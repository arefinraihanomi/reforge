import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../../projects/models/project.dart';
import '../../projects/presentation/projects_notifier.dart';
import '../data/postmortem_repository.dart';
import '../models/lesson.dart';
import '../models/postmortem.dart';

/// Async provider fetching all abandoned projects in the Graveyard.
final abandonedProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final repository = ref.watch(postmortemRepositoryProvider);
  return repository.getAbandonedProjects();
});

/// Async provider fetching the post-mortem record for a specific project.
final projectPostmortemProvider =
    FutureProvider.autoDispose.family<ProjectPostmortem?, String>((ref, projectId) async {
  final repository = ref.watch(postmortemRepositoryProvider);
  return repository.getPostmortemForProject(projectId);
});

/// Async provider fetching lessons for a specific project.
final projectLessonsProvider =
    FutureProvider.autoDispose.family<List<ProjectLesson>, String>((ref, projectId) async {
  final repository = ref.watch(postmortemRepositoryProvider);
  return repository.getProjectLessons(projectId);
});

/// Async provider fetching all lessons across all projects for current user.
final allLessonsProvider = FutureProvider.autoDispose<List<ProjectLesson>>((ref) async {
  final repository = ref.watch(postmortemRepositoryProvider);
  return repository.getAllUserLessons();
});

/// Notifier handling abandonment and post-mortem actions.
class PostmortemActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  PostmortemRepository get _repository => ref.read(postmortemRepositoryProvider);

  /// Transitions a project status to 'abandoned' and moves it into the Graveyard.
  Future<bool> abandonProject({
    required String projectId,
    required String primaryReason,
    String? abandonNote,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.abandonProject(
        projectId: projectId,
        primaryReason: primaryReason,
        abandonNote: abandonNote,
      );
      state = const AsyncData(null);
      _invalidateAll();
      return true;
    } on AppFailure catch (e, st) {
      state = AsyncError(e, st);
      return false;
    } catch (e, st) {
      state = AsyncError(
        const ServerFailure(message: 'Failed to abandon project.'),
        st,
      );
      return false;
    }
  }

  /// Saves a post-mortem entry and extracts reusable lessons.
  Future<ProjectPostmortem?> savePostmortem({
    required String projectId,
    required String primaryReason,
    required String whatWentWrong,
    String? whatWentWell,
    String? notes,
    List<Map<String, String>>? lessons,
  }) async {
    state = const AsyncLoading();
    try {
      final postmortem = await _repository.savePostmortem(
        projectId: projectId,
        primaryReason: primaryReason,
        whatWentWrong: whatWentWrong,
        whatWentWell: whatWentWell,
        notes: notes,
        lessons: lessons,
      );
      state = const AsyncData(null);
      ref.invalidate(projectPostmortemProvider(projectId));
      ref.invalidate(projectLessonsProvider(projectId));
      ref.invalidate(allLessonsProvider);
      ref.invalidate(abandonedProjectsProvider);
      return postmortem;
    } on AppFailure catch (e, st) {
      state = AsyncError(e, st);
      return null;
    } catch (e, st) {
      state = AsyncError(
        const ServerFailure(message: 'Failed to save post-mortem.'),
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

final postmortemActionProvider =
    NotifierProvider<PostmortemActionNotifier, AsyncValue<void>>(
  PostmortemActionNotifier.new,
);
