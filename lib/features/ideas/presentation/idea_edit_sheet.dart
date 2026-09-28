import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/idea.dart';
import 'ideas_notifier.dart';

Future<void> showIdeaEditSheet(BuildContext context, Idea idea) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ReforgeColors.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _IdeaEditSheet(idea: idea),
  );
}

class _IdeaEditSheet extends ConsumerStatefulWidget {
  final Idea idea;

  const _IdeaEditSheet({required this.idea});

  @override
  ConsumerState<_IdeaEditSheet> createState() => _IdeaEditSheetState();
}

class _IdeaEditSheetState extends ConsumerState<_IdeaEditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _problem;
  late final TextEditingController _targetUsers;
  late final TextEditingController _direction;
  late final TextEditingController _hypothesis;
  late final Set<String> _tagIds;
  late IdeaStatus _status;
  late IdeaStage _stage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final idea = widget.idea;
    _title = TextEditingController(text: idea.title);
    _description = TextEditingController(text: idea.description ?? '');
    _problem = TextEditingController(text: idea.problem ?? '');
    _targetUsers = TextEditingController(text: idea.targetUsers ?? '');
    _direction = TextEditingController(text: idea.potentialDirection ?? '');
    _hypothesis = TextEditingController(text: idea.hypothesis ?? '');
    _tagIds = idea.tags.map((tag) => tag.id).toSet();
    _status = idea.status;
    _stage = idea.stage;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _problem.dispose();
    _targetUsers.dispose();
    _direction.dispose();
    _hypothesis.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsListProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit idea', style: ReforgeTypography.sectionTitle),
            const SizedBox(height: 16),
            _field(_title, 'Title'),
            const SizedBox(height: 12),
            _field(_description, 'Original spark', maxLines: 3),
            const SizedBox(height: 12),
            _field(_problem, 'Why it matters', maxLines: 3),
            const SizedBox(height: 12),
            _field(_targetUsers, 'Target users'),
            const SizedBox(height: 12),
            _field(_direction, 'Potential direction', maxLines: 2),
            const SizedBox(height: 12),
            _field(_hypothesis, 'Hypothesis', maxLines: 2),
            const SizedBox(height: 16),
            Text('Status', style: ReforgeTypography.bodyMedium),
            Wrap(
              spacing: 8,
              children: IdeaStatus.values
                  .map(
                    (status) => ChoiceChip(
                      label: Text(status.label),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text('Stage', style: ReforgeTypography.bodyMedium),
            Wrap(
              spacing: 8,
              children: IdeaStage.values
                  .map(
                    (stage) => ChoiceChip(
                      label: Text(stage.label),
                      selected: _stage == stage,
                      onSelected: (_) => setState(() => _stage = stage),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text('Tags', style: ReforgeTypography.bodyMedium),
            tagsAsync.when(
              data: (tags) => Wrap(
                spacing: 8,
                children: tags
                    .map(
                      (tag) => FilterChip(
                        label: Text(tag.name),
                        selected: _tagIds.contains(tag.id),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _tagIds.add(tag.id);
                          } else {
                            _tagIds.remove(tag.id);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(
                'Tags could not be loaded',
                style: ReforgeTypography.meta.copyWith(
                  color: ReforgeColors.danger,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: ReforgeColors.forgeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: ReforgeColors.elevatedSurface,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('A title is required.')));
      return;
    }
    setState(() => _saving = true);
    final updated = await ref
        .read(ideasActionProvider.notifier)
        .updateIdea(
          ideaId: widget.idea.id,
          title: _title.text.trim(),
          description: _description.text.trim(),
          problem: _problem.text.trim(),
          targetUsers: _targetUsers.text.trim(),
          potentialDirection: _direction.text.trim(),
          hypothesis: _hypothesis.text.trim(),
          status: _status,
          stage: _stage,
          tagIds: _tagIds.toList(),
        );
    if (!mounted) return;
    if (updated == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the idea. Please try again.'),
        ),
      );
      return;
    }
    ref.invalidate(ideaDetailProvider(widget.idea.id));
    Navigator.of(context).pop();
  }
}
