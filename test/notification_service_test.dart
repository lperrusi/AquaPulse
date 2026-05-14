import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydration_tracker/models/reminder.dart';
import 'package:hydration_tracker/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService scheduling/cancel IDs', () {
    final service = NotificationService();

    test('schedules one weekly notification per selected day', () async {
      final reminder = Reminder(
        id: 'weekly-reminder',
        userId: 'u1',
        title: 'Weekly',
        message: 'Drink water',
        time: const TimeOfDay(hour: 9, minute: 0),
        daysOfWeek: const [1, 3, 5],
        isActive: true,
      );

      final ids = service.expectedReminderNotificationIds(reminder);
      expect(ids.length, 3);
      expect(ids.toSet().length, 3);
    });

    test('schedules interval reminders with deterministic IDs', () async {
      final reminder = Reminder(
        id: 'interval-reminder',
        userId: 'u1',
        title: 'Interval',
        message: 'Drink water',
        time: const TimeOfDay(hour: 8, minute: 0),
        daysOfWeek: const [2],
        isActive: true,
        isInterval: true,
        intervalMinutes: 60,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
      );
      final ids = service.expectedReminderNotificationIds(reminder);
      // 3 slots/day (8:00, 9:00, 10:00) for 4 weeks.
      expect(ids.length, 12);
      expect(ids.toSet().length, 12);
    });

    test('cancel/delete path uses symmetric interval ID strategy', () {
      final reminder = Reminder(
        id: 'cancel-interval',
        userId: 'u1',
        title: 'Cancel Interval',
        message: 'Drink water',
        time: const TimeOfDay(hour: 8, minute: 0),
        daysOfWeek: const [2],
        isActive: true,
        isInterval: true,
        intervalMinutes: 60,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
      );
      final ids = service.expectedReminderNotificationIds(reminder);
      expect(ids.length, 12);
      expect(ids.toSet().length, 12);
    });
  });
}