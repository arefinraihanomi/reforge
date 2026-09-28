import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reforge/features/auth/data/auth_repository.dart';
import 'package:reforge/features/auth/presentation/auth_notifier.dart';
import 'package:reforge/main.dart';

// ---------------------------------------------------------------------------
// Mocks & Fakes
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}

/// AuthNotifier that bypasses SupabaseBootstrap.isInitialized so integration
/// tests can drive the full auth UI without a live Supabase connection.
class FakeAuthNotifier extends AuthNotifier {
  final AuthRepository repository;
  FakeAuthNotifier(this.repository);

  @override
  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await repository.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Account created successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await repository.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// ---------------------------------------------------------------------------
// Integration Test Lifecycle Suite
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Reforge Full Lifecycle Integration Test', () {
    late MockAuthRepository mockRepo;
    late MockUser mockUser;
    late MockSession mockSession;
    late MockAuthResponse mockAuthResponse;

    setUpAll(() {
      registerFallbackValue(OAuthProvider.google);
    });

    setUp(() {
      mockRepo = MockAuthRepository();
      mockUser = MockUser();
      mockSession = MockSession();
      mockAuthResponse = MockAuthResponse();

      // Default: unauthenticated
      when(() => mockRepo.authStateChanges)
          .thenAnswer((_) => const Stream<AuthState>.empty());
      when(() => mockRepo.getCurrentSession()).thenReturn(null);
      when(() => mockRepo.currentUser).thenReturn(null);
    });

    /// Helper to pump the app with overrides.
    Future<void> pumpApp(
      WidgetTester tester, {
      FakeAuthNotifier? fakeNotifier,
    }) async {
      final notifier = fakeNotifier ?? FakeAuthNotifier(mockRepo);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(() => notifier),
          ],
          child: const ReforgeApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    // -----------------------------------------------------------------------
    // Step 1: Unauthenticated → lands on /login
    // -----------------------------------------------------------------------
    testWidgets('Step 1 — Unauthenticated user lands on login screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(tester);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(ReforgeShellScreen), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Step 2: Signup → registration form visible
    // -----------------------------------------------------------------------
    testWidgets('Step 2 — Navigate to Signup shows registration form', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => mockAuthResponse);
      when(() => mockAuthResponse.session).thenReturn(null);

      await pumpApp(tester);

      // Navigate to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Step 3: Form validation on login
    // -----------------------------------------------------------------------
    testWidgets('Step 3 — Login form enforces email and password validation', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(tester);

      // Tap Sign In without filling in fields
      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Step 4: Authenticated user → lands on shell (Home)
    // -----------------------------------------------------------------------
    testWidgets('Step 4 — Authenticated user lands on Home shell', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockUser.userMetadata).thenReturn({'display_name': 'Arefin'});
      when(() => mockUser.email).thenReturn('arefin@example.com');
      when(() => mockRepo.getCurrentSession()).thenReturn(mockSession);
      when(() => mockRepo.currentUser).thenReturn(mockUser);

      await pumpApp(tester);

      expect(find.byType(ReforgeShellScreen), findsOneWidget);
      expect(find.text('Workshop Active'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Step 5: Navigation tabs are present on shell
    // -----------------------------------------------------------------------
    testWidgets('Step 5 — Bottom navigation tabs are present', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockUser.userMetadata).thenReturn({'display_name': 'Reforger'});
      when(() => mockUser.email).thenReturn('forge@example.com');
      when(() => mockRepo.getCurrentSession()).thenReturn(mockSession);
      when(() => mockRepo.currentUser).thenReturn(mockUser);

      await pumpApp(tester);

      // All 5 bottom nav tabs should be visible
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Ideas'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Graveyard'), findsOneWidget);
      expect(find.text('Reflect'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Helper mock for AuthResponse
// ---------------------------------------------------------------------------

class MockAuthResponse extends Mock implements AuthResponse {}
