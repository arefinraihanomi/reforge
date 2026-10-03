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
                  loading: () => const _ProjectsSkeletonLoader(),
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
                        return _ProjectHoverCard(project: projects[index]);
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
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: ReforgeColors.elevatedSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.hammer, size: 40, color: ReforgeColors.muted),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Builds',
              style: ReforgeTypography.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Start forging your next project. Turn an idea into a structured build.',
              style: ReforgeTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Consumer(
              builder: (context, ref, _) => FilledButton.icon(
                onPressed: () =>
                    ref.read(shellTabIndexProvider.notifier).selectTab(1),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('New Project'),
                style: FilledButton.styleFrom(
                  backgroundColor: ReforgeColors.forgeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: ReforgeTypography.buttonPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Hover Card
// =============================================================================

class _ProjectHoverCard extends StatefulWidget {
  final Project project;
  const _ProjectHoverCard({required this.project});

  @override
  State<_ProjectHoverCard> createState() => _ProjectHoverCardState();
}

class _ProjectHoverCardState extends State<_ProjectHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: ReforgeColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? ReforgeColors.forgeAccent.withValues(alpha: 0.4)
                : ReforgeColors.border,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: InkWell(
          onTap: () => context.go('/projects/${project.id}'),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
        ),
      ),
    );
  }
}

// =============================================================================
// Skeleton Loader
// =============================================================================

class _ProjectsSkeletonLoader extends StatelessWidget {
  const _ProjectsSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const _ProjectSkeletonCard(),
    );
  }
}

class _ProjectSkeletonCard extends StatefulWidget {
  const _ProjectSkeletonCard();

  @override
  State<_ProjectSkeletonCard> createState() => _ProjectSkeletonCardState();
}

class _ProjectSkeletonCardState extends State<_ProjectSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
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
                  _SkeletonBox(width: 160, height: 16, radius: 6),
                  _SkeletonBox(width: 64, height: 22, radius: 6),
                ],
              ),
              const SizedBox(height: 10),
              _SkeletonBox(width: double.infinity, height: 12, radius: 4),
              const SizedBox(height: 6),
              _SkeletonBox(width: 220, height: 12, radius: 4),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SkeletonBox(width: 100, height: 12, radius: 4),
                  _SkeletonBox(width: 120, height: 12, radius: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ReforgeColors.elevatedSurface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
