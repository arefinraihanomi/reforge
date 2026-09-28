import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/network/supabase_client.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../features/graveyard/presentation/graveyard_screen.dart';
import '../features/ideas/presentation/idea_vault_screen.dart';
import '../features/ideas/presentation/ideas_notifier.dart';
import '../features/postmortem/presentation/postmortem_notifier.dart';
import '../features/postmortem/presentation/reflect_screen.dart';
import '../features/projects/presentation/projects_list_screen.dart';
import '../features/projects/presentation/projects_notifier.dart';

/// Notifier tracking the current bottom navigation tab index.
class ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) => state = index;
}

final shellTabIndexProvider =
    NotifierProvider<ShellTabNotifier, int>(ShellTabNotifier.new);

/// Main shell screen displayed for authenticated users at `/home`.
class ReforgeShellScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const ReforgeShellScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<ReforgeShellScreen> createState() => _ReforgeShellScreenState();
}

class _ReforgeShellScreenState extends ConsumerState<ReforgeShellScreen> {
  static const _screens = <Widget>[
    _HomeTab(),
    IdeaVaultScreen(),
    ProjectsListScreen(),
    GraveyardScreen(),
    ReflectScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(shellTabIndexProvider.notifier).selectTab(widget.initialTab);
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReforgeShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(shellTabIndexProvider.notifier).selectTab(widget.initialTab);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(shellTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ReforgeColors.deepSlate,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: LucideIcons.layoutGrid,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(0),
                ),
                _NavItem(
                  icon: LucideIcons.lightbulb,
                  label: 'Ideas',
                  isSelected: currentIndex == 1,
                  onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(1),
                ),
                _NavItem(
                  icon: LucideIcons.hammer,
                  label: 'Projects',
                  isSelected: currentIndex == 2,
                  onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(2),
                ),
                _NavItem(
                  icon: LucideIcons.skull,
                  label: 'Graveyard',
                  isSelected: currentIndex == 3,
                  onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(3),
                ),
                _NavItem(
                  icon: LucideIcons.bookOpen,
                  label: 'Reflect',
                  isSelected: currentIndex == 4,
                  onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single bottom navigation item.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? ReforgeColors.forgeAccent : ReforgeColors.deepSlateMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive, dynamic Home tab dashboard.
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.userMetadata?['display_name'] as String? ??
        (currentUser?.email != null ? currentUser!.email!.split('@').first : 'Arefin');

    final activeProjectsAsync = ref.watch(activeProjectsProvider);
    final ideasStatsAsync = ref.watch(ideasStatsProvider);
    final ideasAsync = ref.watch(ideasListProvider);
    final graveyardAsync = ref.watch(abandonedProjectsProvider);
    final lessonsAsync = ref.watch(allLessonsProvider);

    final sparksCount = ideasStatsAsync.value?.totalSparks ?? ideasAsync.value?.length ?? 0;
    final activeCount = activeProjectsAsync.value?.length ?? 0;
    final graveyardCount = graveyardAsync.value?.length ?? 0;
    final lessonsCount = lessonsAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/brand/app_logo.png',
              height: 28,
              errorBuilder: (context, error, stackTrace) => const Text(
                'Reforge',
                style: ReforgeTypography.screenTitle,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reflection Vault',
            icon: const Icon(LucideIcons.bookOpen, size: 20),
            onPressed: () {
              ref.read(shellTabIndexProvider.notifier).selectTab(4);
            },
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(LucideIcons.logOut, size: 20),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: ReforgeColors.deepSlate,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'R',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: ReforgeColors.forgeAccent,
        onRefresh: () async {
          ref.invalidate(activeProjectsProvider);
          ref.invalidate(projectsListProvider);
          ref.invalidate(ideasStatsProvider);
          ref.invalidate(ideasListProvider);
          ref.invalidate(abandonedProjectsProvider);
          ref.invalidate(allLessonsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Greeting + Workshop Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good evening, $displayName', style: ReforgeTypography.greeting),
                        const SizedBox(height: 2),
                        const Text(
                          'Keep building. Keep refining.',
                          style: ReforgeTypography.body,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ReforgeColors.successBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ReforgeColors.successBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 8, color: ReforgeColors.success),
                        const SizedBox(width: 6),
                        Text(
                          SupabaseBootstrap.isInitialized ? 'Workshop Active' : 'Workshop Active (Local)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ReforgeColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Overview Metrics Grid (4 Tappable Cards)
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Sparks Captured',
                      count: sparksCount,
                      icon: LucideIcons.lightbulb,
                      iconColor: ReforgeColors.forgeAccent,
                      onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Active Builds',
                      count: activeCount,
                      icon: LucideIcons.hammer,
                      iconColor: const Color(0xFF3B82F6),
                      onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Graveyard',
                      count: graveyardCount,
                      icon: LucideIcons.skull,
                      iconColor: ReforgeColors.danger,
                      onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Key Lessons',
                      count: lessonsCount,
                      icon: LucideIcons.bookOpen,
                      iconColor: const Color(0xFF10B981),
                      onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Active Projects / Workspaces Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Workspaces', style: ReforgeTypography.sectionTitle),
                  TextButton(
                    onPressed: () => ref.read(shellTabIndexProvider.notifier).selectTab(2),
                    child: const Text('View All →', style: ReforgeTypography.buttonSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              activeProjectsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: ReforgeColors.forgeAccent),
                  ),
                ),
                error: (_, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ReforgeColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ReforgeColors.border),
                  ),
                  child: const Text('Could not load active builds.', style: ReforgeTypography.meta),
                ),
                data: (projects) {
                  if (projects.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ReforgeColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ReforgeColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No active builds in flight.',
                            style: ReforgeTypography.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pick an idea from your Idea Vault to forge into a scoped build workspace.',
                            style: ReforgeTypography.meta,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => ref.read(shellTabIndexProvider.notifier).selectTab(1),
                            icon: const Icon(LucideIcons.lightbulb, size: 16),
                            label: const Text('Open Idea Vault'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ReforgeColors.forgeAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: projects.take(2).map((project) {
                      final tasks = project.tasks;
                      final completedCount = tasks.where((t) => t.isCompleted).length;
                      final totalCount = tasks.length;
                      final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ReforgeColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ReforgeColors.border),
                        ),
                        child: InkWell(
                          onTap: () => context.go('/projects/${project.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      project.title,
                                      style: ReforgeTypography.cardTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: ReforgeColors.forgeAccentBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'BUILDING',
                                      style: TextStyle(
                                        color: ReforgeColors.forgeAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (project.mvpScope != null && project.mvpScope!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  project.mvpScope!,
                                  style: ReforgeTypography.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor: ReforgeColors.warmSurface,
                                        color: ReforgeColors.forgeAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$completedCount/$totalCount tasks',
                                    style: ReforgeTypography.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Reflection Vault Spotlight
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reflection Takeaway', style: ReforgeTypography.sectionTitle),
                  TextButton(
                    onPressed: () => ref.read(shellTabIndexProvider.notifier).selectTab(4),
                    child: const Text('Vault →', style: ReforgeTypography.buttonSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              lessonsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (lessons) {
                  if (lessons.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ReforgeColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ReforgeColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No lessons recorded yet.', style: ReforgeTypography.cardTitle),
                          const SizedBox(height: 4),
                          const Text(
                            'Capture engineering guidelines from builds to avoid repeating past mistakes.',
                            style: ReforgeTypography.meta,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => ref.read(shellTabIndexProvider.notifier).selectTab(4),
                            icon: const Icon(LucideIcons.bookOpen, size: 16),
                            label: const Text('Open Reflection Vault'),
                          ),
                        ],
                      ),
                    );
                  }

                  final latest = lessons.first;
                  return InkWell(
                    onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(4),
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ReforgeColors.forgeAccentBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  latest.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: ReforgeColors.forgeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (latest.createdAt != null)
                                Text(
                                  DateFormat.yMMMd().format(latest.createdAt!),
                                  style: ReforgeTypography.caption,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.lightbulb, size: 18, color: ReforgeColors.forgeAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  latest.lesson,
                                  style: ReforgeTypography.body.copyWith(
                                    color: ReforgeColors.deepSlate,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Recent Sparks (Ideas Vault Preview)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Sparks', style: ReforgeTypography.sectionTitle),
                  TextButton(
                    onPressed: () => ref.read(shellTabIndexProvider.notifier).selectTab(1),
                    child: const Text('Vault →', style: ReforgeTypography.buttonSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ideasAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (ideas) {
                  if (ideas.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ReforgeColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ReforgeColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Ideas Vault is empty.', style: ReforgeTypography.cardTitle),
                          const SizedBox(height: 4),
                          const Text(
                            'Capture initial thoughts, technical spikes, and project sparks.',
                            style: ReforgeTypography.meta,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => ref.read(shellTabIndexProvider.notifier).selectTab(1),
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Capture Spark'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ReforgeColors.deepSlate,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: ideas.take(2).map((idea) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ReforgeColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ReforgeColors.border),
                        ),
                        child: InkWell(
                          onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(1),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ReforgeColors.forgeAccentBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.lightbulb,
                                  size: 16,
                                  color: ReforgeColors.forgeAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      idea.title,
                                      style: ReforgeTypography.cardTitle.copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (idea.hypothesis != null && idea.hypothesis!.isNotEmpty)
                                      Text(
                                        idea.hypothesis!,
                                        style: ReforgeTypography.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight, size: 16, color: ReforgeColors.muted),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable overview metric summary card.
class _MetricCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _MetricCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                Text(
                  '$count',
                  style: ReforgeTypography.statNumber.copyWith(fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(label, style: ReforgeTypography.statLabel),
          ],
        ),
      ),
    );
  }
}
