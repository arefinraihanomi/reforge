import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reforge/main.dart';

void main() {
  testWidgets('ReforgeApp boots and displays initial workshop shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ReforgeApp(),
      ),
    );

    // Verify presence of greeting and status banner
    expect(find.text('Good evening, Arefin'), findsOneWidget);
    expect(find.text('Workshop Active'), findsOneWidget);
    expect(find.text('FOUNDATION ONLINE'), findsOneWidget);
  });
}
