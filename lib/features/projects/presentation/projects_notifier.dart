import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
import '../../ideas/presentation/ideas_notifier.dart';
import '../data/projects_repository.dart';
import '../models/project.dart';
import '../models/project_decision.dart';
import '../models/project_task.dart';

/// Async provider fetching all projects for the current user.
final projectsListProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final repository = ref.watch(projectsRepositoryProvider);
  return repository.getProjects();
});

/// Async provider filtering active projects (status: active / in_progress).
final activeProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final projects = await ref.watch(projectsListProvider.future);
  return projects.where((p) => p.isActive).toList();
});

/// Async provider fetching a single project detail by ID (family).
final projectDetailProvider =
    FutureProvider.autoDispose.family<Project, String>((ref, projectId) async {
  final repository = ref.watch(projectsRepositoryProvider);
  return repository.getProjectById(projectId);
});

/// Async provider fetching decisions timeline for a project (family).
final projectDecisionsProvider =
    FutureProvider.autoDispose.family<List<ProjectDecision>, String>((ref, projectId) async {
  final repository = ref.watch(projectsRepositoryProvider);
  return repository.getProjectDecisions(projectId);
});

/// Notifier handling project mutation actions (convert, add task, toggle task, delete task, log decision, update scope).
class ProjectsActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  ProjectsRepository get _repository => ref.read(projectsRepositoryProvider);

  /// Converts an idea into a new project and invalidates ideas & projects lists.
  Future<String?> convertIdeaToProject({
    required String ideaId,
    String? ideaTitle,
    String? ideaSummary,
    String? ideaHypothesis,
    String? mvpScope,
    List<String>? initialTasks,
  }) async {
    state = const AsyncLoading();
    try {
      final projectId = await _repository.convertIdeaToProject(
        ideaId: ideaId,
        ideaTitle: ideaTitle,
        ideaSummary: ideaSummary,
        ideaHypothesis: ideaHypothesis,
        mvpScope: mvpScope,
        initialTasks: initialTasks,
      );
      state = const AsyncData(null);
      _invalidateAll();
      return projectId;
    } on AppFailure catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      final failure = ServerFailure(message: e.toString().replaceAll('Exception: ', ''));
      state = AsyncError(failure, st);
      rethrow;
    }
  }

  /// Adds a new task to a project.
  Future<ProjectTask?> addTask({
    required String projectId,
    required String title,
    String priority = 'medium',
  }) async {
    try {
      final task = await _repository.addTask(
        projectId: projectId,
        title: title,
        priority: priority,
      );
      ref.invalidate(projectDetailProvider(projectId));
      ref.invalidate(projectsListProvider);
      return task;
    } catch (e) {
      rethrow;
    }
  }

  /// Toggles completion status of a task.
  Future<void> toggleTaskStatus({
    required String projectId,
    required String taskId,
    required bool isCompleted,
  }) async {
    try {
      await _repository.toggleTaskStatus(
        taskId: taskId,
        isCompleted: isCompleted,
      );
      ref.invalidate(projectDetailProvider(projectId));
      ref.invalidate(projectsListProvider);
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a task from a project.
  Future<void> deleteTask({
    required String projectId,
    required String taskId,
  }) async {
    try {
      await _repository.deleteTask(taskId);
      ref.invalidate(projectDetailProvider(projectId));
      ref.invalidate(projectsListProvider);
    } catch (e) {
      rethrow;
    }
  }

  /// Logs a decision, blocker, or note in project memory.
  Future<ProjectDecision?> logDecision({
    required String projectId,
    required String title,
    required String decision,
    String? rationale,
    String entryType = 'decision',
  }) async {
    try {
      final item = await _repository.logDecision(
        projectId: projectId,
        title: title,
        decision: decision,
        rationale: rationale,
        entryType: entryType,
      );
      ref.invalidate(projectDecisionsProvider(projectId));
      return item;
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a decision from project memory.
  Future<void> deleteDecision({
    required String projectId,
    required String decisionId,
  }) async {
    try {
      await _repository.deleteDecision(decisionId);
      ref.invalidate(projectDecisionsProvider(projectId));
    } catch (e) {
      rethrow;
    }
  }

  /// Updates MVP scope boundary of a project.
  Future<void> updateMvpScope({
    required Project project,
    required String newMvpScope,
  }) async {
    try {
      final updated = project.copyWith(mvpScope: newMvpScope);
      await _repository.updateProject(updated);
      ref.invalidate(projectDetailProvider(project.id));
      ref.invalidate(projectsListProvider);
    } catch (e) {
      rethrow;
    }
  }

  void _invalidateAll() {
    ref.invalidate(projectsListProvider);
    ref.invalidate(ideasListProvider);
    ref.invalidate(ideasStatsProvider);
  }
}

final projectsActionProvider =
    NotifierProvider<ProjectsActionNotifier, AsyncValue<void>>(
  ProjectsActionNotifier.new,
);
