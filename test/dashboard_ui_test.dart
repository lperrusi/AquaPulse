/// Dashboard UI Tests
///
/// Tests for the improved dashboard UI, focusing on the new layout and accessibility features.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydration_tracker/screens/dashboard_screen.dart';
import 'package:hydration_tracker/services/ad_service.dart';

void main() {
  group('Dashboard UI Tests', () {
    tearDown(() {
      final adService = AdService.instance;
      adService.debugResetBannerStates();
    });

    testWidgets('renders dashboard with provider scope',
        (WidgetTester tester) async {
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

    testWidgets('does not reserve banner space when banner state is not loaded',
        (WidgetTester tester) async {
      final adService = AdService.instance;
      adService.debugDisableBannerAutoLoad(true);
      adService.debugSetBannerState(
        isBottom: false,
        status: BannerLoadState.failed,
      );
      adService.debugSetBannerState(
        isBottom: true,
        status: BannerLoadState.loading,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('dashboard_banner_top')), findsNothing);
      expect(find.byKey(const Key('dashboard_banner_bottom')), findsNothing);
    });

    testWidgets('custom amount shows validation for out-of-range input',
        (WidgetTester tester) async {
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
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byKey(const Key('open_add_intake_dialog_button')));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(
          find.byKey(const Key('open_custom_amount_dialog_button')));
      await tester
          .tap(find.byKey(const Key('open_custom_amount_dialog_button')));
      await tester.pump(const Duration(milliseconds: 300));

      final fieldFinder = find.byKey(const Key('custom_amount_ml_field'));
      expect(fieldFinder, findsOneWidget);

      await tester.enterText(fieldFinder, '10001');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Water'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Enter a valid amount (1-10000 ml)'), findsOneWidget);
    });

    testWidgets('custom amount field enforces digits only',
        (WidgetTester tester) async {
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
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byKey(const Key('open_add_intake_dialog_button')));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(
          find.byKey(const Key('open_custom_amount_dialog_button')));
      await tester
          .tap(find.byKey(const Key('open_custom_amount_dialog_button')));
      await tester.pump(const Duration(milliseconds: 300));

      final fieldFinder = find.byKey(const Key('custom_amount_ml_field'));
      expect(fieldFinder, findsOneWidget);

      await tester.enterText(fieldFinder, '12a');
      await tester.pump();

      final editableFinder = find.descendant(
        of: fieldFinder,
        matching: find.byType(EditableText),
      );
      final editable = tester.widget<EditableText>(editableFinder);
      expect(editable.controller.text, '12');
    });
  });
}
