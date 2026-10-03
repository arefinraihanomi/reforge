import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/local_storage/offline_decisions_cache.dart';
import '../../../core/network/supabase_client.dart';
import '../models/project.dart';
import '../models/project_decision.dart';
import '../models/project_task.dart';

abstract class ProjectsRepository {
  Future<String> convertIdeaToProject({
    required String ideaId,
    String? ideaTitle,
    String? ideaSummary,
    String? ideaHypothesis,
    String? mvpScope,
    List<String>? initialTasks,
  });

  Future<List<Project>> getProjects({String? status});
  Future<Project> getProjectById(String projectId);
  Future<Project> updateProject(Project project);
  Future<void> deleteProject(String projectId);

  Future<ProjectTask> addTask({
    required String projectId,
    required String title,
    String priority = 'medium',
  });
  Future<ProjectTask> toggleTaskStatus({
    required String taskId,
    required bool isCompleted,
  });
  Future<void> deleteTask(String taskId);

  // Project Memory & Decision Methods
  Future<List<ProjectDecision>> getProjectDecisions(String projectId);
  Future<ProjectDecision> logDecision({
    required String projectId,
    required String title,
    required String decision,
    String? rationale,
    String entryType = 'decision',
    String category = 'Other',
  });
  Future<void> deleteDecision(String decisionId);
}

class SupabaseProjectsRepository implements ProjectsRepository {
  final SupabaseClient _client;

  SupabaseProjectsRepository(this._client);

