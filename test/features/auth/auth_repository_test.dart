import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reforge/core/errors/failures.dart';
import 'package:reforge/core/network/supabase_client.dart';
import 'package:reforge/features/auth/data/auth_repository.dart';
import 'package:reforge/features/auth/models/user_profile.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}
class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(OAuthProvider.google);
  });

  group('UserProfile Model Tests', () {
    final now = DateTime.parse('2026-09-27T10:00:00.000Z');

    test('creates UserProfile from json correctly', () {
      final json = {
        'id': 'user-123',
        'display_name': 'Test User',
        'avatar_url': 'https://example.com/avatar.png',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.displayName, 'Test User');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.createdAt, now);
      expect(profile.updatedAt, now);
    });

    test('converts UserProfile to json correctly', () {
      final profile = UserProfile(
        id: 'user-123',
        displayName: 'Test User',
        avatarUrl: 'https://example.com/avatar.png',
        createdAt: now,
        updatedAt: now,
      );

      final json = profile.toJson();

      expect(json['id'], 'user-123');
      expect(json['display_name'], 'Test User');
      expect(json['avatar_url'], 'https://example.com/avatar.png');
      expect(json['created_at'], now.toIso8601String());
      expect(json['updated_at'], now.toIso8601String());
    });

    test('copyWith updates specified fields', () {
      final profile = UserProfile(
        id: 'user-123',
        displayName: 'Old Name',
        createdAt: now,
      );

      final updated = profile.copyWith(displayName: 'New Name');

      expect(updated.id, 'user-123');
      expect(updated.displayName, 'New Name');
      expect(updated.createdAt, now);
    });

    test('value equality holds for identical properties', () {
      final p1 = UserProfile(id: '1', displayName: 'Reforger', createdAt: now);
      final p2 = UserProfile(id: '1', displayName: 'Reforger', createdAt: now);

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });

  group('SupabaseAuthRepository Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late SupabaseAuthRepository repository;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
      repository = SupabaseAuthRepository(client: mockSupabaseClient);
    });

    group('Auth State & Session Emissions', () {
      test('authStateChanges emits stream of AuthState events', () async {
        final controller = StreamController<AuthState>();
        when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

        final states = <AuthState>[];
        final subscription = repository.authStateChanges.listen(states.add);

        final mockSession = MockSession();
        controller.add(AuthState(AuthChangeEvent.signedIn, mockSession));
        controller.add(const AuthState(AuthChangeEvent.signedOut, null));

        await pumpEventQueue();

        expect(states.length, 2);
        expect(states[0].event, AuthChangeEvent.signedIn);
        expect(states[0].session, mockSession);
        expect(states[1].event, AuthChangeEvent.signedOut);
        expect(states[1].session, isNull);

        await subscription.cancel();
        await controller.close();
      });

      test('currentUser delegates to client.auth.currentUser', () {
        final mockUser = MockUser();
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        final user = repository.currentUser;

        expect(user, equals(mockUser));
        verify(() => mockAuth.currentUser).called(1);
      });

      test('getCurrentSession delegates to client.auth.currentSession', () {
        final mockSession = MockSession();
        when(() => mockAuth.currentSession).thenReturn(mockSession);

        final session = repository.getCurrentSession();

        expect(session, equals(mockSession));
        verify(() => mockAuth.currentSession).called(1);
      });
    });

    group('signUp', () {
      test('returns AuthResponse on successful registration', () async {
        final mockResponse = MockAuthResponse();
        when(
          () => mockAuth.signUp(
            email: 'test@example.com',
            password: 'securePassword123',
            data: {'display_name': 'Arefin'},
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.signUp(
          email: 'test@example.com',
          password: 'securePassword123',
          displayName: 'Arefin',
        );

        expect(result, equals(mockResponse));
        verify(
          () => mockAuth.signUp(
            email: 'test@example.com',
            password: 'securePassword123',
            data: {'display_name': 'Arefin'},
          ),
        ).called(1);
      });

      test('trims whitespace and ignores empty displayName', () async {
        final mockResponse = MockAuthResponse();
        when(
          () => mockAuth.signUp(
            email: 'test@example.com',
            password: 'securePassword123',
            data: null,
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.signUp(
          email: '  test@example.com  ',
          password: 'securePassword123',
          displayName: '   ',
        );

        expect(result, equals(mockResponse));
      });

      test('catches AuthException and rethrows as typed AuthFailure', () async {
        when(
          () => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          const AuthException('User already registered', statusCode: '400'),
        );

        expect(
          () => repository.signUp(
            email: 'duplicate@example.com',
            password: 'password',
          ),
          throwsA(
            isA<AuthFailure>()
                .having((f) => f.message, 'message', 'User already registered')
                .having((f) => f.code, 'code', '400'),
          ),
        );
      });
    });

    group('signIn', () {
      test('returns AuthResponse on valid credentials', () async {
        final mockResponse = MockAuthResponse();
        when(
          () => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'correctPassword',
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.signIn(
          email: 'test@example.com',
          password: 'correctPassword',
        );

        expect(result, equals(mockResponse));
        verify(
          () => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'correctPassword',
          ),
        ).called(1);
      });

      test('catches invalid credentials and rethrows AuthFailure', () async {
        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          const AuthException('Invalid login credentials', statusCode: '400'),
        );

        expect(
          () => repository.signIn(
            email: 'wrong@example.com',
            password: 'badPassword',
          ),
          throwsA(
            isA<AuthFailure>()
                .having((f) => f.message, 'message', 'Invalid login credentials')
                .having((f) => f.code, 'code', '400'),
          ),
        );
      });
    });

    group('signOut', () {
      test('calls client.auth.signOut successfully', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async => {});

        await expectLater(repository.signOut(), completes);
        verify(() => mockAuth.signOut()).called(1);
      });

      test('catches error and throws AppFailure', () async {
        when(() => mockAuth.signOut()).thenThrow(
          const AuthException('Sign out failed', statusCode: '500'),
        );

        expect(
          () => repository.signOut(),
          throwsA(isA<AuthFailure>()),
        );
      });
    });

    group('signInWithGoogle', () {
      test('falls back to OAuth when native google sign in is unconfigured (dotenv unavailable)', () async {
        // This test verifies that when dotenv throws (no env file in test environment),
        // the repository catches the error and attempts the OAuth fallback path via
        // getOAuthSignInUrl. We mock getOAuthSignInUrl to confirm it is called.
        TestWidgetsFlutterBinding.ensureInitialized();

        when(
          () => mockAuth.getOAuthSignInUrl(
            provider: any(named: 'provider'),
            redirectTo: any(named: 'redirectTo'),
            scopes: any(named: 'scopes'),
            queryParams: any(named: 'queryParams'),
          ),
        ).thenAnswer((_) async => OAuthResponse(
          provider: OAuthProvider.google,
          url: 'https://accounts.google.com/oauth',
        ));

        // signInWithGoogle catches dotenv error -> calls signInWithOAuth ->
        // signInWithOAuth calls getOAuthSignInUrl then launches URL.
        // In test environment the URL launch may fail; we only assert the
        // OAuth code path was reached (getOAuthSignInUrl was called).
        try {
          await repository.signInWithGoogle();
        } catch (_) {
          // URL launch may throw in headless test - acceptable
        }

        verify(
          () => mockAuth.getOAuthSignInUrl(
            provider: any(named: 'provider'),
            redirectTo: any(named: 'redirectTo'),
            scopes: any(named: 'scopes'),
            queryParams: any(named: 'queryParams'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('Riverpod Provider', () {
      test('authRepositoryProvider resolves SupabaseAuthRepository', () {
        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
          ],
        );

        addTearDown(container.dispose);

        final repo = container.read(authRepositoryProvider);
        expect(repo, isA<SupabaseAuthRepository>());
      });
    });
  });
}
