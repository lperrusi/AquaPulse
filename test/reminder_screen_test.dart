import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hydration_tracker/models/reminder.dart';
import 'package:hydration_tracker/screens/reminders_screen.dart';
import 'package:hydration_tracker/services/database_service.dart';
import 'package:hydration_tracker/providers/app_providers.dart';

// Generate mocks for DatabaseService
@GenerateMocks([DatabaseService])
import 'reminder_screen_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RemindersScreen Widget Tests', () {
    late MockDatabaseService mockDatabaseService;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      when(mockDatabaseService.getAllReminders())
          .thenAnswer((_) async => <Reminder>[]);
      when(mockDatabaseService.addReminder(any)).thenAnswer((_) async {});
      when(mockDatabaseService.updateReminder(any)).thenAnswer((_) async {});
      when(mockDatabaseService.deleteReminder(any)).thenAnswer((_) async {});
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDatabaseService),
        ],
        child: MaterialApp(
          home: const RemindersScreen(),
        ),
      );
    }

    testWidgets('renders reminders screen core sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Quick Add'), findsOneWidget);
      expect(find.text('Interval Reminders'), findsOneWidget);
    });

    testWidgets('renders reminder card data from provider',
        (WidgetTester tester) async {
      when(mockDatabaseService.getAllReminders()).thenAnswer(
        (_) async => <Reminder>[
          const Reminder(
            id: 'reminder-1',
            userId: 'test-user',
            title: 'Morning Hydration',
            message: 'Time to drink water! 💧',
            time: TimeOfDay(hour: 9, minute: 0),
            daysOfWeek: [1, 2, 3, 4, 5],
            isActive: true,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Morning Hydration'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('gracefully handles reminders load error',
        (WidgetTester tester) async {
      when(mockDatabaseService.getAllReminders())
          .thenThrow(Exception('Database error'));

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });
  });
}
