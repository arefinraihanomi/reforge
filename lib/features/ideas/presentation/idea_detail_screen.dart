import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/ai_gateway_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/idea.dart';
import '../../projects/presentation/convert_idea_dialog.dart';
import 'idea_edit_sheet.dart';
import 'ideas_notifier.dart';

/// Detail screen for a single idea — shows full content, evolution stepper,
/// workshop notes, and action buttons matching the reference design.
class IdeaDetailScreen extends ConsumerWidget {
  final String ideaId;

  const IdeaDetailScreen({super.key, required this.ideaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideaAsync = ref.watch(ideaDetailProvider(ideaId));

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      body: ideaAsync.when(
        data: (idea) => _IdeaDetailBody(idea: idea),
        loading: () => const Center(
          child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  size: 48,
                  color: ReforgeColors.danger,
                ),
                const SizedBox(height: 16),
                Text('Failed to load idea', style: ReforgeTypography.cardTitle),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: ReforgeTypography.body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IdeaDetailBody extends ConsumerWidget {
  final Idea idea;
  const _IdeaDetailBody({required this.idea});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // --- App Bar ---
        SliverAppBar(
          backgroundColor: ReforgeColors.warmSurface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: ReforgeColors.graphite,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Idea #${idea.ideaNumber.toString().padLeft(3, '0')}',
            style: ReforgeTypography.bodyMedium,
          ),
          actions: [
            Text(
              idea.status == IdeaStatus.draft ? 'Draft' : '',
              style: ReforgeTypography.bodyMedium.copyWith(
                color: ReforgeColors.muted,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                LucideIcons.ellipsisVertical,
                size: 20,
                color: ReforgeColors.graphite,
              ),
              onSelected: (value) => _handleMenuAction(context, ref, value),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Archive Idea'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: ReforgeColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ),

        // --- Content ---
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Header card: Status + Tags + Title + Meta
              _HeaderCard(idea: idea),
              const SizedBox(height: 20),

              // Reforge Evolution Stepper
              _EvolutionStepper(idea: idea),
              const SizedBox(height: 20),

              // Original Spark (Description)
              if (idea.description != null && idea.description!.isNotEmpty)
                _ContentSection(
                  icon: LucideIcons.mapPin,
                  iconColor: ReforgeColors.forgeAccent,
                  title: 'Original Spark',
                  content: idea.description!,
                ),

              // Why It Matters (Problem)
              if (idea.problem != null && idea.problem!.isNotEmpty)
                _ContentSection(
                  icon: LucideIcons.target,
                  iconColor: ReforgeColors.success,
                  title: 'Why It Matters',
                  content: idea.problem!,
                ),

              // Potential Direction
              if (idea.potentialDirection != null &&
                  idea.potentialDirection!.isNotEmpty)
                _ContentSection(
                  icon: LucideIcons.compass,
                  iconColor: ReforgeColors.category,
                  title: 'Potential Direction',
                  content: idea.potentialDirection!,
                ),

              // Workshop Notes & Scratches
              if (idea.workshopNotes.isNotEmpty)
                _WorkshopNotesSection(notes: idea.workshopNotes),

              const SizedBox(height: 24),

              // Action buttons
              _ActionButtons(idea: idea),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    switch (action) {
      case 'archive':
        final success = await ref
            .read(ideasActionProvider.notifier)
            .archiveIdea(idea.id);
        if (success && context.mounted) Navigator.of(context).pop();
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Idea?'),
            content: const Text(
              'This action is permanent and cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: ReforgeColors.danger,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final success = await ref
              .read(ideasActionProvider.notifier)
              .deleteIdea(idea.id);
          if (success && context.mounted) Navigator.of(context).pop();
        }
    }
  }
}

// =============================================================================
// Header Card
// =============================================================================

class _HeaderCard extends StatelessWidget {
  final Idea idea;
  const _HeaderCard({required this.idea});

  @override
  Widget build(BuildContext context) {
    final capturedDate = DateFormat('MMM d, yyyy').format(idea.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ReforgeColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReforgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Tag chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Status badge
              _StatusPill(status: idea.status),
              // Tags
              for (final tag in idea.tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ReforgeColors.categoryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag.name,
                    style: ReforgeTypography.badge.copyWith(
                      color: ReforgeColors.category,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(idea.title, style: ReforgeTypography.screenTitle),
          const SizedBox(height: 12),

          // Meta row: Captured date | Iterations | Notes logged
          Row(
            children: [
              const Icon(
                LucideIcons.clock,
                size: 14,
                color: ReforgeColors.muted,
              ),
              const SizedBox(width: 6),
              Text('Captured $capturedDate', style: ReforgeTypography.meta),
              const SizedBox(width: 16),
              Text('•', style: ReforgeTypography.meta),
              const SizedBox(width: 16),
              Text(
                '${idea.revisionsCount} ${idea.revisionsCount == 1 ? "iteration" : "iterations"}',
                style: ReforgeTypography.meta,
              ),
              const SizedBox(width: 16),
              Text('•', style: ReforgeTypography.meta),
              const SizedBox(width: 16),
              Text(
                '${idea.workshopNotes.length} notes logged',
                style: ReforgeTypography.meta,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IdeaStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color dot) = switch (status) {
      IdeaStatus.active => (
        ReforgeColors.successBg,
        ReforgeColors.success,
        ReforgeColors.success,
      ),
      IdeaStatus.exploring => (
        ReforgeColors.warningBg,
        ReforgeColors.warning,
        ReforgeColors.warning,
      ),
      IdeaStatus.building => (
        ReforgeColors.categoryBg,
        ReforgeColors.category,
        ReforgeColors.category,
      ),
      IdeaStatus.converted => (
        ReforgeColors.successBg,
        ReforgeColors.success,
        ReforgeColors.success,
      ),
      IdeaStatus.archived => (
        ReforgeColors.codeBg,
        ReforgeColors.muted,
        ReforgeColors.muted,
      ),
      IdeaStatus.draft => (
        ReforgeColors.codeBg,
        ReforgeColors.muted,
        ReforgeColors.muted,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'Status: ${status.label}',
            style: ReforgeTypography.badge.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Evolution Stepper
// =============================================================================

class _EvolutionStepper extends StatelessWidget {
  final Idea idea;
  const _EvolutionStepper({required this.idea});

  @override
  Widget build(BuildContext context) {
    final currentStageIndex = idea.stage.index;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ReforgeColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReforgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('REFORGE EVOLUTION', style: ReforgeTypography.overline),
              Text(
                'Stage ${idea.stage.number} of ${IdeaStage.values.length}',
                style: ReforgeTypography.badge.copyWith(
                  color: ReforgeColors.forgeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stage circles with connector lines
          Row(
            children: List.generate(IdeaStage.values.length, (index) {
              final stage = IdeaStage.values[index];
              final isCompleted = index < currentStageIndex;
              final isCurrent = index == currentStageIndex;
              final isLast = index == IdeaStage.values.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    // Stage circle
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? ReforgeColors.success
                                : isCurrent
                                ? ReforgeColors.forgeAccent
                                : ReforgeColors.border,
                            border: isCurrent
                                ? Border.all(
                                    color: ReforgeColors.forgeAccentLight,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: isCompleted
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : isCurrent
                              ? const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.white,
                                )
                              : const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: ReforgeColors.muted,
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stage.label,
                          style: ReforgeTypography.meta.copyWith(
                            fontWeight: isCurrent || isCompleted
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isCurrent
                                ? ReforgeColors.forgeAccent
                                : isCompleted
                                ? ReforgeColors.success
                                : ReforgeColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    // Connector line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 18),
                          color: index < currentStageIndex
                              ? ReforgeColors.success
                              : ReforgeColors.border,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Content Sections
// =============================================================================

class _ContentSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _ContentSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ReforgeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(title, style: ReforgeTypography.subTitle),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: ReforgeTypography.body.copyWith(
                color: ReforgeColors.graphite,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Workshop Notes Section
// =============================================================================

class _WorkshopNotesSection extends StatelessWidget {
  final List<WorkshopNote> notes;
  const _WorkshopNotesSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ReforgeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.clipboardList,
                  size: 18,
                  color: ReforgeColors.graphite,
                ),
                const SizedBox(width: 8),
                Text(
                  'Workshop Notes & Scratches',
                  style: ReforgeTypography.subTitle,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ReforgeColors.codeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${notes.length} ${notes.length == 1 ? "entry" : "entries"}',
                    style: ReforgeTypography.badge.copyWith(
                      color: ReforgeColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 7),
                      decoration: const BoxDecoration(
                        color: ReforgeColors.forgeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note.text,
                        style: ReforgeTypography.body.copyWith(
                          color: ReforgeColors.graphite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Action Buttons
// =============================================================================

class _ActionButtons extends ConsumerStatefulWidget {
  final Idea idea;
  const _ActionButtons({required this.idea});

  @override
  ConsumerState<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends ConsumerState<_ActionButtons> {
  bool _aiLoading = false;
  _AiIdeaReviewCard? _aiResult;

  Future<void> _runAiReview() async {
    setState(() {
      _aiLoading = true;
      _aiResult = null;
    });
    final service = ref.read(aiGatewayServiceProvider);
    final result = await service.reviewIdea(
      title: widget.idea.title,
      description: widget.idea.description,
      tags: widget.idea.tags.map((t) => t.name).toList(),
    );
    if (mounted) {
      setState(() {
        _aiLoading = false;
        if (result != null) {
          _aiResult = _AiIdeaReviewCard(
            summary: result.summary,
            risks: result.risks,
            mvpCut: result.recommendedMvpCut,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI review unavailable. Please enter details manually.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI Advisory Card (non-blocking — shown if result available)
        if (_aiResult != null) ...[
          _aiResult!,
          const SizedBox(height: 12),
        ],

        // AI Review Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _aiLoading ? null : _runAiReview,
            icon: _aiLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ReforgeColors.forgeAccent,
                    ),
                  )
                : const Icon(LucideIcons.bot, size: 16, color: ReforgeColors.forgeAccent),
            label: Text(
              _aiLoading ? 'Reviewing with AI...' : 'AI Scope Review 🤖',
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
        const SizedBox(height: 12),

        // Primary CTA: Turn into Project
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              ConvertIdeaDialog.show(context, widget.idea);
            },
            icon: const Icon(LucideIcons.hammer, size: 18),
            label: const Text('Turn into Project →'),
            style: FilledButton.styleFrom(
              backgroundColor: ReforgeColors.forgeAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: ReforgeTypography.buttonPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showIdeaEditSheet(context, widget.idea),
                icon: const Icon(LucideIcons.penLine, size: 16),
                label: const Text('Edit Idea'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ReforgeColors.graphite,
                  side: const BorderSide(color: ReforgeColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: ReforgeTypography.bodyMedium,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final success = await ref
                      .read(ideasActionProvider.notifier)
                      .archiveIdea(widget.idea.id);
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(LucideIcons.archive, size: 16),
                label: const Text('Graveyard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ReforgeColors.graphite,
                  side: const BorderSide(color: ReforgeColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: ReforgeTypography.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// AI Idea Review Result Card
// =============================================================================

class _AiIdeaReviewCard extends StatelessWidget {
  final String summary;
  final List<String> risks;
  final String mvpCut;

  const _AiIdeaReviewCard({
    required this.summary,
    required this.risks,
    required this.mvpCut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReforgeColors.forgeAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReforgeColors.forgeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bot, size: 16, color: ReforgeColors.forgeAccent),
              const SizedBox(width: 8),
              Text(
                'AI Scope Advisory',
                style: ReforgeTypography.cardTitle.copyWith(
                  color: ReforgeColors.forgeAccent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(summary, style: ReforgeTypography.body),
          if (risks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Scope Risks',
              style: ReforgeTypography.meta.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final risk in risks)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      size: 12,
                      color: ReforgeColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(risk, style: ReforgeTypography.bodySmall)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ReforgeColors.successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.scissors, size: 14, color: ReforgeColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommended MVP Cut: $mvpCut',
                    style: ReforgeTypography.bodySmall.copyWith(
                      color: ReforgeColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

