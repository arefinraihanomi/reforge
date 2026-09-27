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
}

class SupabasePostmortemRepository implements PostmortemRepository {
  final SupabaseClient _client;

  SupabasePostmortemRepository(this._client);

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
      if (!SupabaseBootstrap.isInitialized) return [];
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('project_lessons')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (response as List).cast<Map<String, dynamic>>();
      return list.map((json) => ProjectLesson.fromJson(json)).toList();
    } catch (e) {
      throw AppFailure.fromException(e);
    }
  }
}

final postmortemRepositoryProvider = Provider<PostmortemRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabasePostmortemRepository(client);
});
