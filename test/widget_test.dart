import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reforge/features/auth/data/auth_repository.dart';
import 'package:reforge/main.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}

void main() {
  testWidgets('ReforgeApp boots and displays initial workshop shell when authenticated', (WidgetTester tester) async {
    final mockAuth = MockAuthRepository();
    final mockUser = MockUser();
    final mockSession = MockSession();

    when(() => mockUser.userMetadata).thenReturn({'display_name': 'Arefin'});
    when(() => mockUser.email).thenReturn('arefin@example.com');
    when(() => mockAuth.getCurrentSession()).thenReturn(mockSession);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockAuth.authStateChanges).thenAnswer((_) => const Stream<AuthState>.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
        child: const ReforgeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of greeting and status banner
    expect(find.text('Good evening, Arefin'), findsOneWidget);
    expect(find.text('Workshop Active'), findsOneWidget);
    expect(find.text('FOUNDATION ONLINE'), findsOneWidget);
  });
}
