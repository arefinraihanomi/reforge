import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../postmortem/presentation/postmortem_notifier.dart';
import '../../projects/models/project.dart';
import '../../projects/presentation/projects_notifier.dart';
import 'reforge_notifier.dart';

class ReforgeWizardScreen extends ConsumerStatefulWidget {
  final String sourceProjectId;

  const ReforgeWizardScreen({
    super.key,
    required this.sourceProjectId,
  });

  @override
  ConsumerState<ReforgeWizardScreen> createState() => _ReforgeWizardScreenState();
}

class _ReforgeWizardScreenState extends ConsumerState<ReforgeWizardScreen> {
  int _currentStep = 0;
  final Set<String> _selectedLessons = {};
  late final TextEditingController _v2TitleController;
  late final TextEditingController _v2ScopeController;
  late final TextEditingController _changesSummaryController;
  late final TextEditingController _taskInputController;
  final List<String> _initialTasks = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _v2TitleController = TextEditingController();
    _v2ScopeController = TextEditingController();
    _changesSummaryController = TextEditingController();
    _taskInputController = TextEditingController();

    _initialTasks.addAll([
      'Setup tighter V2 core layout',
      'Implement lesson-backed architecture',
    ]);
  }

  @override
  void dispose() {
    _v2TitleController.dispose();
    _v2ScopeController.dispose();
    _changesSummaryController.dispose();
    _taskInputController.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _taskInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _initialTasks.add(text);
        _taskInputController.clear();
      });
    }
  }

  void _removeTask(int index) {
    setState(() {
      _initialTasks.removeAt(index);
    });
  }



  Future<void> _submitReforge() async {
    final title = _v2TitleController.text.trim();
    final scope = _v2ScopeController.text.trim();

    if (title.isEmpty || scope.isEmpty) {
      setState(() => _errorMessage = 'Please provide both V2 Title and a tight MVP Scope.');
      return;
    }

    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final newProjectId = await ref
        .read(reforgeActionProvider.notifier)
        .resurrectProjectToV2(
          sourceProjectId: widget.sourceProjectId,
          v2Title: title,
          v2MvpScope: scope,
          selectedLessons: _selectedLessons.toList(),
          initialTasks: _initialTasks,
          changesSummary: _changesSummaryController.text.trim(),
        );

    if (mounted) {
      if (newProjectId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('V2 Project successfully forged! Ancestor lessons linked.')),
        );
        context.go('/projects/$newProjectId');
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to forge V2 project. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancestorAsync = ref.watch(projectDetailProvider(widget.sourceProjectId));
    final lessonsAsync = ref.watch(projectLessonsProvider(widget.sourceProjectId));
    final postmortemAsync = ref.watch(projectPostmortemProvider(widget.sourceProjectId));

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
          'Reforge Resurrection Wizard (V2)',
          style: ReforgeTypography.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: ancestorAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
        ),
        error: (err, _) => Center(
          child: Text('Error loading ancestor project: ${err.toString()}'),
        ),
        data: (ancestor) {
          if (_v2TitleController.text.isEmpty) {
            _v2TitleController.text = '${ancestor.title} v2';
          }

          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: ReforgeColors.forgeAccent,
                  ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Step Progress Header
                  Row(
                    children: [
                      _buildStepHeaderBadge(0, '1. Lessons'),
                      const Expanded(child: Divider(indent: 8, endIndent: 8)),
                      _buildStepHeaderBadge(1, '2. V2 Scope'),
                      const Expanded(child: Divider(indent: 8, endIndent: 8)),
                      _buildStepHeaderBadge(2, '3. Forge'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Active Step Content
                  if (_currentStep == 0)
                    _buildStep1(ancestor, lessonsAsync, postmortemAsync)
                  else if (_currentStep == 1)
                    _buildStep2()
                  else
                    _buildStep3(ancestor),

                  const SizedBox(height: 32),

                  // Bottom Controls Row
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (_currentStep < 2) {
                                  setState(() => _currentStep++);
                                } else {
                                  _submitReforge();
                                }
                              },
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(
                                _currentStep == 2 ? LucideIcons.hammer : LucideIcons.arrowRight,
                                size: 18,
                              ),
                        label: Text(_currentStep == 2
                            ? (_isSubmitting ? 'Forging V2...' : 'Forge V2 Project 🔥')
                            : 'Next Step'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ReforgeColors.forgeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            if (_currentStep > 0) {
                              setState(() => _currentStep--);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ReforgeColors.graphite,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            side: const BorderSide(color: ReforgeColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Back'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepHeaderBadge(int stepIndex, String title) {
    final isActive = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? ReforgeColors.forgeAccent
            : (isActive ? ReforgeColors.deepSlate : ReforgeColors.warmSurface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.transparent : ReforgeColors.border,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          color: isActive ? Colors.white : ReforgeColors.graphite,
        ),
      ),
    );
  }

  Widget _buildStep1(
    Project ancestor,
    AsyncValue<List<dynamic>> lessonsAsync,
    AsyncValue<dynamic> postmortemAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ReforgeColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ReforgeColors.border),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.history, color: ReforgeColors.deepSlate, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ancestor V1: ${ancestor.title}', style: ReforgeTypography.cardTitle),
                    Text(
                      'Stopping Reason: ${ancestor.abandonReason ?? "Abandoned"}',
                      style: ReforgeTypography.meta,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Select Lessons to Apply to V2',
          style: ReforgeTypography.sectionTitle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'Check the key insights from V1 that will guide V2 development.',
          style: ReforgeTypography.meta,
        ),
        const SizedBox(height: 12),

        lessonsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const Text('No lessons recorded yet.', style: ReforgeTypography.meta),
          data: (lessons) {
            if (lessons.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ReforgeColors.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ReforgeColors.border),
                ),
                child: const Text(
                  'No lessons explicitly saved in post-mortem. You can still define a tighter scope in Step 2.',
                  style: ReforgeTypography.meta,
                ),
              );
            }

            return Column(
              children: lessons.map((l) {
                final String text = l.lesson as String;
                final isSelected = _selectedLessons.contains(text);

                return CheckboxListTile(
                  value: isSelected,
                  activeColor: ReforgeColors.forgeAccent,
                  title: Text(text, style: ReforgeTypography.body),
                  subtitle: Text('Category: ${l.category}', style: ReforgeTypography.meta),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedLessons.add(text);
                      } else {
                        _selectedLessons.remove(text);
                      }
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('V2 Project Title', style: ReforgeTypography.cardTitle.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: _v2TitleController,
          style: ReforgeTypography.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: ReforgeColors.cardSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ReforgeColors.border),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Tighter MVP Scope Input
        Text('Tighter V2 MVP Scope Boundary (Mandatory)', style: ReforgeTypography.cardTitle.copyWith(fontSize: 14)),
        const SizedBox(height: 4),
        const Text(
          'Cut unnecessary features from V1. What is the single core value proposition?',
          style: ReforgeTypography.meta,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _v2ScopeController,
          maxLines: 3,
          style: ReforgeTypography.body,
          decoration: InputDecoration(
            hintText: 'e.g. Remove custom plugin system; focus strictly on 1 core screen with local storage.',
            filled: true,
            fillColor: ReforgeColors.cardSurface,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ReforgeColors.border),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text('Summary of Architectural Changes (Optional)', style: ReforgeTypography.cardTitle.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: _changesSummaryController,
          maxLines: 2,
          style: ReforgeTypography.body,
          decoration: InputDecoration(
            hintText: 'e.g. Replaced SQLite with Supabase RLS; simplified UI layout.',
            filled: true,
            fillColor: ReforgeColors.cardSurface,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ReforgeColors.border),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Initial V2 Tasks
        Text('Initial V2 Checklist Tasks', style: ReforgeTypography.cardTitle.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taskInputController,
                style: ReforgeTypography.body,
                onSubmitted: (_) => _addTask(),
                decoration: InputDecoration(
                  hintText: 'Add V2 task...',
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
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: ReforgeColors.deepSlate,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Icon(LucideIcons.plus, size: 18),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_initialTasks.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _initialTasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ReforgeColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ReforgeColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkSquare, size: 16, color: ReforgeColors.forgeAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_initialTasks[index], style: ReforgeTypography.body.copyWith(fontSize: 13)),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 16, color: ReforgeColors.subtle),
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
    );
  }

  Widget _buildStep3(Project ancestor) {
    final v1Scope = ancestor.mvpScope ?? 'No scope defined for V1';
    final v2Scope = _v2ScopeController.text.trim();
    final hasScopeDiff = v2Scope.isNotEmpty && v2Scope != v1Scope;

    // Pre-flight checklist items
    final preflightItems = [
      _PreflightItem(
        label: 'V2 title is defined',
        isPassed: _v2TitleController.text.trim().isNotEmpty,
      ),
      _PreflightItem(
        label: 'Tighter MVP scope boundary is specified',
        isPassed: v2Scope.isNotEmpty,
      ),
      _PreflightItem(
        label: 'Scope differs from V1 (no copy-paste)',
        isPassed: hasScopeDiff,
      ),
      _PreflightItem(
        label: 'At least one lesson selected from V1',
        isPassed: _selectedLessons.isNotEmpty,
        isWarning: _selectedLessons.isEmpty,
        warningNote: 'Optional, but recommended to carry forward V1 wisdom.',
      ),
      _PreflightItem(
        label: 'Initial V2 tasks are defined',
        isPassed: _initialTasks.isNotEmpty,
      ),
    ];

    final allCriticalPassed = preflightItems
        .where((i) => !i.isWarning)
        .every((i) => i.isPassed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              style: ReforgeTypography.bodySmall.copyWith(color: ReforgeColors.danger),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Pre-flight Checklist
        Text('Pre-Flight Checklist', style: ReforgeTypography.cardTitle.copyWith(fontSize: 15)),
        const SizedBox(height: 4),
        const Text(
          'Ensure all critical items pass before forging V2.',
          style: ReforgeTypography.meta,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ReforgeColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ReforgeColors.border),
          ),
          child: Column(
            children: preflightItems.map((item) {
              final Color iconColor;
              final IconData icon;
              if (item.isPassed) {
                iconColor = ReforgeColors.success;
                icon = LucideIcons.checkCircle2;
              } else if (item.isWarning) {
                iconColor = ReforgeColors.warning;
                icon = LucideIcons.alertCircle;
              } else {
                iconColor = ReforgeColors.danger;
                icon = LucideIcons.xCircle;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: ReforgeTypography.body.copyWith(
                              color: item.isPassed ? ReforgeColors.graphite : iconColor,
                              fontWeight: item.isPassed ? FontWeight.normal : FontWeight.w500,
                            ),
                          ),
                          if (!item.isPassed && item.warningNote != null)
                            Text(item.warningNote!, style: ReforgeTypography.meta),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Scope Diff Panel
        Text('Scope Diff: V1 → V2', style: ReforgeTypography.cardTitle.copyWith(fontSize: 15)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ScopeDiffCard(
                label: 'V1 Scope (Ancestor)',
                content: v1Scope,
                color: ReforgeColors.dangerBg,
                borderColor: ReforgeColors.dangerBorder,
                icon: LucideIcons.history,
                iconColor: ReforgeColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ScopeDiffCard(
                label: 'V2 Scope (New)',
                content: v2Scope.isNotEmpty ? v2Scope : '(not yet defined — go back to Step 2)',
                color: ReforgeColors.successBg,
                borderColor: ReforgeColors.successBorder,
                icon: LucideIcons.hammer,
                iconColor: ReforgeColors.success,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: allCriticalPassed
                ? ReforgeColors.forgeAccent.withValues(alpha: 0.08)
                : ReforgeColors.dangerBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: allCriticalPassed
                  ? ReforgeColors.forgeAccent.withValues(alpha: 0.3)
                  : ReforgeColors.dangerBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    allCriticalPassed ? LucideIcons.hammer : LucideIcons.alertTriangle,
                    color: allCriticalPassed ? ReforgeColors.forgeAccent : ReforgeColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    allCriticalPassed ? 'Ready to Forge V2 Project' : 'Complete checklist before forging',
                    style: ReforgeTypography.cardTitle.copyWith(
                      color: allCriticalPassed ? ReforgeColors.forgeAccent : ReforgeColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Project Name: ${_v2TitleController.text}', style: ReforgeTypography.bodyMedium),
              const SizedBox(height: 4),
              Text('Ancestor Link: ${ancestor.title} (V1)', style: ReforgeTypography.meta),
              const SizedBox(height: 4),
              Text('Lessons Carried Forward: ${_selectedLessons.length}', style: ReforgeTypography.meta),
              Text('Initial Tasks Configured: ${_initialTasks.length}', style: ReforgeTypography.meta),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pre-flight checklist item data model
// ---------------------------------------------------------------------------
class _PreflightItem {
  final String label;
  final bool isPassed;
  final bool isWarning;
  final String? warningNote;

  const _PreflightItem({
    required this.label,
    required this.isPassed,
    this.isWarning = false,
    this.warningNote,
  });
}

// ---------------------------------------------------------------------------
// Scope diff card widget
// ---------------------------------------------------------------------------
class _ScopeDiffCard extends StatelessWidget {
  final String label;
  final String content;
  final Color color;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;

  const _ScopeDiffCard({
    required this.label,
    required this.content,
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: ReforgeTypography.badge.copyWith(color: iconColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: ReforgeTypography.bodySmall.copyWith(height: 1.4),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
