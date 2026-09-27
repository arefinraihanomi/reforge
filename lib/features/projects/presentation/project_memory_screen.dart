import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/project_decision.dart';
import 'log_decision_dialog.dart';
import 'projects_notifier.dart';

class ProjectMemoryScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectMemoryScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectMemoryScreen> createState() => _ProjectMemoryScreenState();
}

class _ProjectMemoryScreenState extends ConsumerState<ProjectMemoryScreen> {
  String _typeFilter = 'all'; // 'all', 'decision', 'blocker', 'note'

  @override
  Widget build(BuildContext context) {
    final decisionsAsync = ref.watch(projectDecisionsProvider(widget.projectId));
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));

    final projectTitle = projectAsync.when(
      data: (p) => p.title,
      loading: () => 'Project Workspace',
      error: (_, __) => 'Project Workspace',
    );

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
              context.go('/projects/${widget.projectId}');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Memory Timeline',
              style: ReforgeTypography.screenTitle.copyWith(fontSize: 18),
            ),
            Text(
              projectTitle,
              style: ReforgeTypography.meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(projectDecisionsProvider(widget.projectId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => LogDecisionDialog.show(context, projectId: widget.projectId),
        backgroundColor: ReforgeColors.deepSlate,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Log Decision'),
      ),
      body: Column(
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Memory'),
                const SizedBox(width: 8),
                _buildFilterChip('decision', 'Decisions'),
                const SizedBox(width: 8),
                _buildFilterChip('blocker', 'Blockers'),
                const SizedBox(width: 8),
                _buildFilterChip('note', 'Notes'),
              ],
            ),
          ),

          // Timeline Body
          Expanded(
            child: decisionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 36, color: ReforgeColors.danger),
                      const SizedBox(height: 8),
                      const Text('Failed to load memory timeline', style: ReforgeTypography.cardTitle),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(projectDecisionsProvider(widget.projectId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (decisions) {
                final filtered = decisions.where((d) {
                  if (_typeFilter == 'all') return true;
                  return d.entryType == _typeFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineItem(context, filtered[index], index == filtered.length - 1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _typeFilter == value;
    return InkWell(
      onTap: () => setState(() => _typeFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ReforgeColors.deepSlate : ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ReforgeColors.deepSlate : ReforgeColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : ReforgeColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ReforgeColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: ReforgeColors.warmSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bookmarkPlus, size: 32, color: ReforgeColors.subtle),
            ),
            const SizedBox(height: 16),
            Text(
              'No Memory Logs Yet',
              style: ReforgeTypography.cardTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log decisions, technical blockers, and architectural choices to preserve project execution context.',
              style: ReforgeTypography.meta,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => LogDecisionDialog.show(context, projectId: widget.projectId),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Log First Decision'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ReforgeColors.deepSlate,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, ProjectDecision item, bool isLast) {
    Color typeColor;
    IconData typeIcon;
    String badgeLabel;

    if (item.isBlocker) {
      typeColor = ReforgeColors.danger;
      typeIcon = LucideIcons.alertTriangle;
      badgeLabel = 'BLOCKER';
    } else if (item.isDecision) {
      typeColor = ReforgeColors.success;
      typeIcon = LucideIcons.checkCircle2;
      badgeLabel = 'DECISION';
    } else {
      typeColor = ReforgeColors.category;
      typeIcon = LucideIcons.fileText;
      badgeLabel = 'NOTE';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Node & Bar
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: typeColor, width: 1.5),
                ),
                child: Icon(typeIcon, size: 14, color: typeColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: ReforgeColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ReforgeColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ReforgeColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeLabel,
                          style: ReforgeTypography.badge.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item.createdAt != null)
                        Text(
                          DateFormat.yMMMd().add_jm().format(item.createdAt!),
                          style: ReforgeTypography.meta,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: ReforgeTypography.cardTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.decision,
                    style: ReforgeTypography.body.copyWith(
                      color: ReforgeColors.graphite,
                      height: 1.45,
                    ),
                  ),
                  if (item.rationale != null && item.rationale!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ReforgeColors.warmSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ReforgeColors.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.lightbulb, size: 14, color: ReforgeColors.forgeAccent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rationale: ${item.rationale}',
                              style: ReforgeTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
