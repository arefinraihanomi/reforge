import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../ideas/models/idea.dart';
import 'projects_notifier.dart';
import '../../../core/errors/failures.dart';

class ConvertIdeaDialog extends ConsumerStatefulWidget {
  final Idea idea;

  const ConvertIdeaDialog({
    super.key,
    required this.idea,
  });

  static Future<void> show(BuildContext context, Idea idea) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConvertIdeaDialog(idea: idea),
    );
  }

  @override
  ConsumerState<ConvertIdeaDialog> createState() => _ConvertIdeaDialogState();
}

class _ConvertIdeaDialogState extends ConsumerState<ConvertIdeaDialog> {
  late final TextEditingController _mvpScopeController;
  late final TextEditingController _taskInputController;
  final List<String> _tasks = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mvpScopeController = TextEditingController(
      text: widget.idea.hypothesis ?? widget.idea.problem ?? '',
    );
    _taskInputController = TextEditingController();
    
    // Default initial starter tasks if none
    _tasks.addAll([
      'Define core schema & entities',
      'Build primary user flow',
      'Setup MVP verification test',
    ]);
  }

  @override
  void dispose() {
    _mvpScopeController.dispose();
    _taskInputController.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _taskInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tasks.add(text);
        _taskInputController.clear();
      });
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  Future<void> _submitConversion() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final projectId = await ref
          .read(projectsActionProvider.notifier)
          .convertIdeaToProject(
            ideaId: widget.idea.id,
            ideaTitle: widget.idea.title,
            ideaSummary: widget.idea.description ?? widget.idea.problem,
            ideaHypothesis: widget.idea.hypothesis,
            mvpScope: _mvpScopeController.text.trim(),
            initialTasks: _tasks,
          );

      if (projectId == null || projectId.isEmpty) {
        throw Exception('Failed to convert idea to project.');
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        context.go('/projects/$projectId'); // Navigate to project workspace
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e is AppFailure
              ? e.message
              : e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: ReforgeColors.warmSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (ReforgeColors.deepSlateMuted),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ReforgeColors.forgeAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.hammer,
                  color: ReforgeColors.forgeAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convert Idea to Project',
                      style: ReforgeTypography.screenTitle.copyWith(fontSize: 18),
                    ),
                    Text(
                      'Transform "${widget.idea.title}" into active workspace',
                      style: ReforgeTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ReforgeColors.dangerBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ReforgeColors.dangerBorder),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: ReforgeColors.danger, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MVP Scope Boundary Banner Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ReforgeColors.warmSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ReforgeColors.forgeAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.target,
                              size: 16,
                              color: ReforgeColors.forgeAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'MVP Scope Boundary',
                              style: ReforgeTypography.cardTitle.copyWith(
                                color: ReforgeColors.forgeAccent,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Define what is STRICTLY included in v1. Avoid scope creep before building.',
                          style: ReforgeTypography.caption,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _mvpScopeController,
                          maxLines: 3,
                          style: ReforgeTypography.body,
                          decoration: InputDecoration(
                            hintText: 'e.g. Essential 3 screens, local SQLite, basic auth only.',
                            filled: true,
                            fillColor: ReforgeColors.warmSurface,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: ReforgeColors.deepSlateMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Initial Checklist Tasks
                  Text(
                    'Initial Task Checklist',
                    style: ReforgeTypography.sectionTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Break down initial build steps into manageable tasks.',
                    style: ReforgeTypography.caption,
                  ),
                  const SizedBox(height: 10),

                  // Add Task Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskInputController,
                          style: ReforgeTypography.body,
                          onSubmitted: (_) => _addTask(),
                          decoration: InputDecoration(
                            hintText: 'Add initial task...',
                            filled: true,
                            fillColor: ReforgeColors.warmSurface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: ReforgeColors.deepSlateMuted),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ReforgeColors.deepSlate,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(LucideIcons.plus, size: 18),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Tasks list chips
                  if (_tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No initial tasks added.',
                        style: ReforgeTypography.caption,
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: ReforgeColors.warmSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ReforgeColors.deepSlateMuted),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.checkSquare, size: 16, color: ReforgeColors.deepSlate),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _tasks[index],
                                  style: ReforgeTypography.body.copyWith(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16, color: ReforgeColors.deepSlate),
                                onPressed: () => _removeTask(index),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Submit Action Button
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitConversion,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.hammer, size: 18),
            label: Text(_isSubmitting ? 'Forging Project...' : 'Forge into Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ReforgeColors.forgeAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: ReforgeTypography.cardTitle.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
