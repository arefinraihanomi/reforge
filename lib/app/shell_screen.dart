import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/network/supabase_client.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../features/graveyard/presentation/graveyard_screen.dart';
import '../features/ideas/presentation/idea_vault_screen.dart';
import '../features/postmortem/presentation/reflect_screen.dart';
import '../features/projects/presentation/projects_list_screen.dart';

/// Tracks the current bottom navigation tab index.
class ShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;

  @override
  set state(int value) => super.state = value;
}

final shellTabIndexProvider =
    NotifierProvider<ShellTabIndexNotifier, int>(ShellTabIndexNotifier.new);

/// Main shell screen displayed for authenticated users at `/home`.
class ReforgeShellScreen extends ConsumerWidget {
  const ReforgeShellScreen({super.key});

  static const _screens = <Widget>[
    _HomeTab(),
    IdeaVaultScreen(),
    ProjectsListScreen(),
    GraveyardScreen(),
    ReflectScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onTap: () => ref.read(shellTabIndexProvider.notifier).state = 0,
                ),
                _NavItem(
                  icon: LucideIcons.lightbulb,
                  label: 'Ideas',
                  isSelected: currentIndex == 1,
                  onTap: () => ref.read(shellTabIndexProvider.notifier).state = 1,
                ),
                _NavItem(
                  icon: LucideIcons.hammer,
                  label: 'Projects',
                  isSelected: currentIndex == 2,
                  onTap: () => ref.read(shellTabIndexProvider.notifier).state = 2,
                ),
                _NavItem(
                  icon: LucideIcons.skull,
                  label: 'Graveyard',
                  isSelected: currentIndex == 3,
                  onTap: () => ref.read(shellTabIndexProvider.notifier).state = 3,
                ),
                _NavItem(
                  icon: LucideIcons.bookOpen,
                  label: 'Reflect',
                  isSelected: currentIndex == 4,
                  onTap: () => ref.read(shellTabIndexProvider.notifier).state = 4,
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
  final bool badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge = false,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badge)
                  Positioned(
                    top: -3,
                    right: -6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ReforgeColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
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

/// Home tab content (previously the full shell body).
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.userMetadata?['display_name'] as String? ??
        (currentUser?.email != null ? currentUser!.email!.split('@').first : 'Arefin');

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
            tooltip: 'Search',
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: () {},
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, $displayName', style: ReforgeTypography.greeting),
                        const SizedBox(height: 4),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: ReforgeColors.success),
                        SizedBox(width: 6),
                        Text(
                          'Workshop Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ReforgeColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: ReforgeColors.forgeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'FOUNDATION ONLINE',
                            style: ReforgeTypography.overline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Phase A1: Foundation & Core Infrastructure is ready.',
                        style: ReforgeTypography.cardTitle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        SupabaseBootstrap.isInitialized
                            ? 'Supabase backend connected.'
                            : 'Running with local fallback tokens. Supabase credentials ready in .env.',
                        style: ReforgeTypography.body,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
