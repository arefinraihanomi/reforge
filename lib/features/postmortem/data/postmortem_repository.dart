import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/supabase_client.dart';
import '../../projects/models/project.dart';
import '../models/lesson.dart';
import '../models/postmortem.dart';

abstract class PostmortemRepository {
  Future<void> abandonProject({
    required String projectId,
    required String primaryReason,
    String? abandonNote,
  });

  Future<List<Project>> getAbandonedProjects();
  Future<ProjectPostmortem?> getPostmortemForProject(String projectId);
  Future<ProjectPostmortem> savePostmortem({
    required String projectId,
    required String primaryReason,
    required String whatWentWrong,
    String? whatWentWell,
    String? notes,
    List<Map<String, String>>? lessons,
  });

  Future<List<ProjectLesson>> getProjectLessons(String projectId);
  Future<List<ProjectLesson>> getAllUserLessons();
  Future<ProjectLesson> createLesson({
    required String lesson,
    required String category,
    String? projectId,
  });
}

class SupabasePostmortemRepository implements PostmortemRepository {
  final SupabaseClient _client;

  SupabasePostmortemRepository(this._client);

  static final List<ProjectLesson> _fallbackLessons = [
    ProjectLesson(
      id: 'lesson-seed-1',
      userId: 'workshop-user',
      lesson: 'Keep the initial MVP slice strictly under 3 core user flows to prevent scope creep.',
      category: 'scope',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ProjectLesson(
      id: 'lesson-seed-2',
      userId: 'workshop-user',
      lesson: 'Decouple state management early with clear repository interfaces for smooth offline fallback testing.',
      category: 'architecture',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ProjectLesson(
      id: 'lesson-seed-3',
      userId: 'workshop-user',
      lesson: 'Validate AI prompt outputs with strict JSON schemas before parsing into domain models.',
      category: 'technical',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ProjectLesson(
      id: 'lesson-seed-4',
      userId: 'workshop-user',
      lesson: 'Log architectural decisions immediately when trade-offs are settled so context is never lost.',
      category: 'process',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  static final List<ProjectLesson> _localLessons = List.from(_fallbackLessons);

  @override
  Future<void> abandonProject({
    required String projectId,
    required String primaryReason,
    String? abandonNote,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      await _client.from('projects').update({
        'status': 'abandoned',
        'abandoned_at': DateTime.now().toUtc().toIso8601String(),
        'abandon_reason': primaryReason,
        if (abandonNote != null && abandonNote.trim().isNotEmpty)
          'abandon_note': abandonNote.trim(),
      }).eq('id', projectId).eq('user_id', userId);
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<List<Project>> getAbandonedProjects() async {
    try {
      if (!SupabaseBootstrap.isInitialized) return [];
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('projects')
          .select('*, project_tasks(*)')
          .eq('user_id', userId)
          .eq('status', 'abandoned')
          .order('created_at', ascending: false);

      final list = (response as List).cast<Map<String, dynamic>>();
      return list.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<ProjectPostmortem?> getPostmortemForProject(String projectId) async {
    try {
      if (!SupabaseBootstrap.isInitialized) return null;
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('project_postmortems')
          .select('*')
          .eq('project_id', projectId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ProjectPostmortem.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ProjectPostmortem> savePostmortem({
    required String projectId,
    required String primaryReason,
    required String whatWentWrong,
    String? whatWentWell,
    String? notes,
    List<Map<String, String>>? lessons,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthFailure(message: 'User must be authenticated.');
      }

      // Upsert post-mortem
      final Map<String, dynamic> postmortemJson = await _client
          .from('project_postmortems')
          .upsert(
            {
              'project_id': projectId,
              'user_id': userId,
              'primary_reason': primaryReason,
              'what_went_wrong': whatWentWrong.trim(),
              if (whatWentWell != null && whatWentWell.trim().isNotEmpty)
                'what_went_well': whatWentWell.trim(),
              if (notes != null && notes.trim().isNotEmpty)
                'notes': notes.trim(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'project_id',
          )
          .select()
          .single();

      final postmortem = ProjectPostmortem.fromJson(postmortemJson);

      // Insert associated lessons if provided
      if (lessons != null && lessons.isNotEmpty) {
        final List<Map<String, dynamic>> lessonRows = lessons
            .where((l) => (l['lesson'] ?? '').trim().isNotEmpty)
            .map((l) => {
                  'project_id': projectId,
                  'postmortem_id': postmortem.id,
                  'user_id': userId,
                  'lesson': l['lesson']!.trim(),
                  'category': l['category'] ?? 'architecture',
                })
            .toList();

        if (lessonRows.isNotEmpty) {
          await _client.from('project_lessons').insert(lessonRows);
        }
      }

      return postmortem;
    } catch (e) {
      final errStr = e.toString();
      if (!SupabaseBootstrap.isInitialized ||
          errStr.contains('PGRST205') ||
          errStr.contains('project_postmortems') ||
          errStr.contains('AuthFailure')) {
        // Fallback local mock save
        final fallbackPostmortem = ProjectPostmortem(
          id: 'local-pm-${DateTime.now().millisecondsSinceEpoch}',
          projectId: projectId,
          userId: _client.auth.currentUser?.id ?? 'local-user',
          primaryReason: primaryReason,
          whatWentWrong: whatWentWrong.trim(),
          whatWentWell: whatWentWell?.trim(),
          notes: notes?.trim(),
          createdAt: DateTime.now(),
        );

        if (lessons != null && lessons.isNotEmpty) {
          for (final l in lessons) {
            final lessonText = (l['lesson'] ?? '').trim();
            if (lessonText.isNotEmpty) {
              await createLesson(
                lesson: lessonText,
                category: l['category'] ?? 'architecture',
                projectId: projectId,
              );
            }
          }
        }

        return fallbackPostmortem;
      }
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<List<ProjectLesson>> getProjectLessons(String projectId) async {
    try {
      if (!SupabaseBootstrap.isInitialized) return [];
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('project_lessons')
          .select('*')
          .eq('project_id', projectId)
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (response as List).cast<Map<String, dynamic>>();
      return list.map((json) => ProjectLesson.fromJson(json)).toList();
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }

  @override
  Future<List<ProjectLesson>> getAllUserLessons() async {
    try {
      if (!SupabaseBootstrap.isInitialized) {
        return List.from(_localLessons);
      }
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return List.from(_localLessons);
      }

      final response = await _client
          .from('project_lessons')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (response as List).cast<Map<String, dynamic>>();
      final lessons = list.map((json) => ProjectLesson.fromJson(json)).toList();
      if (lessons.isEmpty) {
        return List.from(_localLessons);
      }
      return lessons;
    } catch (e) {
      return List.from(_localLessons);
    }
  }

  @override
  Future<ProjectLesson> createLesson({
    required String lesson,
    required String category,
    String? projectId,
  }) async {
    try {
      final now = DateTime.now();
      if (!SupabaseBootstrap.isInitialized) {
        final newLesson = ProjectLesson(
          id: 'local-lesson-${now.millisecondsSinceEpoch}',
          projectId: projectId,
          userId: 'local-user',
          lesson: lesson.trim(),
          category: category.toLowerCase().trim(),
          createdAt: now,
        );
        _localLessons.insert(0, newLesson);
        return newLesson;
      }

      final userId = _client.auth.currentUser?.id ?? 'local-user';
      final response = await _client
          .from('project_lessons')
          .insert({
            'user_id': userId,
            'lesson': lesson.trim(),
            'category': category.toLowerCase().trim(),
            if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
          })
          .select()
          .single();

      final created = ProjectLesson.fromJson(response);
      _localLessons.insert(0, created);
      return created;
    } catch (e) {
      final fallbackLesson = ProjectLesson(
        id: 'local-lesson-${DateTime.now().millisecondsSinceEpoch}',
        projectId: projectId,
        userId: 'local-user',
        lesson: lesson.trim(),
        category: category.toLowerCase().trim(),
        createdAt: DateTime.now(),
      );
      _localLessons.insert(0, fallbackLesson);
      return fallbackLesson;
    }
  }
}

final postmortemRepositoryProvider = Provider<PostmortemRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabasePostmortemRepository(client);
});
