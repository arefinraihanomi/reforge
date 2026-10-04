import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reforge/app/shell_screen.dart';

void main() {
  testWidgets('Analytics stays within a narrow Android viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectedTab = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingNavigationBar(
            currentIndex: selectedTab,
            onSelectTab: (index) => selectedTab = index,
          ),
        ),
      ),
    );

    final analyticsLabel = find.text('Analytics');
    expect(analyticsLabel, findsOneWidget);
    expect(tester.getRect(analyticsLabel).right, lessThanOrEqualTo(320));

    await tester.tap(analyticsLabel);
    expect(selectedTab, 5);
  });
}