  @override
  Future<String> convertIdeaToProject({
    required String ideaId,
    String? ideaTitle,
    String? ideaSummary,
    String? ideaHypothesis,
    String? mvpScope,
    List<String>? initialTasks,
  }) async {
    try {
      if (!SupabaseBootstrap.isInitialized) {
        return 'local-project-${DateTime.now().millisecondsSinceEpoch}';
      }

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      // 1. Attempt Supabase RPC execution
      try {
        final response = await _client.rpc(
          'convert_idea_to_project',
          params: {
            'p_idea_id': ideaId,
            if (mvpScope != null && mvpScope.trim().isNotEmpty)
              'p_mvp_scope': mvpScope.trim(),
            if (initialTasks != null && initialTasks.isNotEmpty)
              'p_initial_tasks': initialTasks.where((t) => t.trim().isNotEmpty).toList(),
          },
        );
        if (response != null && response.toString().isNotEmpty) {
          return response.toString();
        }
      } catch (_) {
        // Fallback to direct REST table operations if RPC is not deployed in remote DB
      }

      // 2. Direct Table Fallback
      String title = ideaTitle ?? '';
      String? summary = ideaSummary;
      String? hypothesis = ideaHypothesis;

      if (title.isEmpty) {
        final Map<String, dynamic>? ideaRow = await _client
            .from('ideas')
            .select('title, description, problem, hypothesis')
            .eq('id', ideaId)
            .maybeSingle();

        if (ideaRow != null) {
          title = ideaRow['title'] as String? ?? 'Converted Project';
          summary = ideaRow['description'] as String? ?? ideaRow['problem'] as String?;
          hypothesis = ideaRow['hypothesis'] as String?;
        } else {
          title = 'Converted Project';
        }
      }

      final finalMvpScope = (mvpScope != null && mvpScope.trim().isNotEmpty)
          ? mvpScope.trim()
          : hypothesis;

      // Insert Project
      final projectResponse = await _client.from('projects').insert({
        'user_id': userId,
        'idea_id': ideaId,
        'title': title,
        'summary': summary,
        'mvp_scope': finalMvpScope,
        'status': 'active',
      }).select('id').single();

      final newProjectId = projectResponse['id'] as String;

      // Update Idea status
      await _client.from('ideas').update({
        'status': 'converted',
        'stage': 'building',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', ideaId).eq('user_id', userId);

      // Insert Initial Tasks
      if (initialTasks != null && initialTasks.isNotEmpty) {
        final validTasks = initialTasks.where((t) => t.trim().isNotEmpty).toList();
        for (var i = 0; i < validTasks.length; i++) {
          await _client.from('project_tasks').insert({
            'project_id': newProjectId,
            'user_id': userId,
            'title': validTasks[i].trim(),
            'status': 'pending',
            'position': i,
          });
        }
      }

      return newProjectId;
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<List<Project>> getProjects({String? status}) async {
    try {
      if (!SupabaseBootstrap.isInitialized) return [];
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _client
          .from('projects')
          .select('*, project_tasks(*)')
          .eq('user_id', userId);

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      final list = (response as List).cast<Map<String, dynamic>>();
      return list.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<Project> getProjectById(String projectId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      final Map<String, dynamic> json = await _client
          .from('projects')
          .select('*, project_tasks(*)')
          .eq('id', projectId)
          .eq('user_id', userId)
          .single();

      final tasksJson = (json['project_tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      tasksJson.sort((a, b) => ((a['position'] as num?)?.toInt() ?? 0)
          .compareTo((b['position'] as num?)?.toInt() ?? 0));

      final tasks = tasksJson.map((t) => ProjectTask.fromJson(t)).toList();
      return Project.fromJson(json, tasks: tasks);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<Project> updateProject(Project project) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      final updateData = project.toJson();
      updateData.remove('project_tasks');
      updateData.remove('created_at');
      updateData.remove('updated_at');

      final Map<String, dynamic> response = await _client
          .from('projects')
          .update(updateData)
          .eq('id', project.id)
          .eq('user_id', userId)
          .select('*, project_tasks(*)')
          .single();

      return Project.fromJson(response);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      await _client
          .from('projects')
          .delete()
          .eq('id', projectId)
          .eq('user_id', userId);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<ProjectTask> addTask({
    required String projectId,
    required String title,
    String priority = 'medium',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      final Map<String, dynamic> response = await _client
          .from('project_tasks')
          .insert({
            'project_id': projectId,
            'user_id': userId,
            'title': title.trim(),
            'priority': priority,
            'status': 'pending',
          })
          .select()
          .single();

      return ProjectTask.fromJson(response);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<ProjectTask> toggleTaskStatus({
    required String taskId,
    required bool isCompleted,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      final Map<String, dynamic> response = await _client
          .from('project_tasks')
          .update({
            'status': isCompleted ? 'completed' : 'pending',
          })
          .eq('id', taskId)
          .eq('user_id', userId)
          .select()
          .single();

      return ProjectTask.fromJson(response);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      await _client
          .from('project_tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', userId);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<List<ProjectDecision>> getProjectDecisions(String projectId) async {
    List<ProjectDecision> remoteDecisions = [];
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final response = await _client
            .from('project_decisions')
            .select('*')
            .eq('project_id', projectId)
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        final list = (response as List).cast<Map<String, dynamic>>();
        remoteDecisions = list.map((json) => ProjectDecision.fromJson(json)).toList();
      }
    } catch (_) {
      // Ignore network failures and fall back to local cache
    }

    // Merge remote decisions with local Hive cache to guarantee logged decisions are never lost
    final cached = OfflineDecisionsCache.loadDecisions(projectId);
    final Set<String> ids = remoteDecisions.map((d) => d.id).toSet();
    for (final c in cached) {
      if (!ids.contains(c.id)) {
        remoteDecisions.insert(0, c);
        ids.add(c.id);
      }
    }

    return remoteDecisions;
  }

  @override
  Future<ProjectDecision> logDecision({
    required String projectId,
    required String title,
    required String decision,
    String? rationale,
    String entryType = 'decision',
    String category = 'Other',
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      final Map<String, dynamic> response = await _client
          .from('project_decisions')
          .insert({
            'project_id': projectId,
            'user_id': userId,
            'title': title.trim(),
            'decision': decision.trim(),
            if (rationale != null && rationale.trim().isNotEmpty)
              'rationale': rationale.trim(),
            'entry_type': entryType,
            'category': category,
          })
          .select()
          .single();

      return ProjectDecision.fromJson(response);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('PGRST205') || errStr.contains('project_decisions')) {
        // Fallback when remote migration has not been applied yet
        return ProjectDecision(
          id: 'local-dec-${DateTime.now().millisecondsSinceEpoch}',
          projectId: projectId,
          userId: _client.auth.currentUser?.id ?? 'local-user',
          title: title.trim(),
          decision: decision.trim(),
          rationale: rationale?.trim(),
          entryType: entryType,
          category: category,
          createdAt: DateTime.now(),
        );
      }
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<void> deleteDecision(String decisionId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      await _client
          .from('project_decisions')
          .delete()
          .eq('id', decisionId)
          .eq('user_id', userId);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }
}

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProjectsRepository(client);
});
