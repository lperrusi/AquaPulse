/// Test Helpers
///
/// Provides common test utilities and mocks for various services used across the app.
/// Centralizes test setup and mock creation for consistent testing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hydration_tracker/models/reminder.dart';
import 'package:hydration_tracker/models/user.dart';
import 'package:hydration_tracker/models/water_intake.dart';
import 'package:hydration_tracker/models/cup_size.dart';
import 'package:hydration_tracker/models/streak.dart';
import 'package:hydration_tracker/services/database_service.dart';
import 'package:hydration_tracker/services/notification_service.dart';
import 'package:hydration_tracker/services/weather_service.dart';
import 'package:hydration_tracker/services/firebase_service.dart';
import 'package:hydration_tracker/providers/app_providers.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// Generate mocks
@GenerateMocks([
  DatabaseService,
  NotificationService,
  WeatherService,
  FirebaseService,
])
import 'test_helpers.mocks.dart';

/// Helper class for creating mock services and test utilities
class TestHelpers {
  /// Creates a mock database service with common setup
  static MockDatabaseService createMockDatabaseService() {
    final mock = MockDatabaseService();

    // Setup common database responses
    when(mock.getCurrentUser()).thenAnswer((_) async => null);
    when(mock.getCurrentUserId()).thenAnswer((_) async => null);
    when(mock.setCurrentUserId(any)).thenAnswer((_) async {});
    when(mock.clearCurrentUserId()).thenAnswer((_) async {});
    when(mock.getAllWaterIntakes()).thenAnswer((_) async => <WaterIntake>[]);
    when(mock.getAllReminders()).thenAnswer((_) async => <Reminder>[]);
    when(mock.getAllCupSizes()).thenAnswer((_) async => <CupSize>[]);
    when(mock.getAllStreaks()).thenAnswer((_) async => <Streak>[]);

    return mock;
  }

  /// Creates a mock notification service with common setup
  static MockNotificationService createMockNotificationService() {
    final mock = MockNotificationService();

    // Setup common notification responses
    when(mock.initialize()).thenAnswer((_) async {});
    when(mock.requestPermissions()).thenAnswer((_) async => true);
    when(mock.scheduleReminder(any)).thenAnswer((_) async {});
    when(mock.cancelReminder(any)).thenAnswer((_) async {});
    when(mock.recordNotificationDismissal()).thenAnswer((_) async {});
    when(mock.recordNotificationResponse()).thenAnswer((_) async {});

    return mock;
  }

  /// Creates a mock weather service with common setup
  static MockWeatherService createMockWeatherService() {
    final mock = MockWeatherService();

    // Setup common weather responses
    when(mock.getCurrentWeather()).thenAnswer((_) async => null);
    when(mock.startBackgroundUpdates()).thenAnswer((_) {});
    when(mock.stopBackgroundUpdates()).thenAnswer((_) {});

    return mock;
  }

  /// Creates a mock Firebase service with common setup
  static MockFirebaseService createMockFirebaseService() {
    final mock = MockFirebaseService();
    when(mock.currentUser).thenReturn(null);
    when(mock.createOrUpdateUser(any)).thenAnswer((_) async {});
    when(mock.authStateChanges)
        .thenAnswer((_) => Stream<firebase_auth.User?>.empty());
    return mock;
  }

  /// Creates a test container with overridden providers
  static ProviderContainer createTestContainer({
    MockDatabaseService? mockDatabase,
    MockNotificationService? mockNotification,
    MockWeatherService? mockWeather,
    MockFirebaseService? mockFirebase,
  }) {
    final database = mockDatabase ?? createMockDatabaseService();
    final notification = mockNotification ?? createMockNotificationService();
    final weather = mockWeather ?? createMockWeatherService();
    final firebase = mockFirebase ?? createMockFirebaseService();

    return ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(database),
        notificationServiceProvider.overrideWithValue(notification),
        // Note: weatherServiceProvider and firebaseServiceProvider are not defined in app_providers.dart
        // We'll need to handle these differently or add them to the providers
      ],
    );
  }

  /// Sets up the test environment with necessary bindings
  static void setupTestEnvironment() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Note: Localizations.localeResolutionCallback is deprecated
    // Localization is handled by MaterialApp in createTestApp
  }

  /// Helper method to pump until settled with a timeout
  static Future<void> pumpUntilSettled(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await tester.pump();
      if (!tester.binding.isRootWidgetAttached) break;

      // Check if there are any pending microtasks or timers
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Creates a test app widget with providers
  static Widget createTestApp({
    required Widget child,
    ProviderContainer? container,
  }) {
    return UncontrolledProviderScope(
      container: container ?? createTestContainer(),
      child: MaterialApp(
        home: child,
        // Localizations are not needed for most tests
        // If needed, can be added via intl package
      ),
    );
  }
}

/// Test data helper class
class TestData {
  /// Creates a test reminder
  static Reminder createTestReminder({
    String? id,
    String? userId,
    String? title,
    String? message,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? isActive,
  }) {
    return Reminder(
      id: id ?? 'test_reminder_id',
      userId: userId ?? 'test_user_id',
      title: title ?? 'Test Reminder',
      message: message ?? 'Test message',
      time: time ?? const TimeOfDay(hour: 9, minute: 0),
      daysOfWeek: daysOfWeek ?? [1, 2, 3, 4, 5],
      isActive: isActive ?? true,
    );
  }

  /// Creates a test user
  static User createTestUser({
    String? id,
    String? email,
    String? name,
  }) {
    return User(
      id: id ?? 'test_user_id',
      email: email ?? 'test@example.com',
      name: name ?? 'Test User',
      age: 25,
      weight: 70.0,
      gender: 'M',
      activityLevel: ActivityLevel.moderatelyActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a test water intake
  static WaterIntake createTestWaterIntake({
    String? id,
    String? userId,
    double? amount,
    DateTime? timestamp,
  }) {
    return WaterIntake(
      id: id ?? 'test_intake_id',
      userId: userId ?? 'test_user_id',
      amount: amount ?? 250.0,
      timestamp: timestamp ?? DateTime.now(),
      note: null,
    );
  }

  /// Creates a test cup size
  static CupSize createTestCupSize({
    String? id,
    String? name,
    double? amount,
    String? icon,
  }) {
    return CupSize(
      id: id ?? 'test_cup_id',
      name: name ?? 'Test Cup',
      amount: amount ?? 250.0,
      icon: icon ?? '🥤',
      createdAt: DateTime.now(),
    );
  }
}
