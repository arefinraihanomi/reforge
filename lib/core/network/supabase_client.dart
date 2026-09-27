import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Riverpod provider exposing the initialized [SupabaseClient] instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Riverpod provider exposing the currently authenticated [User] or null.
final currentUserProvider = Provider<User?>((ref) {
  if (!SupabaseBootstrap.isInitialized) return null;
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
});

/// Riverpod provider streaming the current [AuthState].
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  if (!SupabaseBootstrap.isInitialized) {
    return const Stream<AuthState>.empty();
  }
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Bootstraps Supabase and local environment configuration.
///
/// Implements resilient error fallback: if `.env` or credentials are missing or
/// placeholders, the app boots safely into offline/demo mode without unhandled exceptions.
abstract final class SupabaseBootstrap {
  static bool _isInitialized = false;

  /// Whether Supabase client was successfully initialized.
  static bool get isInitialized => _isInitialized;

  /// Initializes the local environment and Supabase instance.
  static Future<void> initialize() async {
    // 1. Attempt loading environment file
    try {
      await dotenv.load(fileName: 'assets/.env');
    } catch (_) {
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        debugPrint('[SupabaseBootstrap] Notice: environment file could not be loaded: $e');
      }
    }

    final url = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY');

    // 2. Validate credentials
    final isPlaceholder = _isPlaceholder(url) || _isPlaceholder(anonKey);

    if (isPlaceholder) {
      debugPrint(
        '[SupabaseBootstrap] Running in offline / unconfigured mode. '
        'Provide valid SUPABASE_URL and SUPABASE_ANON_KEY in assets/.env to connect to live backend.',
      );
      _isInitialized = false;
      return;
    }

    // 3. Initialize Supabase
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
      debugPrint('[SupabaseBootstrap] Supabase initialized successfully.');
    } catch (error, stackTrace) {
      debugPrint('[SupabaseBootstrap] Supabase.initialize caught error: $error\n$stackTrace');
      _isInitialized = false;
      // Do not rethrow so app boots safely into shell
    }
  }

  static bool _isPlaceholder(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized.contains('placeholder') ||
        normalized.startsWith('your_') ||
        normalized == 'changeme' ||
        normalized == 'change_me';
  }
}
