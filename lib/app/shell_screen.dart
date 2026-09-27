import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/network/supabase_client.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../features/auth/presentation/auth_notifier.dart';

/// Main shell screen displayed for authenticated users at `/home`.
class ReforgeShellScreen extends ConsumerWidget {
  const ReforgeShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.userMetadata?['display_name'] as String? ??
        (currentUser?.email != null ? currentUser!.email!.split('@').first : 'Arefin');

    return Scaffold(
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
                        Text('Good evening, $displayName', style: ReforgeTypography.greeting),
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
