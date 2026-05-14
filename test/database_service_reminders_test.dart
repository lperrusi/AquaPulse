import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydration_tracker/models/reminder.dart';
import 'package:hydration_tracker/models/user.dart';
import 'package:hydration_tracker/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService.getReminders ordering', () {
    final databaseService = DatabaseService();
    const userId = 'reminder-order-user';

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final db = await databaseService.database;
      await db.delete('reminders', where: 'userId = ?', whereArgs: [userId]);
      await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      await databaseService.insertUser(
        User(
          id: userId,
          email: 'order@test.com',
          name: 'Order Test',
          weight: 70,
          activityLevel: ActivityLevel.moderatelyActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    test('returns reminders sorted by hour and minute', () async {
      final db = await databaseService.database;
      await db.delete('reminders', where: 'userId = ?', whereArgs: [userId]);

      await databaseService.insertReminder(
        Reminder(
          id: 'r-late',
          userId: userId,
          title: 'Late',
          message: 'Late',
          time: const TimeOfDay(hour: 19, minute: 30),
          daysOfWeek: const [1],
        ),
      );
      await databaseService.insertReminder(
        Reminder(
          id: 'r-early',
          userId: userId,
          title: 'Early',
          message: 'Early',
          time: const TimeOfDay(hour: 8, minute: 15),
          daysOfWeek: const [1],
        ),
      );
      await databaseService.insertReminder(
        Reminder(
          id: 'r-mid',
          userId: userId,
          title: 'Mid',
          message: 'Mid',
          time: const TimeOfDay(hour: 8, minute: 45),
          daysOfWeek: const [1],
        ),
      );

      final reminders = await databaseService.getReminders(userId);
      final ids = reminders.map((reminder) => reminder.id).toList();

      expect(ids, equals(const ['r-early', 'r-mid', 'r-late']));
    });
  });
}
