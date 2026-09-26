import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reforge/core/network/supabase_client.dart';
import 'package:reforge/core/theme/colors.dart';
import 'package:reforge/core/theme/theme.dart';
import 'package:reforge/core/theme/typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase & environment configuration with safe fallback
  await SupabaseBootstrap.initialize();

  runApp(
    const ProviderScope(
      child: ReforgeApp(),
    ),
  );
}

/// The root application widget for Reforge.
class ReforgeApp extends StatelessWidget {
  const ReforgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reforge',
      debugShowCheckedModeBanner: false,
      theme: ReforgeTheme.lightTheme,
      home: const ReforgeShellScreen(),
    );
  }
}

/// Temporary foundation shell screen displayed before Phase A2 routing is wired up.
class ReforgeShellScreen extends StatelessWidget {
  const ReforgeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: ReforgeColors.deepSlate,
              child: const Text(
                'A',
                style: TextStyle(
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good evening, Arefin', style: ReforgeTypography.greeting),
                        SizedBox(height: 4),
                        Text(
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
