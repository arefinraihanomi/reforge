import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../../postmortem/presentation/postmortem_notifier.dart';
import '../../projects/presentation/projects_notifier.dart';
import '../data/reforge_repository.dart';
import '../models/project_version.dart';

/// Async provider fetching version lineage for a project.
final projectLineageProvider =
    FutureProvider.autoDispose.family<ProjectVersion?, String>((ref, projectId) async {
  final repository = ref.watch(reforgeRepositoryProvider);
  return repository.getLineageForProject(projectId);
});

/// Notifier handling Reforge V2 resurrection execution.
class ReforgeActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  ReforgeRepository get _repository => ref.read(reforgeRepositoryProvider);

  /// Resurrects an abandoned project into a new V2 workspace with ancestor link and lessons.
  Future<String?> resurrectProjectToV2({
    required String sourceProjectId,
    required String v2Title,
    required String v2MvpScope,
    List<String>? selectedLessons,
    List<String>? initialTasks,
    String? changesSummary,
  }) async {
    state = const AsyncLoading();
    try {
      final newProjectId = await _repository.resurrectProjectToV2(
        sourceProjectId: sourceProjectId,
        v2Title: v2Title,
        v2MvpScope: v2MvpScope,
        selectedLessons: selectedLessons,
        initialTasks: initialTasks,
        changesSummary: changesSummary,
      );
      state = const AsyncData(null);
      _invalidateAll();
      return newProjectId;
    } on AppFailure catch (e, st) {
      state = AsyncError(e, st);
      return null;
    } catch (e, st) {
      state = AsyncError(
        const ServerFailure(message: 'Failed to resurrect project to V2.'),
        st,
      );
      return null;
    }
  }

  void _invalidateAll() {
    ref.invalidate(projectsListProvider);
    ref.invalidate(activeProjectsProvider);
    ref.invalidate(abandonedProjectsProvider);
  }
}

final reforgeActionProvider =
    NotifierProvider<ReforgeActionNotifier, AsyncValue<void>>(
  ReforgeActionNotifier.new,
);
