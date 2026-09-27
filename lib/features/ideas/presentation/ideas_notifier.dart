import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../data/ideas_repository.dart';
import '../models/idea.dart';
import '../models/tag.dart';

/// Filter state for the Idea Vault list screen.
class IdeasFilter {
  final IdeaStatus? status;
  final Set<String> selectedTagIds;
  final String searchQuery;

  const IdeasFilter({
    this.status,
    this.selectedTagIds = const {},
    this.searchQuery = '',
  });

  IdeasFilter copyWith({
    IdeaStatus? status,
    Set<String>? selectedTagIds,
    String? searchQuery,
    bool clearStatus = false,
  }) {
    return IdeasFilter(
      status: clearStatus ? null : (status ?? this.status),
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier provider for the current filter state.
final ideasFilterProvider =
    NotifierProvider<IdeasFilterNotifier, IdeasFilter>(IdeasFilterNotifier.new);

class IdeasFilterNotifier extends Notifier<IdeasFilter> {
  @override
  IdeasFilter build() => const IdeasFilter();

  void setStatus(IdeaStatus? status) {
    if (status == state.status) {
      // Toggle off
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(status: status);
    }
  }

  void toggleTag(String tagId) {
    final tags = Set<String>.from(state.selectedTagIds);
    if (tags.contains(tagId)) {
      tags.remove(tagId);
    } else {
      tags.add(tagId);
    }
    state = state.copyWith(selectedTagIds: tags);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearAll() {
    state = const IdeasFilter();
  }
}

/// Async provider that fetches and caches the list of ideas based on current filters.
final ideasListProvider = FutureProvider.autoDispose<List<Idea>>((ref) async {
  final repository = ref.watch(ideasRepositoryProvider);
  final filter = ref.watch(ideasFilterProvider);

  return repository.listIdeas(
    status: filter.status,
    tagIds: filter.selectedTagIds.isNotEmpty
        ? filter.selectedTagIds.toList()
        : null,
    searchQuery:
        filter.searchQuery.isNotEmpty ? filter.searchQuery : null,
  );
});

/// Fetches a single idea by ID (used for detail screen).
final ideaDetailProvider =
    FutureProvider.autoDispose.family<Idea, String>((ref, ideaId) async {
  final repository = ref.watch(ideasRepositoryProvider);
  return repository.getIdea(ideaId);
});

/// Async provider for user's tags list.
final tagsListProvider = FutureProvider.autoDispose<List<Tag>>((ref) async {
  final repository = ref.watch(ideasRepositoryProvider);
  return repository.listTags();
});

/// Computed provider for vault statistics.
final ideasStatsProvider = FutureProvider.autoDispose<IdeasStats>((ref) async {
  final repository = ref.watch(ideasRepositoryProvider);
  final allIdeas = await repository.listIdeas();

  final totalSparks = allIdeas.length;
  final activeForge = allIdeas.where((i) =>
      i.status == IdeaStatus.building || i.status == IdeaStatus.exploring).length;

  return IdeasStats(
    totalSparks: totalSparks,
    activeForge: activeForge,
  );
});

/// Simple statistics for the Ideas Vault header.
class IdeasStats {
  final int totalSparks;
  final int activeForge;

  const IdeasStats({this.totalSparks = 0, this.activeForge = 0});
}

/// Notifier handling idea mutation actions (create, update, archive, delete).
class IdeasActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  IdeasRepository get _repository => ref.read(ideasRepositoryProvider);

  /// Creates a new idea with optional tag associations.
  Future<Idea?> createIdea({
    required String title,
    String? description,
    String? problem,
    String? targetUsers,
    String? potentialDirection,
    String? hypothesis,
    IdeaStatus status = IdeaStatus.active,
    List<String>? tagIds,
  }) async {
    state = const AsyncLoading();
    try {
      final idea = await _repository.createIdea(
        title: title,
        description: description,
        problem: problem,
        targetUsers: targetUsers,
        potentialDirection: potentialDirection,
        hypothesis: hypothesis,
        status: status,
        tagIds: tagIds,
      );
      state = const AsyncData(null);
      _invalidateListProviders();
      return idea;
    } on AppFailure catch (e, st) {
      state = AsyncError(e, st);
      return null;
    } catch (e, st) {
      state = AsyncError(
        const ServerFailure(message: 'Failed to create idea.'),
        st,
      );
      return null;
    }
  }

  /// Updates an existing idea.
  Future<Idea?> updateIdea({
    required String ideaId,
    String? title,
    String? description,
    String? problem,
    String? targetUsers,
    String? potentialDirection,
    String? hypothesis,
    List<WorkshopNote>? workshopNotes,
    IdeaStatus? status,
    IdeaStage? stage,
    int? revisionsCount,
    List<String>? tagIds,
  }) async {
    state = const AsyncLoading();
    try {
      final idea = await _repository.updateIdea(
        ideaId: ideaId,
        title: title,
        description: description,
        problem: problem,
        targetUsers: targetUsers,
        potentialDirection: potentialDirection,
        hypothesis: hypothesis,
        workshopNotes: workshopNotes,
        status: status,
        stage: stage,
        revisionsCount: revisionsCount,
        tagIds: tagIds,
      );
      state = const AsyncData(null);
      _invalidateListProviders();
      return idea;
    } on AppFailure catch (e, st) {
      state = AsyncError(e, st);
      return null;
    } catch (e, st) {
      state = AsyncError(
        const ServerFailure(message: 'Failed to update idea.'),
        st,
      );
      return null;
    }
  }

  /// Archives an idea (soft deletion).
  Future<bool> archiveIdea(String ideaId) async {
    state = const AsyncLoading();
    try {
      await _repository.archiveIdea(ideaId);
      state = const AsyncData(null);
      _invalidateListProviders();
      return true;
    } on AppFailure catch (e, st) {
      state = AsyncError(e, st);
      return false;
    } catch (e, st) {
      state = AsyncError(
        const ServerFailure(message: 'Failed to archive idea.'),
        st,
      );
      return false;
    }
  }

  /// Permanently deletes an idea.
  Future<bool> deleteIdea(String ideaId) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteIdea(ideaId);
      state = const AsyncData(null);
      _invalidateListProviders();
      return true;
    } on AppFailure catch (e, st) {
      state = AsyncError(e, st);
      return false;
    } catch (e, st) {
      state = AsyncError(
        const ServerFailure(message: 'Failed to delete idea.'),
        st,
      );
      return false;
    }
  }

  /// Creates a tag. Returns the created tag or null on failure.
  Future<Tag?> createTag({required String name, String? color}) async {
    try {
      final tag = await _repository.createTag(name: name, color: color);
      ref.invalidate(tagsListProvider);
      return tag;
    } catch (_) {
      return null;
    }
  }

  void _invalidateListProviders() {
    ref.invalidate(ideasListProvider);
    ref.invalidate(ideasStatsProvider);
  }
}

/// Riverpod provider exposing [IdeasActionNotifier].
final ideasActionProvider =
    NotifierProvider<IdeasActionNotifier, AsyncValue<void>>(
        IdeasActionNotifier.new);
