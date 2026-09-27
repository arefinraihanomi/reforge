import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../postmortem/presentation/postmortem_notifier.dart';
import '../../projects/models/project.dart';

class GraveyardScreen extends ConsumerWidget {
  const GraveyardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abandonedProjectsAsync = ref.watch(abandonedProjectsProvider);

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Graveyard',
                        style: ReforgeTypography.screenTitle,
                      ),
                      const Text(
                        'Guilt-free memorial of paused & abandoned builds',
                        style: ReforgeTypography.meta,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    onPressed: () => ref.invalidate(abandonedProjectsProvider),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // List of Abandoned Projects
              Expanded(
                child: abandonedProjectsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 36, color: ReforgeColors.danger),
                        const SizedBox(height: 8),
                        const Text('Failed to load Graveyard', style: ReforgeTypography.cardTitle),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(abandonedProjectsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (projects) {
                    if (projects.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return ListView.separated(
                      itemCount: projects.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildGraveyardCard(context, ref, projects[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
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
              child: const Icon(
                LucideIcons.ghost,
                size: 32,
                color: ReforgeColors.subtle,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The Graveyard is Empty',
              style: ReforgeTypography.cardTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'No abandoned projects yet. When a build hits a roadblock or scope creep, abandon it guilt-free to capture post-mortem lessons.',
              style: ReforgeTypography.meta,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraveyardCard(BuildContext context, WidgetRef ref, Project project) {
    final postmortemAsync = ref.watch(projectPostmortemProvider(project.id));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReforgeColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReforgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: ReforgeTypography.cardTitle.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ReforgeColors.dangerBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.abandonReason?.toUpperCase() ?? 'ABANDONED',
                  style: ReforgeTypography.badge.copyWith(
                    color: ReforgeColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (project.abandonedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Archived ${DateFormat.yMMMd().format(project.abandonedAt!)}',
              style: ReforgeTypography.meta,
            ),
          ],

          if (project.abandonNote != null && project.abandonNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${project.abandonNote}"',
              style: ReforgeTypography.quote.copyWith(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: ReforgeColors.border),
          const SizedBox(height: 12),

          // Post-Mortem CTA & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              postmortemAsync.when(
                data: (pm) {
                  final isDone = pm != null;
                  return Row(
                    children: [
                      Icon(
                        isDone ? LucideIcons.checkCircle2 : LucideIcons.helpCircle,
                        size: 16,
                        color: isDone ? ReforgeColors.success : ReforgeColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDone ? 'Post-Mortem Saved' : 'Post-Mortem Pending',
                        style: ReforgeTypography.meta.copyWith(
                          color: isDone ? ReforgeColors.success : ReforgeColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text('Post-Mortem Status N/A', style: ReforgeTypography.meta),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/reforge/${project.id}'),
                    icon: const Icon(LucideIcons.flame, size: 16, color: ReforgeColors.forgeAccent),
                    label: const Text('Reforge V2 🔥'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ReforgeColors.forgeAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: const BorderSide(color: ReforgeColors.forgeAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: ReforgeTypography.buttonPrimary.copyWith(fontSize: 13),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/postmortem/${project.id}'),
                    icon: const Icon(LucideIcons.bookOpen, size: 16),
                    label: const Text('Post-Mortem'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ReforgeColors.deepSlate,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: ReforgeTypography.buttonPrimary.copyWith(fontSize: 13),
                    ),
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
