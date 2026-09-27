import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reforge/app/routes.dart';
import 'package:reforge/app/shell_screen.dart';
import 'package:reforge/core/network/supabase_client.dart';
import 'package:reforge/core/theme/theme.dart';

export 'app/shell_screen.dart' show ReforgeShellScreen;

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
class ReforgeApp extends ConsumerWidget {
  const ReforgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Reforge',
      debugShowCheckedModeBanner: false,
      theme: ReforgeTheme.lightTheme,
      routerConfig: router,
    );
  }
}

