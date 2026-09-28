import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/shell_screen.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/idea.dart';
import '../../projects/presentation/convert_idea_dialog.dart';
import 'idea_edit_sheet.dart';
import 'ideas_notifier.dart';

/// Detail screen for a single idea — upgraded with sticky bottom actions,
/// interactive stage stepper info, and polished empty/placeholder states.
class IdeaDetailScreen extends ConsumerWidget {
  final String ideaId;

  const IdeaDetailScreen({super.key, required this.ideaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideaAsync = ref.watch(ideaDetailProvider(ideaId));

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      appBar: AppBar(
        backgroundColor: ReforgeColors.warmSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: ReforgeColors.graphite,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Idea Details', style: ReforgeTypography.bodyMedium),
        actions: [
          ideaAsync.maybeWhen(
            data: (idea) => idea.status == IdeaStatus.draft
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        'Draft',
                        style: ReforgeTypography.bodyMedium.copyWith(
                          color: ReforgeColors.muted,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          ideaAsync.maybeWhen(
            data: (idea) => PopupMenuButton<String>(
              icon: const Icon(
                LucideIcons.ellipsisVertical,
                size: 20,
                color: ReforgeColors.graphite,
              ),
              onSelected: (value) =>
                  _handleMenuAction(context, ref, idea, value),
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
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
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
      // --- Sticky Bottom Action Bar Added ---
      bottomNavigationBar: ideaAsync.maybeWhen(
        data: (idea) => _StickyBottomActionBar(idea: idea),
        orElse: () => null,
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    Idea idea,
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

class _IdeaDetailBody extends StatelessWidget {
  final Idea idea;
  const _IdeaDetailBody({required this.idea});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        // Header card: Status + Tags + Title + Meta
        _HeaderCard(idea: idea),
        const SizedBox(height: 20),

        // Reforge Evolution Stepper (Interactive)
        _EvolutionStepper(idea: idea),
        const SizedBox(height: 20),

        // Original Spark (Description)
        _ContentSection(
          icon: LucideIcons.mapPin,
          iconColor: ReforgeColors.forgeAccent,
          title: 'Original Spark',
          content: idea.description,
          emptyPlaceholder: 'No description provided yet. Tap edit to flesh out your idea spark!',
        ),

        // Why It Matters (Problem)
        _ContentSection(
          icon: LucideIcons.target,
          iconColor: ReforgeColors.success,
          title: 'Why It Matters',
          content: idea.problem,
          emptyPlaceholder: 'Define the core problem this idea solves to give it more weight.',
        ),

        // Potential Direction
        _ContentSection(
          icon: LucideIcons.compass,
          iconColor: ReforgeColors.category,
          title: 'Potential Direction',
          content: idea.potentialDirection,
          emptyPlaceholder:
              'Add potential tech stacks, markets, or product directions.',
        ),

        // Workshop Notes & Scratches
        if (idea.workshopNotes.isNotEmpty)
          _WorkshopNotesSection(notes: idea.workshopNotes),
      ],
    );
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReforgeColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(status: idea.status),
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
          Text(idea.title, style: ReforgeTypography.screenTitle),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: ReforgeColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text('Captured $capturedDate', style: ReforgeTypography.meta),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${idea.revisionsCount} ${idea.revisionsCount == 1 ? "iteration" : "iterations"}',
                    style: ReforgeTypography.meta,
                  ),
                  Text(
                    '${idea.workshopNotes.length} notes logged',
                    style: ReforgeTypography.meta,
                  ),
                ],
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
// Evolution Stepper (Interactive with Tap Feedbacks)
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReforgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            children: List.generate(IdeaStage.values.length, (index) {
              final stage = IdeaStage.values[index];
              final isCompleted = index < currentStageIndex;
              final isCurrent = index == currentStageIndex;
              final isLast = index == IdeaStage.values.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Stage: ${stage.label}'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Column(
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
                              textAlign: TextAlign.center,
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
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 12,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 18),
                        color: index < currentStageIndex
                            ? ReforgeColors.success
                            : ReforgeColors.border,
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
// Content Sections with Empty State Placeholders
// =============================================================================

class _ContentSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? content;
  final String emptyPlaceholder;

  const _ContentSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.emptyPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = content == null || content!.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEmpty
                ? ReforgeColors.border.withValues(alpha: 0.6)
                : ReforgeColors.border,
          ),
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
              isEmpty ? emptyPlaceholder : content!,
              style: ReforgeTypography.body.copyWith(
                color: isEmpty ? ReforgeColors.muted : ReforgeColors.graphite,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
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
          borderRadius: BorderRadius.circular(16),
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
// Sticky Bottom Action Bar (Keeps CTA always reachable)
// =============================================================================

class _StickyBottomActionBar extends ConsumerWidget {
  final Idea idea;
  const _StickyBottomActionBar({required this.idea});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: ReforgeColors.warmSurface,
        border: const Border(top: BorderSide(color: ReforgeColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI Review Button (Commented out as requested, kept intact)
            /*
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.bot, size: 16, color: ReforgeColors.forgeAccent),
                label: const Text('AI Scope Review 🤖', style: TextStyle(color: ReforgeColors.forgeAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ReforgeColors.forgeAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            */

            // Primary CTA: Turn into Project
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ConvertIdeaDialog.show(context, idea);
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
            const SizedBox(height: 10),
            // Secondary actions row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showIdeaEditSheet(context, idea),
                    icon: const Icon(LucideIcons.penLine, size: 16),
                    label: const Text('Edit Idea'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ReforgeColors.graphite,
                      side: const BorderSide(color: ReforgeColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                          .archiveIdea(idea.id);

                      if (!success || !context.mounted) return;

                      ref.read(shellTabIndexProvider.notifier).state = 3;
                      if (context.canPop()) {
                        Navigator.of(context).pop();
                      }
                      context.go('/home');
                    },
                    icon: const Icon(LucideIcons.archive, size: 16),
                    label: const Text('Graveyard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ReforgeColors.graphite,
                      side: const BorderSide(color: ReforgeColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: ReforgeTypography.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
