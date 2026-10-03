import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../data/ideas_repository.dart';
import '../models/idea.dart';
import '../models/tag.dart';

/// Sort order for the Idea Vault list.
enum IdeaSortBy {
  newestFirst,
  oldestFirst,
  alphabetical,
  statusGrouped;

  String get label {
    switch (this) {
      case IdeaSortBy.newestFirst:
        return 'Newest First';
      case IdeaSortBy.oldestFirst:
        return 'Oldest First';
      case IdeaSortBy.alphabetical:
        return 'A → Z';
      case IdeaSortBy.statusGrouped:
        return 'By Status';
    }
  }
}

/// Tag filter mode: whether ALL selected tags must match (AND) or ANY (OR).
enum TagFilterMode { and, or }

/// Filter state for the Idea Vault list screen.
class IdeasFilter {
  final IdeaStatus? status;
  final Set<String> selectedTagIds;
  final String searchQuery;
  final TagFilterMode tagFilterMode;
  final IdeaSortBy sortBy;

  const IdeasFilter({
    this.status,
    this.selectedTagIds = const {},
    this.searchQuery = '',
    this.tagFilterMode = TagFilterMode.or,
    this.sortBy = IdeaSortBy.newestFirst,
  });

  IdeasFilter copyWith({
    IdeaStatus? status,
    Set<String>? selectedTagIds,
    String? searchQuery,
    TagFilterMode? tagFilterMode,
    IdeaSortBy? sortBy,
    bool clearStatus = false,
  }) {
    return IdeasFilter(
      status: clearStatus ? null : (status ?? this.status),
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      searchQuery: searchQuery ?? this.searchQuery,
      tagFilterMode: tagFilterMode ?? this.tagFilterMode,
      sortBy: sortBy ?? this.sortBy,
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

  void toggleTagFilterMode() {
    state = state.copyWith(
      tagFilterMode: state.tagFilterMode == TagFilterMode.or
          ? TagFilterMode.and
          : TagFilterMode.or,
    );
  }

  void setSortBy(IdeaSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void clearAll() {
    state = const IdeasFilter();
  }
}

/// Async provider that fetches and caches the list of ideas based on current filters.
final ideasListProvider = FutureProvider.autoDispose<List<Idea>>((ref) async {
  final repository = ref.watch(ideasRepositoryProvider);
  final filter = ref.watch(ideasFilterProvider);

  // Fetch raw list — server handles status and search; tag filtering may be client-side
  var ideas = await repository.listIdeas(
    status: filter.status,
    tagIds: filter.selectedTagIds.isNotEmpty && filter.tagFilterMode == TagFilterMode.or
        ? filter.selectedTagIds.toList()
        : null,
    searchQuery: filter.searchQuery.isNotEmpty ? filter.searchQuery : null,
  );

  // AND-mode: keep only ideas that have ALL selected tags
  if (filter.selectedTagIds.isNotEmpty && filter.tagFilterMode == TagFilterMode.and) {
    ideas = ideas.where((idea) {
      final ideaTagIds = idea.tags.map((t) => t.id).toSet();
      return filter.selectedTagIds.every((tagId) => ideaTagIds.contains(tagId));
    }).toList();
  }

  // Client-side sort
  switch (filter.sortBy) {
    case IdeaSortBy.newestFirst:
      ideas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case IdeaSortBy.oldestFirst:
      ideas.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case IdeaSortBy.alphabetical:
      ideas.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    case IdeaSortBy.statusGrouped:
      final order = {
        IdeaStatus.building: 0,
        IdeaStatus.exploring: 1,
        IdeaStatus.active: 2,
        IdeaStatus.archived: 3,
        IdeaStatus.converted: 4,
      };
      ideas.sort((a, b) => (order[a.status] ?? 5).compareTo(order[b.status] ?? 5));
  }

  return ideas;
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
