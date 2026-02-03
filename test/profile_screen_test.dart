/// Profile Screen Tests
///
/// Tests for the profile screen, focusing on gender and activity level selection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydration_tracker/screens/profile_screen.dart';
import 'package:hydration_tracker/providers/app_providers.dart';
import 'package:hydration_tracker/models/user.dart';
import 'package:hydration_tracker/services/database_service.dart';
import 'package:hydration_tracker/services/firebase_service.dart';
import 'package:mockito/mockito.dart';
import 'test_helpers.dart';
import 'test_helpers.mocks.dart';

void main() {
  group('Profile Screen Tests', () {
    late ProviderContainer container;
    late MockDatabaseService mockDb;
    late MockFirebaseService mockFirebase;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();

      mockDb = TestHelpers.createMockDatabaseService();
      mockFirebase = TestHelpers.createMockFirebaseService();
      when(mockFirebase.currentUser).thenReturn(null);
      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
          firebaseServiceProvider.overrideWithValue(mockFirebase),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should allow selecting a gender', (WidgetTester tester) async {
      // Create a test user
      final testUser = User(
        id: 'test_user',
        email: 'test@example.com',
        name: 'Test User',
        age: 30,
        weight: 70.0,
        gender: null, // Start with no gender selected
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set up the mock to return the test user immediately
      when(mockDb.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockDb.updateUser(any)).thenAnswer((_) async {});
      when(mockDb.getAllWaterIntakesForUser(any)).thenAnswer((_) async => []);
      when(mockDb.getWaterIntakeForDateAndUser(any, any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      // Pump multiple times to allow async operations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the profile screen is present
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Find the gender buttons - look for "Male" and "Female" text
      final maleButton = find.text('Male');
      final femaleButton = find.text('Female');

      // Wait a bit more if buttons aren't found yet
      if (maleButton.evaluate().isEmpty || femaleButton.evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(maleButton, findsOneWidget);
      expect(femaleButton, findsOneWidget);

      // Scroll to make sure the buttons are visible
      await tester.ensureVisible(maleButton);
      await tester.pump();

      // Tap the Male button
      await tester.tap(maleButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Pump several more times to allow any post-frame sync logic to run
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Male STAYS selected: selected button shows white text
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w).data == 'Male' &&
              (w).style?.color == Colors.white,
        ),
        findsOneWidget,
        reason: 'Male button should stay selected (white text) after tap',
      );

      // Now tap the Female button
      await tester.ensureVisible(femaleButton);
      await tester.pump();
      await tester.tap(femaleButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Female STAYS selected
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w).data == 'Female' &&
              (w).style?.color == Colors.white,
        ),
        findsOneWidget,
        reason: 'Female button should stay selected (white text) after tap',
      );
    });

    testWidgets('should allow selecting an activity level',
        (WidgetTester tester) async {
      // Create a test user
      final testUser = User(
        id: 'test_user',
        email: 'test@example.com',
        name: 'Test User',
        age: 30,
        weight: 70.0,
        gender: 'male',
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set up the mock to return the test user immediately
      when(mockDb.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockDb.updateUser(any)).thenAnswer((_) async {});
      when(mockDb.getAllWaterIntakesForUser(any)).thenAnswer((_) async => []);
      when(mockDb.getWaterIntakeForDateAndUser(any, any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      // Pump multiple times to allow async operations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the profile screen is present
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Find the Activity Level section - look for "Activity Level" text
      final activityLevelText = find.text('Activity Level');
      expect(activityLevelText, findsOneWidget);

      // Find the "Moderately Active" text which should be visible
      final moderatelyActiveText = find.text('Moderately Active');
      expect(moderatelyActiveText, findsOneWidget);

      // Scroll to make sure the activity level section is visible
      await tester.ensureVisible(moderatelyActiveText);
      await tester.pump();

      // Tap on the Activity Level section to open the modal
      // We'll tap on the "Moderately Active" text or the container
      await tester.tap(moderatelyActiveText, warnIfMissed: false);
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 500)); // Wait for modal animation

      // Verify the modal is shown - look for "Select Activity Level" title
      final selectActivityLevelTitle = find.text('Select Activity Level');
      expect(selectActivityLevelTitle, findsOneWidget);

      // Find and tap "Very Active" option in the modal
      final veryActiveOption = find.text('Very Active');
      expect(veryActiveOption, findsOneWidget);

      await tester.tap(veryActiveOption);
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 500)); // Wait for modal to close

      // Verify the modal is closed (title should not be visible)
      expect(selectActivityLevelTitle, findsNothing);

      // Pump several more times to allow any post-frame sync logic to run
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the activity level STAYS selected: profile should now display "Very Active"
      expect(
        find.text('Very Active'),
        findsOneWidget,
        reason:
            'Activity level section should display "Very Active" after selection',
      );
      // Ensure it's the one in the profile (not in a modal - modal is closed)
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('should allow selecting gender and activity level in sequence',
        (WidgetTester tester) async {
      // Create a test user
      final testUser = User(
        id: 'test_user',
        email: 'test@example.com',
        name: 'Test User',
        age: 30,
        weight: 70.0,
        gender: null,
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set up the mock to return the test user immediately
      when(mockDb.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockDb.updateUser(any)).thenAnswer((_) async {});
      when(mockDb.getAllWaterIntakesForUser(any)).thenAnswer((_) async => []);
      when(mockDb.getWaterIntakeForDateAndUser(any, any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      // Pump multiple times to allow async operations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Step 1: Select gender (Female)
      final femaleButton = find.text('Female');
      expect(femaleButton, findsOneWidget);

      await tester.ensureVisible(femaleButton);
      await tester.pump();
      await tester.tap(femaleButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Step 2: Select activity level
      final moderatelyActiveText = find.text('Moderately Active');
      expect(moderatelyActiveText, findsOneWidget);

      await tester.ensureVisible(moderatelyActiveText);
      await tester.pump();
      await tester.tap(moderatelyActiveText, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify modal is open
      final selectActivityLevelTitle = find.text('Select Activity Level');
      expect(selectActivityLevelTitle, findsOneWidget);

      // Select "Lightly Active"
      final lightlyActiveOption = find.text('Lightly Active');
      expect(lightlyActiveOption, findsOneWidget);

      await tester.tap(lightlyActiveOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify modal is closed
      expect(selectActivityLevelTitle, findsNothing);

      // Pump to allow sync logic
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify both selections STAY: Female selected and Lightly Active displayed
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w).data == 'Female' &&
              (w).style?.color == Colors.white,
        ),
        findsOneWidget,
        reason: 'Female should stay selected',
      );
      expect(
        find.text('Lightly Active'),
        findsOneWidget,
        reason:
            'Activity level should display "Lightly Active" after selection',
      );
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
