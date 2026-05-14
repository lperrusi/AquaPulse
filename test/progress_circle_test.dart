/// Progress circle widget tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydration_tracker/widgets/progress_circle.dart';

void main() {
  group('ProgressCircle', () {
    testWidgets('onTap null does not expose tap target key', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: ProgressCircle(
              current: 100,
              goal: 2000,
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('progress_circle_add_intake_tap')),
        findsNothing,
      );
    });

    testWidgets('onTap invokes callback when tap target is pressed',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: ProgressCircle(
              current: 100,
              goal: 2000,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('progress_circle_add_intake_tap')),
      );
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onTap registers Add water intake semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: ProgressCircle(
              current: 0,
              goal: 2000,
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.byKey(const ValueKey<String>('progress_circle_add_intake_tap')),
      );
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.label, contains('Add water intake'));
    });
  });
}
