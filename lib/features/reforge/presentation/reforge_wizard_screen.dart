import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/ai_gateway_service.dart';
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
  bool _isAiSuggesting = false;
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

  Future<void> _aiSuggestReforgeStrategy(String ancestorTitle, String? abandonReason) async {
    if (_isAiSuggesting) return;
    setState(() => _isAiSuggesting = true);

    final service = ref.read(aiGatewayServiceProvider);
    final result = await service.suggestReforgeStrategy(
      ancestorTitle: ancestorTitle,
      abandonReason: abandonReason,
      selectedLessons: _selectedLessons.toList(),
    );

    if (mounted) {
      if (result != null) {
        setState(() {
          if (_v2ScopeController.text.isEmpty && result.tighterMvpScope.isNotEmpty) {
            _v2ScopeController.text = result.tighterMvpScope;
          }
          if (_changesSummaryController.text.isEmpty && result.simplifications.isNotEmpty) {
            _changesSummaryController.text = result.simplifications.join('\n• ');
          }
          for (final task in result.recommendedTasks) {
            if (!_initialTasks.contains(task)) {
              _initialTasks.add(task);
            }
          }
          _isAiSuggesting = false;
        });
        // Move to Step 2 so user can review AI-prefilled scope
        if (_currentStep == 0) setState(() => _currentStep = 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI strategy ready — review in Step 2 before forging.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isAiSuggesting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI suggestion unavailable. Continue manually.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _submitReforge();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : details.onStepContinue,
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
                          onPressed: details.onStepCancel,
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
                );
              },
              steps: [
                // STEP 1: Lessons Review
                Step(
                  title: const Text('Lessons'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildStep1(ancestor, lessonsAsync, postmortemAsync),
                ),

                // STEP 2: Refined Scope & Tasks
                Step(
                  title: const Text('V2 Scope'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildStep2(),
                ),

                // STEP 3: Confirm & Forge
                Step(
                  title: const Text('Forge'),
                  isActive: _currentStep >= 2,
                  state: StepState.indexed,
                  content: _buildStep3(ancestor),
                ),
              ],
            ),
          );
        },
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
          loading: () => const CircularProgressIndicator(color: ReforgeColors.forgeAccent),
          error: (_, __) => const Text('No lessons recorded yet.', style: ReforgeTypography.meta),
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
            );         },
        ),

        const SizedBox(height: 16),

        // AI Suggest Strategy button — pre-fills Step 2 scope & tasks
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isAiSuggesting
                ? null
                : () => _aiSuggestReforgeStrategy(
                      ancestor.title,
                      ancestor.abandonReason,
                    ),
            icon: _isAiSuggesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ReforgeColors.forgeAccent,
                    ),
                  )
                : const Icon(LucideIcons.sparkles, size: 16, color: ReforgeColors.forgeAccent),
            label: Text(
              _isAiSuggesting ? 'Generating V2 Strategy...' : 'AI Suggest V2 Strategy ✨',
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

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ReforgeColors.forgeAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ReforgeColors.forgeAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.hammer, color: ReforgeColors.forgeAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ready to Forge V2 Project',
                    style: ReforgeTypography.cardTitle.copyWith(color: ReforgeColors.forgeAccent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Project Name: ${_v2TitleController.text}', style: ReforgeTypography.bodyMedium),
              const SizedBox(height: 4),
              Text('Ancestor Link: ${ancestor.title} (V1)', style: ReforgeTypography.meta),
              const SizedBox(height: 4),
              Text('Scope Boundary: ${_v2ScopeController.text}', style: ReforgeTypography.body),
              const SizedBox(height: 8),
              Text('Lessons Carried Forward: ${_selectedLessons.length}', style: ReforgeTypography.meta),
              Text('Initial Tasks Configured: ${_initialTasks.length}', style: ReforgeTypography.meta),
            ],
          ),
        ),
      ],
    );
  }
}
