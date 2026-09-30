import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/network/supabase_client.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../features/auth/presentation/profile_notifier.dart';
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
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    if (isDesktop) {
      return Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final isCtrl = HardwareKeyboard.instance.isControlPressed;
            if (isCtrl) {
              final tabKeys = {
                LogicalKeyboardKey.digit1: 0,
                LogicalKeyboardKey.digit2: 1,
                LogicalKeyboardKey.digit3: 2,
                LogicalKeyboardKey.digit4: 3,
                LogicalKeyboardKey.digit5: 4,
              };
              final targetTab = tabKeys[event.logicalKey];
              if (targetTab != null) {
                ref.read(shellTabIndexProvider.notifier).selectTab(targetTab);
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          body: Row(
            children: [
              _DesktopSidebar(
                currentIndex: currentIndex,
                onSelectTab: (index) =>
                    ref.read(shellTabIndexProvider.notifier).selectTab(index),
              ),
              const VerticalDivider(width: 1, thickness: 1, color: ReforgeColors.border),
              Expanded(
                child: _AnimatedTabBody(
                  currentIndex: currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ReforgeColors.deepSlate,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
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
        ),
      ),
    );
  }
}

/// A desktop navigation sidebar widget.
class _DesktopSidebar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectTab;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final profileName = profileAsync.value?.profile.displayName;
    final currentUser = ref.watch(currentUserProvider);
    final displayName = profileName ??
        (currentUser?.userMetadata?['display_name'] as String? ??
            (currentUser?.email != null
                ? currentUser!.email!.split('@').first
                : 'User'));
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    return Container(
      width: 230,
      color: ReforgeColors.warmSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/brand/app_logo.png',
                  height: 38,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    LucideIcons.flame,
                    color: ReforgeColors.forgeAccent,
                    size: 32,
                  ),
                ),
              ),
            ),
            const Divider(color: ReforgeColors.border, height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _SidebarNavItem(
                    icon: LucideIcons.layoutGrid,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => onSelectTab(0),
                  ),
                  _SidebarNavItem(
                    icon: LucideIcons.lightbulb,
                    label: 'Ideas Vault',
                    isSelected: currentIndex == 1,
                    onTap: () => onSelectTab(1),
                  ),
                  _SidebarNavItem(
                    icon: LucideIcons.hammer,
                    label: 'Projects',
                    isSelected: currentIndex == 2,
                    onTap: () => onSelectTab(2),
                  ),
                  _SidebarNavItem(
                    icon: LucideIcons.skull,
                    label: 'Graveyard',
                    isSelected: currentIndex == 3,
                    onTap: () => onSelectTab(3),
                  ),
                  _SidebarNavItem(
                    icon: LucideIcons.bookOpen,
                    label: 'Reflection Vault',
                    isSelected: currentIndex == 4,
                    onTap: () => onSelectTab(4),
                  ),
                ],
              ),
            ),
            const Divider(color: ReforgeColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Avatar circle with initial
                  InkWell(
                    onTap: () => context.push('/profile'),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: ReforgeColors.deepSlate,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ReforgeColors.graphite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Sign-out button
                  Tooltip(
                    message: 'Sign Out',
                    child: InkWell(
                      onTap: () async {
                        await ref.read(authNotifierProvider.notifier).signOut();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          LucideIcons.logOut,
                          size: 16,
                          color: ReforgeColors.muted,
                        ),
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

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? ReforgeColors.deepSlate
        : Colors.transparent;
    final iconColor = isSelected
        ? ReforgeColors.forgeAccent
        : ReforgeColors.muted;
    final textColor = isSelected
        ? Colors.white
        : ReforgeColors.graphite;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                // Left accent bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? ReforgeColors.forgeAccent : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
                // Nav item content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: iconColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    final color = isSelected
        ? ReforgeColors.forgeAccent
        : ReforgeColors.deepSlateMuted;
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

/// State-preserving animated tab body.
/// Uses Stack + Offstage + AnimatedOpacity to fade between tabs
/// while keeping all tab widgets alive (no state loss on switch).
class _AnimatedTabBody extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const _AnimatedTabBody({
    required this.currentIndex,
    required this.children,
  });

  @override
  State<_AnimatedTabBody> createState() => _AnimatedTabBodyState();
}

class _AnimatedTabBodyState extends State<_AnimatedTabBody>
    with TickerProviderStateMixin {
  late int _previousIndex;
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controllers = List.generate(
      widget.children.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 220),
        value: i == widget.currentIndex ? 1.0 : 0.0,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Fade out old tab
      _controllers[oldWidget.currentIndex].reverse();
      // Fade in new tab
      _controllers[widget.currentIndex].forward();
      _previousIndex = widget.currentIndex;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            final opacity = _controllers[i].value;
            return Offstage(
              offstage: opacity == 0.0 && i != widget.currentIndex,
              child: TickerMode(
                enabled: i == widget.currentIndex,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              ),
            );
          },
          child: widget.children[i],
        );
      }),
    );
  }
}

