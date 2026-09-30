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
                  loading: () => const _GraveyardSkeletonLoader(),
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
                        return _GraveyardHoverCard(project: projects[index]);
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
              child: const Icon(LucideIcons.skull, size: 40, color: ReforgeColors.muted),
            ),
            const SizedBox(height: 20),
            const Text(
              'The Graveyard is Empty',
              style: ReforgeTypography.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Projects you abandon or complete get memorialized here.',
              style: ReforgeTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '"Every abandoned build is a lesson forged in silence."',
              style: ReforgeTypography.body.copyWith(
                fontStyle: FontStyle.italic,
                color: ReforgeColors.subtle,
              ),
              textAlign: TextAlign.center,
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

class _GraveyardHoverCard extends ConsumerStatefulWidget {
  final Project project;
  const _GraveyardHoverCard({required this.project});

  @override
  ConsumerState<_GraveyardHoverCard> createState() => _GraveyardHoverCardState();
}

class _GraveyardHoverCardState extends ConsumerState<_GraveyardHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final postmortemAsync = ref.watch(projectPostmortemProvider(project.id));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
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
              : [],
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Post-Mortem Status
                postmortemAsync.when(
                  data: (pm) {
                    final isDone = pm != null;

                    return Row(
                      children: [
                        Icon(
                          isDone
                              ? LucideIcons.checkCircle2
                              : LucideIcons.helpCircle,
                          size: 16,
                          color: isDone
                              ? ReforgeColors.success
                              : ReforgeColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDone
                              ? 'Post-Mortem Saved'
                              : 'Post-Mortem Pending',
                          style: ReforgeTypography.meta.copyWith(
                            color: isDone
                                ? ReforgeColors.success
                                : ReforgeColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },

                  loading: () => const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),

                  error: (_, _) => const Text(
                    'Post-Mortem Status N/A',
                    style: ReforgeTypography.meta,
                  ),
                ),

                const SizedBox(height: 12),

                // Buttons - Left & Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/reforge/${project.id}'),
                      icon: const Icon(
                        LucideIcons.flame,
                        size: 16,
                      ),
                      label: const Text('Reforge V2'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ReforgeColors.forgeAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        side: const BorderSide(
                          color: ReforgeColors.forgeAccent,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle:
                            ReforgeTypography.buttonPrimary.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed: () =>
                          context.go('/postmortem/${project.id}'),
                      icon: const Icon(
                        LucideIcons.bookOpen,
                        size: 16,
                      ),
                      label: const Text('Post-Mortem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ReforgeColors.deepSlate,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle:
                            ReforgeTypography.buttonPrimary.copyWith(
                          fontSize: 13,
                        ),
                      ),
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

// =============================================================================
// Skeleton Loader
// =============================================================================

class _GraveyardSkeletonLoader extends StatelessWidget {
  const _GraveyardSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _GraveyardSkeletonCard(),
    );
  }
}

class _GraveyardSkeletonCard extends StatefulWidget {
  const _GraveyardSkeletonCard();

  @override
  State<_GraveyardSkeletonCard> createState() => _GraveyardSkeletonCardState();
}

class _GraveyardSkeletonCardState extends State<_GraveyardSkeletonCard>
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
                  _SkeletonBox(width: 80, height: 22, radius: 6),
                ],
              ),
              const SizedBox(height: 8),
              _SkeletonBox(width: 120, height: 12, radius: 4),
              const SizedBox(height: 10),
              _SkeletonBox(width: double.infinity, height: 12, radius: 4),
              const SizedBox(height: 6),
              _SkeletonBox(width: 200, height: 12, radius: 4),
              const SizedBox(height: 16),
              const Divider(height: 1, color: ReforgeColors.border),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SkeletonBox(width: 100, height: 32, radius: 8),
                  _SkeletonBox(width: 110, height: 32, radius: 8),
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
