import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/shell_screen.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../models/project.dart';
import 'projects_notifier.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProjectsAsync = ref.watch(activeProjectsProvider);

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
                        'Active Workspaces',
                        style: ReforgeTypography.screenTitle,
                      ),
                      const Text(
                        'Track active builds & MVP boundaries',
                        style: ReforgeTypography.meta,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    onPressed: () => ref.invalidate(projectsListProvider),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Active Projects List
              Expanded(
                child: activeProjectsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle,
                            size: 36, color: ReforgeColors.danger),
                        const SizedBox(height: 8),
                        const Text('Failed to load projects', style: ReforgeTypography.cardTitle),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(projectsListProvider),
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
                        return _buildProjectCard(context, projects[index]);
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
                LucideIcons.hammer,
                size: 32,
                color: ReforgeColors.subtle,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Projects Yet',
              style: ReforgeTypography.cardTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Convert an idea from your Idea Vault into an active build workspace with a tight MVP scope.',
              style: ReforgeTypography.meta,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) => ElevatedButton.icon(
                onPressed: () =>
                    ref.read(shellTabIndexProvider.notifier).selectTab(1),
                icon: const Icon(LucideIcons.lightbulb, size: 18),
                label: const Text('Go to Idea Vault'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ReforgeColors.forgeAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    return InkWell(
      onTap: () => context.go('/projects/${project.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ReforgeColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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
                    color: ReforgeColors.successBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    project.status.toUpperCase(),
                    style: ReforgeTypography.badge.copyWith(
                      color: ReforgeColors.success,
                    ),
                  ),
                ),
              ],
            ),
            if (project.mvpScope != null && project.mvpScope!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Scope: ${project.mvpScope}',
                style: ReforgeTypography.meta.copyWith(
                  color: ReforgeColors.muted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.checkSquare, size: 14, color: ReforgeColors.forgeAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${project.completedTasksCount} / ${project.totalTasksCount} tasks',
                      style: ReforgeTypography.meta.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ReforgeColors.graphite,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Open Workspace',
                      style: ReforgeTypography.meta.copyWith(
                        color: ReforgeColors.forgeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: ReforgeColors.forgeAccent,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