/// Interactive, dynamic Home tab dashboard with desktop/web responsiveness.
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final profileAsync = ref.watch(profileNotifierProvider);
    final profileName = profileAsync.value?.profile.displayName;
    final currentUser = ref.watch(currentUserProvider);
    final displayName = profileName ??
        (currentUser?.userMetadata?['display_name'] as String? ??
            (currentUser?.email != null
                ? currentUser!.email!.split('@').first
                : 'Arefin'));

    final activeProjectsAsync = ref.watch(activeProjectsProvider);
    final ideasStatsAsync = ref.watch(ideasStatsProvider);
    final ideasAsync = ref.watch(ideasListProvider);
    final graveyardAsync = ref.watch(abandonedProjectsProvider);
    final lessonsAsync = ref.watch(allLessonsProvider);

    final sparksCount = ideasStatsAsync.value?.totalSparks ?? ideasAsync.value?.length ?? 0;
    final activeCount = activeProjectsAsync.value?.length ?? 0;
    final graveyardCount = graveyardAsync.value?.length ?? 0;
    final lessonsCount = lessonsAsync.value?.length ?? 0;

    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: ReforgeColors.warmSurface,
      appBar: AppBar(
        title: isDesktop
            ? const Text('Dashboard', style: ReforgeTypography.screenTitle)
            : Row(
                children: [
                  Image.asset(
                    'assets/brand/app_logo.png',
                    height: 28,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('Reforge', style: ReforgeTypography.screenTitle),
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
          // --- Interactive 'A' Avatar Profile Button ---
          Tooltip(
            message: 'Architect Profile',
            child: InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: ReforgeColors.deepSlate,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: ReforgeColors.border),
        ),
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
          ref.invalidate(profileNotifierProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 850;

                    final metricCards = [
                      _MetricCard(
                        label: 'Sparks Captured',
                        count: sparksCount,
                        icon: LucideIcons.lightbulb,
                        iconColor: ReforgeColors.forgeAccent,
                        onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(1),
                      ),
                      _MetricCard(
                        label: 'Active Builds',
                        count: activeCount,
                        icon: LucideIcons.hammer,
                        iconColor: const Color(0xFF3B82F6),
                        onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(2),
                      ),
                      _MetricCard(
                        label: 'Graveyard',
                        count: graveyardCount,
                        icon: LucideIcons.skull,
                        iconColor: ReforgeColors.danger,
                        onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(3),
                      ),
                      _MetricCard(
                        label: 'Key Lessons',
                        count: lessonsCount,
                        icon: LucideIcons.bookOpen,
                        iconColor: const Color(0xFF10B981),
                        onTap: () => ref.read(shellTabIndexProvider.notifier).selectTab(4),
                      ),
                    ];

                    final activeProjectsWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    );

                    final reflectionTakeawayWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    );

                    final recentSparksWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    );

                    return Column(
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
                                  Text('Hi, $displayName', style: ReforgeTypography.greeting),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Keep building. Keep refining.',
                                    style: ReforgeTypography.body,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
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

                        // Overview Metrics Grid (Desktop 4 in a row vs Mobile 2x2)
                        if (isDesktop)
                          Row(
                            children: metricCards
                                .map((card) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: card,
                                      ),
                                    ))
                                .toList(),
                          )
                        else ...[
                          Row(
                            children: [
                              Expanded(child: metricCards[0]),
                              const SizedBox(width: 12),
                              Expanded(child: metricCards[1]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: metricCards[2]),
                              const SizedBox(width: 12),
                              Expanded(child: metricCards[3]),
                            ],
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Dashboard Section Layout (Desktop 2-column vs Mobile stacked)
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    activeProjectsWidget,
                                    const SizedBox(height: 24),
                                    recentSparksWidget,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    reflectionTakeawayWidget,
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          activeProjectsWidget,
                          const SizedBox(height: 24),
                          reflectionTakeawayWidget,
                          const SizedBox(height: 24),
                          recentSparksWidget,
                        ],

                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
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
