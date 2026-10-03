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
      if (userId == null || !SupabaseBootstrap.isInitialized) {
        return 'local-v2-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Wrap network calls with strict timeout so UI never hangs endlessly
      return await Future.microtask(() async {
        // 1. Fetch ancestor project details
        final ancestorMap = await _client
            .from('projects')
            .select('id, idea_id, title, summary')
            .eq('id', sourceProjectId)
            .eq('user_id', userId)
            .maybeSingle();

        final title = ancestorMap != null ? ancestorMap['title'] as String? ?? 'Ancestor Project' : 'Ancestor Project';
        final String? ideaId = ancestorMap != null ? ancestorMap['idea_id'] as String? : null;

        // 2. Insert new V2 project
        final Map<String, dynamic> newProjectMap = await _client
            .from('projects')
            .insert({
              'user_id': userId,
              'idea_id': ideaId,
              'title': v2Title.trim(),
              'summary': 'Resurrected V2 of $title',
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

        return newProjectId;
      }).timeout(const Duration(seconds: 3), onTimeout: () {
        return 'local-v2-${DateTime.now().millisecondsSinceEpoch}';
      });
    } catch (_) {
      return 'local-v2-${DateTime.now().millisecondsSinceEpoch}';
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
