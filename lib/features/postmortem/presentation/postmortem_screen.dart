import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/ai_gateway_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../projects/presentation/projects_notifier.dart';
import 'postmortem_notifier.dart';

class PostmortemScreen extends ConsumerStatefulWidget {
  final String projectId;

  const PostmortemScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<PostmortemScreen> createState() => _PostmortemScreenState();
}

class _PostmortemScreenState extends ConsumerState<PostmortemScreen> {
  late final TextEditingController _whatWentWrongController;
  late final TextEditingController _whatWentWellController;
  late final TextEditingController _lessonInputController;
  String _lessonCategory = 'architecture';
  final List<Map<String, String>> _lessons = [];

  bool _isSubmitting = false;
  bool _isAiDrafting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _whatWentWrongController = TextEditingController();
    _whatWentWellController = TextEditingController();
    _lessonInputController = TextEditingController();
  }

  @override
  void dispose() {
    _whatWentWrongController.dispose();
    _whatWentWellController.dispose();
    _lessonInputController.dispose();
    super.dispose();
  }

  void _addLesson() {
    final text = _lessonInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _lessons.add({
          'lesson': text,
          'category': _lessonCategory,
        });
        _lessonInputController.clear();
      });
    }
  }

  void _removeLesson(int index) {
    setState(() {
      _lessons.removeAt(index);
    });
  }

  Future<void> _aiDraftPostmortem(String projectTitle, String? abandonReason, String? abandonNote) async {
    if (_isAiDrafting) return;
    setState(() => _isAiDrafting = true);

    final service = ref.read(aiGatewayServiceProvider);
    final result = await service.generatePostmortemDraft(
      title: projectTitle,
      abandonReason: abandonReason,
      abandonNote: abandonNote,
    );

    if (mounted) {
      if (result != null) {
        setState(() {
          if (_whatWentWrongController.text.isEmpty) {
            _whatWentWrongController.text = result.whatWentWrong;
          }
          if (_whatWentWellController.text.isEmpty) {
            _whatWentWellController.text = result.whatWentWell;
          }
          for (final lesson in result.suggestedLessons) {
            if (!_lessons.any((l) => l['lesson'] == lesson['lesson'])) {
              _lessons.add({
                'lesson': lesson['lesson'] ?? '',
                'category': lesson['category'] ?? 'architecture',
              });
            }
          }
          _isAiDrafting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI draft ready — review and edit before saving.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isAiDrafting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI draft unavailable. Please fill in the form manually.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitPostmortem(String primaryReason) async {
    final wrongText = _whatWentWrongController.text.trim();
    if (wrongText.isEmpty) {
      setState(() => _errorMessage = 'Please describe what went wrong or why the project stopped.');
      return;
    }

    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final postmortem = await ref
        .read(postmortemActionProvider.notifier)
        .savePostmortem(
          projectId: widget.projectId,
          primaryReason: primaryReason,
          whatWentWrong: wrongText,
          whatWentWell: _whatWentWellController.text.trim(),
          lessons: _lessons,
        );

    if (mounted) {
      if (postmortem != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post-Mortem completed! Reusable lessons saved.')),
        );
        context.go('/home');
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to save post-mortem. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      appBar: AppBar(
        backgroundColor: ReforgeColors.warmSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: ReforgeColors.deepSlate),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Project Post-Mortem',
          style: ReforgeTypography.screenTitle.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Reforge into V2',
            icon: const Icon(LucideIcons.flame, color: ReforgeColors.forgeAccent),
            onPressed: () => context.go('/reforge/${widget.projectId}'),
          ),
        ],
      ),
      body: projectAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
        ),
        error: (err, _) => Center(
          child: Text('Error loading project: ${err.toString()}'),
        ),
        data: (project) {
          final primaryReason = project.abandonReason ?? 'other';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Project Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ReforgeColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ReforgeColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ReforgeColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.skull, color: ReforgeColors.danger, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              style: ReforgeTypography.cardTitle.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reason: ${project.abandonReason ?? "Abandoned"}',
                              style: ReforgeTypography.meta,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                      style: ReforgeTypography.bodySmall.copyWith(
                        color: ReforgeColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // AI Draft Button — pre-fills form based on project history
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAiDrafting
                        ? null
                        : () => _aiDraftPostmortem(
                              project.title,
                              project.abandonReason,
                              project.abandonNote,
                            ),
                    icon: _isAiDrafting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ReforgeColors.forgeAccent,
                            ),
                          )
                        : const Icon(
                            LucideIcons.sparkles,
                            size: 16,
                            color: ReforgeColors.forgeAccent,
                          ),
                    label: Text(
                      _isAiDrafting ? 'Drafting with AI...' : 'AI Draft Post-Mortem ✨',
                      style: ReforgeTypography.bodyMedium.copyWith(
                        color: ReforgeColors.forgeAccent,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ReforgeColors.forgeAccent,
                      side: const BorderSide(color: ReforgeColors.forgeAccent),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Postmortem Form Fields
                Text(
                  '1. What Went Wrong?',
                  style: ReforgeTypography.sectionTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Identify the root causes (architectural complexity, scope creep, wrong tech choice).',
                  style: ReforgeTypography.meta,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _whatWentWrongController,
                  maxLines: 4,
                  style: ReforgeTypography.body,
                  decoration: InputDecoration(
                    hintText: 'e.g. Tried building a custom state manager instead of using Riverpod; schema migration became unmaintainable.',
                    filled: true,
                    fillColor: ReforgeColors.cardSurface,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ReforgeColors.border),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  '2. What Went Well? (Optional)',
                  style: ReforgeTypography.sectionTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Acknowledge wins, good design choices, or useful components built.',
                  style: ReforgeTypography.meta,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _whatWentWellController,
                  maxLines: 3,
                  style: ReforgeTypography.body,
                  decoration: InputDecoration(
                    hintText: 'e.g. Supabase RLS security policies worked cleanly; UI design token setup was fast.',
                    filled: true,
                    fillColor: ReforgeColors.cardSurface,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ReforgeColors.border),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Extract Reusable Lessons Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ReforgeColors.forgeAccent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ReforgeColors.forgeAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.lightbulb, size: 18, color: ReforgeColors.forgeAccent),
                          const SizedBox(width: 8),
                          Text(
                            '3. Extract Reusable Lessons for V2',
                            style: ReforgeTypography.cardTitle.copyWith(
                              color: ReforgeColors.forgeAccent,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'These takeaways will carry forward into future projects and V2 resurrection.',
                        style: ReforgeTypography.meta,
                      ),
                      const SizedBox(height: 12),

                      // Category Selector & Lesson Input
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: _lessonCategory,
                            underline: const SizedBox(),
                            style: ReforgeTypography.bodySmall.copyWith(
                              color: ReforgeColors.graphite,
                              fontWeight: FontWeight.bold,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'architecture', child: Text('Architecture')),
                              DropdownMenuItem(value: 'scope', child: Text('Scope')),
                              DropdownMenuItem(value: 'technical', child: Text('Technical')),
                              DropdownMenuItem(value: 'process', child: Text('Process')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _lessonCategory = val);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _lessonInputController,
                              style: ReforgeTypography.body,
                              onSubmitted: (_) => _addLesson(),
                              decoration: InputDecoration(
                                hintText: 'Add reusable lesson...',
                                filled: true,
                                fillColor: ReforgeColors.cardSurface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: ReforgeColors.border),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addLesson,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ReforgeColors.forgeAccent,
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

                      // Lessons list
                      if (_lessons.isNotEmpty)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _lessons.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final lessonItem = _lessons[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: ReforgeColors.cardSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ReforgeColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ReforgeColors.quoteBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      lessonItem['category']!.toUpperCase(),
                                      style: ReforgeTypography.badge.copyWith(
                                        fontSize: 9,
                                        color: ReforgeColors.codeText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lessonItem['lesson']!,
                                      style: ReforgeTypography.body.copyWith(fontSize: 13),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: ReforgeColors.subtle),
                                    onPressed: () => _removeLesson(index),
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

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _submitPostmortem(primaryReason),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.checkCircle2, size: 18),
                  label: Text(_isSubmitting ? 'Preserving Knowledge...' : 'Complete Post-Mortem & Preserve Lessons'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ReforgeColors.deepSlate,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: ReforgeTypography.buttonPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
