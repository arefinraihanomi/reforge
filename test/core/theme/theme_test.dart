import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reforge/core/theme/colors.dart';
import 'package:reforge/core/theme/theme.dart';
import 'package:reforge/core/theme/typography.dart';

void main() {
  group('ReforgeTheme & Tokens Verification', () {
    test('ReforgeTheme.lightTheme initializes with expected tokens', () {
      final theme = ReforgeTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(ReforgeColors.warmSurface));
      expect(theme.colorScheme.primary, equals(ReforgeColors.forgeAccent));
      expect(theme.colorScheme.surface, equals(ReforgeColors.cardSurface));
      expect(theme.colorScheme.onSurface, equals(ReforgeColors.graphite));
      expect(theme.colorScheme.error, equals(ReforgeColors.danger));
    });

    test('Typography uses Inter font family and designated weights', () {
      expect(ReforgeTypography.fontFamily, equals('Inter'));
      expect(ReforgeTypography.greeting.fontWeight, equals(FontWeight.w600));
      expect(ReforgeTypography.greeting.fontSize, equals(20));
      expect(ReforgeTypography.sectionTitle.fontSize, equals(18));
      expect(ReforgeTypography.cardTitle.fontSize, equals(16));
      expect(ReforgeTypography.statNumber.fontWeight, equals(FontWeight.w700));
    });

    testWidgets('App renders clean scaffold using ReforgeTheme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ReforgeTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: Text(
                'Reforge Theme Ready',
                style: ReforgeTypography.greeting,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Reforge Theme Ready'), findsOneWidget);
    });
  });
}
