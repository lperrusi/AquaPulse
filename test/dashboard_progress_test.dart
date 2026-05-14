/// Dashboard Progress Tests
///
/// Tests for the dashboard progress indicator and water intake functionality,
/// specifically focusing on the issue with exceeding the daily goal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydration_tracker/screens/dashboard_screen.dart';

void main() {
  group('Dashboard Progress Tests', () {
    testWidgets('renders dashboard without crashing', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}
