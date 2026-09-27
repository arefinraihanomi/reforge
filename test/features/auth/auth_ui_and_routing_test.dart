import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reforge/app/routes.dart';
import 'package:reforge/app/shell_screen.dart';
import 'package:reforge/features/auth/data/auth_repository.dart';
import 'package:reforge/features/auth/presentation/login_screen.dart';
import 'package:reforge/main.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => const Stream<AuthState>.empty());
  });

  group('Protected Routing & Auth Redirect Guard Tests', () {
    testWidgets('Unauthenticated user is redirected to /login', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockAuthRepository.getCurrentSession()).thenReturn(null);
      when(() => mockAuthRepository.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const ReforgeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify user is on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(ReforgeShellScreen), findsNothing);
    });

    testWidgets('Authenticated user proceeds directly to /home', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockUser = MockUser();
      final mockSession = MockSession();
      when(() => mockUser.userMetadata).thenReturn({'display_name': 'Arefin'});
      when(() => mockUser.email).thenReturn('arefin@example.com');
      when(() => mockAuthRepository.getCurrentSession()).thenReturn(mockSession);
      when(() => mockAuthRepository.currentUser).thenReturn(mockUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const ReforgeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify user is on ReforgeShellScreen at /home
      expect(find.byType(ReforgeShellScreen), findsOneWidget);
      expect(find.text('Workshop Active'), findsOneWidget);
      expect(find.text('Good evening, Arefin'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Navigating to signup displays registration form and name field', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockAuthRepository.getCurrentSession()).thenReturn(null);
      when(() => mockAuthRepository.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const ReforgeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign Up link
      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);
      await tester.ensureVisible(signUpButton);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Verify Signup view fields
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Form validation enforces required email and password fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockAuthRepository.getCurrentSession()).thenReturn(null);
      when(() => mockAuthRepository.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const ReforgeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign In with empty fields
      final submitButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });
  });
}
