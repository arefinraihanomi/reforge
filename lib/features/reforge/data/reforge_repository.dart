import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/supabase_client.dart';
import '../models/project_version.dart';

abstract class ReforgeRepository {
  Future<String> resurrectProjectToV2({
    required String sourceProjectId,
    required String v2Title,
    required String v2MvpScope,
    List<String>? selectedLessons,
    List<String>? initialTasks,
    String? changesSummary,
  });

  Future<ProjectVersion?> getLineageForProject(String projectId);
}

class SupabaseReforgeRepository implements ReforgeRepository {
  final SupabaseClient _client;

  SupabaseReforgeRepository(this._client);

  @override
  Future<String> resurrectProjectToV2({
    required String sourceProjectId,
    required String v2Title,
    required String v2MvpScope,
    List<String>? selectedLessons,
    List<String>? initialTasks,
    String? changesSummary,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      // 1. Fetch ancestor project details
      final ancestorMap = await _client
          .from('projects')
          .select('id, idea_id, title, summary')
          .eq('id', sourceProjectId)
          .eq('user_id', userId)
          .single();

      final String? ideaId = ancestorMap['idea_id'] as String?;

      // 2. Insert new V2 project
      final Map<String, dynamic> newProjectMap = await _client
          .from('projects')
          .insert({
            'user_id': userId,
            if (ideaId != null) 'idea_id': ideaId,
            'title': v2Title.trim(),
            'summary': 'Resurrected V2 of ${ancestorMap['title']}',
            'mvp_scope': v2MvpScope.trim(),
            'status': 'active',
          })
          .select('id')
          .single();

      final String newProjectId = newProjectMap['id'] as String;

      // 3. Mark original project as 'reforged'
      await _client
          .from('projects')
          .update({'status': 'reforged'})
          .eq('id', sourceProjectId)
          .eq('user_id', userId);

      // 4. Record version lineage link
      await _client.from('project_versions').insert({
        'user_id': userId,
        'source_project_id': sourceProjectId,
        'new_project_id': newProjectId,
        'version_label': 'v2',
        if (changesSummary != null && changesSummary.trim().isNotEmpty)
          'changes_summary': changesSummary.trim(),
        'lessons_applied': selectedLessons ?? [],
      });

      // 5. Seed initial tasks for V2
      if (initialTasks != null && initialTasks.isNotEmpty) {
        final List<Map<String, dynamic>> taskRows = [];
        for (int i = 0; i < initialTasks.length; i++) {
          final t = initialTasks[i].trim();
          if (t.isNotEmpty) {
            taskRows.add({
              'project_id': newProjectId,
              'user_id': userId,
              'title': t,
              'status': 'pending',
              'priority': 'high',
              'position': i,
            });
          }
        }
        if (taskRows.isNotEmpty) {
          await _client.from('project_tasks').insert(taskRows);
        }
      }

      // 6. Log ancestral memory note in new V2 project
      await _client.from('project_decisions').insert({
        'project_id': newProjectId,
        'user_id': userId,
        'title': 'V2 Resurrection & Scope Boundary',
        'decision': 'Resurrected from ancestor project "${ancestorMap['title']}". MVP Scope strictly limited to: $v2MvpScope',
        'rationale': selectedLessons != null && selectedLessons.isNotEmpty
            ? 'Applied past lessons: ${selectedLessons.join("; ")}'
            : 'Applying past post-mortem learnings to avoid scope creep.',
        'entry_type': 'decision',
      });

      return newProjectId;
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<ProjectVersion?> getLineageForProject(String projectId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      final response = await _client
          .from('project_versions')
          .select('*')
          .or('source_project_id.eq.$projectId,new_project_id.eq.$projectId')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ProjectVersion.fromJson(response);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }
}

final reforgeRepositoryProvider = Provider<ReforgeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseReforgeRepository(client);
});
