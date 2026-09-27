import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reforge/features/ideas/data/ideas_repository.dart';
import 'package:reforge/features/ideas/models/idea.dart';
import 'package:reforge/features/ideas/models/tag.dart';
import 'package:reforge/features/ideas/presentation/ideas_notifier.dart';

void main() {
  late _MemoryIdeasRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MemoryIdeasRepository();
    container = ProviderContainer(
      overrides: [ideasRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('creates an idea and exposes it through the list provider', () async {
    final created = await container
        .read(ideasActionProvider.notifier)
        .createIdea(title: 'A useful spark', tagIds: ['tag-1']);

    expect(created, isNotNull);
    expect(created!.title, 'A useful spark');
    expect(created.tags.single.id, 'tag-1');

    final ideas = await container.read(ideasListProvider.future);
    expect(ideas, hasLength(1));
    expect(ideas.single.id, created.id);
  });

  test('archives an idea and preserves it in the unfiltered vault', () async {
    final created = await container
        .read(ideasActionProvider.notifier)
        .createIdea(title: 'An archived spark');

    final archived = await container
        .read(ideasActionProvider.notifier)
        .archiveIdea(created!.id);

    expect(archived, isTrue);
    final ideas = await container.read(ideasListProvider.future);
    expect(ideas.single.status, IdeaStatus.archived);
  });

  test('filters ideas by status and search query', () async {
    await container
        .read(ideasActionProvider.notifier)
        .createIdea(title: 'Garden planner', status: IdeaStatus.exploring);
    await container
        .read(ideasActionProvider.notifier)
        .createIdea(title: 'Reading tracker');
    container
        .read(ideasFilterProvider.notifier)
        .setStatus(IdeaStatus.exploring);
    container.read(ideasFilterProvider.notifier).setSearchQuery('garden');

    final ideas = await container.read(ideasListProvider.future);

    expect(ideas, hasLength(1));
    expect(ideas.single.title, 'Garden planner');
  });
}

class _MemoryIdeasRepository implements IdeasRepository {
  final List<Idea> ideas = [];
  final List<Tag> tags = [
    Tag(
      id: 'tag-1',
      userId: 'user-1',
      name: 'Product',
      createdAt: DateTime.utc(2026, 9, 27),
    ),
  ];

  @override
  Future<List<Idea>> listIdeas({
    IdeaStatus? status,
    List<String>? tagIds,
    String? searchQuery,
  }) async {
    return ideas.where((idea) {
      if (status != null && idea.status != status) return false;
      if (tagIds != null && !idea.tags.any((tag) => tagIds.contains(tag.id))) {
        return false;
      }
      if (searchQuery != null &&
          !idea.title.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Idea> getIdea(String ideaId) async =>
      ideas.firstWhere((idea) => idea.id == ideaId);

  @override
  Future<Idea> createIdea({
    required String title,
    String? description,
    String? problem,
    String? targetUsers,
    String? potentialDirection,
    String? hypothesis,
    IdeaStatus status = IdeaStatus.active,
    List<String>? tagIds,
  }) async {
    final now = DateTime.utc(2026, 9, 27);
    final idea = Idea(
      id: 'idea-${ideas.length + 1}',
      userId: 'user-1',
      title: title,
      description: description,
      problem: problem,
      targetUsers: targetUsers,
      potentialDirection: potentialDirection,
      hypothesis: hypothesis,
      status: status,
      createdAt: now,
      updatedAt: now,
      tags: tags.where((tag) => tagIds?.contains(tag.id) ?? false).toList(),
    );
    ideas.add(idea);
    return idea;
  }

  @override
  Future<Idea> updateIdea({
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
    final index = ideas.indexWhere((idea) => idea.id == ideaId);
    final current = ideas[index];
    final updated = current.copyWith(
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
      tags: tagIds == null
          ? current.tags
          : tags.where((tag) => tagIds.contains(tag.id)).toList(),
    );
    ideas[index] = updated;
    return updated;
  }

  @override
  Future<void> archiveIdea(String ideaId) async {
    await updateIdea(ideaId: ideaId, status: IdeaStatus.archived);
  }

  @override
  Future<void> deleteIdea(String ideaId) async {
    ideas.removeWhere((idea) => idea.id == ideaId);
  }

  @override
  Future<List<Tag>> listTags() async => tags;

  @override
  Future<Tag> createTag({required String name, String? color}) async {
    final tag = Tag(
      id: 'tag-${tags.length + 1}',
      userId: 'user-1',
      name: name,
      color: color,
      createdAt: DateTime.utc(2026, 9, 27),
    );
    tags.add(tag);
    return tag;
  }

  @override
  Future<void> deleteTag(String tagId) async {
    tags.removeWhere((tag) => tag.id == tagId);
  }
}
