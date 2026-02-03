import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydration_tracker/models/reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Reminder Model Tests', () {
    late Reminder testReminder;

    setUp(() {
      testReminder = const Reminder(
        id: 'test-reminder-1',
        userId: 'test-user',
        title: 'Morning Hydration',
        message: 'Time to drink water! 💧',
        time: TimeOfDay(hour: 9, minute: 0),
        daysOfWeek: [1, 2, 3, 4, 5], // Monday to Friday
        isActive: true,
      );
    });

    group('Constructor and Properties', () {
      test('should create reminder with all required properties', () {
        expect(testReminder.id, equals('test-reminder-1'));
        expect(testReminder.title, equals('Morning Hydration'));
        expect(testReminder.message, equals('Time to drink water! 💧'));
        expect(testReminder.time, equals(const TimeOfDay(hour: 9, minute: 0)));
        expect(testReminder.daysOfWeek, equals([1, 2, 3, 4, 5]));
        expect(testReminder.isActive, isTrue);
        expect(testReminder.isInterval, isFalse);
      });

      test('should create interval reminder with all properties', () {
        final intervalReminder = Reminder(
          id: 'interval-reminder',
          userId: 'test-user',
          title: 'Hourly Reminder',
          message: 'Drink water every hour',
          time: const TimeOfDay(hour: 8, minute: 0),
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isActive: true,
          isInterval: true,
          intervalMinutes: 60,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
        );

        expect(intervalReminder.isInterval, isTrue);
        expect(intervalReminder.intervalMinutes, equals(60));
        expect(intervalReminder.startTime, equals(const TimeOfDay(hour: 8, minute: 0)));
        expect(intervalReminder.endTime, equals(const TimeOfDay(hour: 18, minute: 0)));
      });
    });

    group('copyWith', () {
      test('should create copy with updated properties', () {
        final updatedReminder = testReminder.copyWith(
          title: 'Updated Title',
          message: 'Updated message',
          isActive: false,
        );

        expect(updatedReminder.id, equals(testReminder.id));
        expect(updatedReminder.title, equals('Updated Title'));
        expect(updatedReminder.message, equals('Updated message'));
        expect(updatedReminder.isActive, isFalse);
        expect(updatedReminder.time, equals(testReminder.time));
        expect(updatedReminder.daysOfWeek, equals(testReminder.daysOfWeek));
      });

      test('should create copy with interval properties', () {
        final intervalReminder = testReminder.copyWith(
          isInterval: true,
          intervalMinutes: 30,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
        );

        expect(intervalReminder.isInterval, isTrue);
        expect(intervalReminder.intervalMinutes, equals(30));
        expect(intervalReminder.startTime, equals(const TimeOfDay(hour: 9, minute: 0)));
        expect(intervalReminder.endTime, equals(const TimeOfDay(hour: 17, minute: 0)));
      });

      test('should keep original properties when not specified', () {
        final updatedReminder = testReminder.copyWith(title: 'New Title');

        expect(updatedReminder.id, equals(testReminder.id));
        expect(updatedReminder.title, equals('New Title'));
        expect(updatedReminder.message, equals(testReminder.message));
        expect(updatedReminder.time, equals(testReminder.time));
        expect(updatedReminder.daysOfWeek, equals(testReminder.daysOfWeek));
        expect(updatedReminder.isActive, equals(testReminder.isActive));
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final json = testReminder.toJson();

        expect(json['id'], equals('test-reminder-1'));
        expect(json['title'], equals('Morning Hydration'));
        expect(json['message'], equals('Time to drink water! 💧'));
        expect(json['time_hour'], equals(9));
        expect(json['time_minute'], equals(0));
        expect(json['days_of_week'], equals('1,2,3,4,5'));
        expect(json['is_active'], equals(1));
        expect(json['is_interval'], equals(0));
        expect(json['interval_minutes'], isNull);
        expect(json['start_time_hour'], isNull);
        expect(json['start_time_minute'], isNull);
        expect(json['end_time_hour'], isNull);
        expect(json['end_time_minute'], isNull);
      });

      test('should convert interval reminder to JSON correctly', () {
        final intervalReminder = Reminder(
          id: 'interval-reminder',
          userId: 'test-user',
          title: 'Hourly Reminder',
          message: 'Drink water every hour',
          time: const TimeOfDay(hour: 8, minute: 0),
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          isActive: true,
          isInterval: true,
          intervalMinutes: 60,
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
        );

        final json = intervalReminder.toJson();

        expect(json['is_interval'], equals(1));
        expect(json['interval_minutes'], equals(60));
        expect(json['start_time_hour'], equals(8));
        expect(json['start_time_minute'], equals(0));
        expect(json['end_time_hour'], equals(18));
        expect(json['end_time_minute'], equals(0));
      });

      test('should create from JSON correctly', () {
        final json = {
          'id': 'test-reminder-1',
          'userId': 'test-user',
          'title': 'Morning Hydration',
          'message': 'Time to drink water! 💧',
          'time_hour': 9,
          'time_minute': 0,
          'days_of_week': '1,2,3,4,5',
          'is_active': 1,
          'is_interval': 0,
          'interval_minutes': null,
          'start_time_hour': null,
          'start_time_minute': null,
          'end_time_hour': null,
          'end_time_minute': null,
        };

        final reminder = Reminder.fromJson(json);

        expect(reminder.id, equals('test-reminder-1'));
        expect(reminder.title, equals('Morning Hydration'));
        expect(reminder.message, equals('Time to drink water! 💧'));
        expect(reminder.time, equals(const TimeOfDay(hour: 9, minute: 0)));
        expect(reminder.daysOfWeek, equals([1, 2, 3, 4, 5]));
        expect(reminder.isActive, isTrue);
        expect(reminder.isInterval, isFalse);
      });

      test('should create interval reminder from JSON correctly', () {
        final json = {
          'id': 'interval-reminder',
          'userId': 'test-user',
          'title': 'Hourly Reminder',
          'message': 'Drink water every hour',
          'time_hour': 8,
          'time_minute': 0,
          'days_of_week': '1,2,3,4,5,6,7',
          'is_active': 1,
          'is_interval': 1,
          'interval_minutes': 60,
          'start_time_hour': 8,
          'start_time_minute': 0,
          'end_time_hour': 18,
          'end_time_minute': 0,
        };

        final reminder = Reminder.fromJson(json);

        expect(reminder.isInterval, isTrue);
        expect(reminder.intervalMinutes, equals(60));
        expect(reminder.startTime, equals(const TimeOfDay(hour: 8, minute: 0)));
        expect(reminder.endTime, equals(const TimeOfDay(hour: 18, minute: 0)));
      });

      test('should handle empty days of week', () {
        final json = {
          'id': 'test-reminder',
          'userId': 'test-user',
          'title': 'Test',
          'message': 'Test message',
          'time_hour': 9,
          'time_minute': 0,
          'days_of_week': '',
          'is_active': 1,
          'is_interval': 0,
          'interval_minutes': null,
          'start_time_hour': null,
          'start_time_minute': null,
          'end_time_hour': null,
          'end_time_minute': null,
        };

        final reminder = Reminder.fromJson(json);
        expect(reminder.daysOfWeek, isEmpty);
      });
    });

    group('Equality and HashCode', () {
      test('should be equal to identical reminder', () {
        final reminder1 = const Reminder(
          id: 'test-1',
          userId: 'test-user',
          title: 'Test',
          message: 'Test message',
          time: TimeOfDay(hour: 9, minute: 0),
          daysOfWeek: [1, 2, 3],
          isActive: true,
        );

        final reminder2 = const Reminder(
          id: 'test-1',
          userId: 'test-user',
          title: 'Test',
          message: 'Test message',
          time: TimeOfDay(hour: 9, minute: 0),
          daysOfWeek: [1, 2, 3],
          isActive: true,
        );

        expect(reminder1, equals(reminder2));
        expect(reminder1.hashCode, equals(reminder2.hashCode));
      });

      test('should not be equal to different reminder', () {
        final reminder1 = const Reminder(
          id: 'test-1',
          userId: 'test-user',
          title: 'Test',
          message: 'Test message',
          time: TimeOfDay(hour: 9, minute: 0),
          daysOfWeek: [1, 2, 3],
          isActive: true,
        );

        final reminder2 = const Reminder(
          id: 'test-2',
          userId: 'test-user',
          title: 'Test',
          message: 'Test message',
          time: TimeOfDay(hour: 9, minute: 0),
          daysOfWeek: [1, 2, 3],
          isActive: true,
        );

        expect(reminder1, isNot(equals(reminder2)));
      });

      test('should not be equal to different type', () {
        expect(testReminder, isNot(equals('not a reminder')));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        final string = testReminder.toString();
        
        expect(string, contains('test-reminder-1'));
        expect(string, contains('Morning Hydration'));
        expect(string, contains('Time to drink water! 💧'));
        expect(string, contains('TimeOfDay(09:00)'));
        expect(string, contains('[1, 2, 3, 4, 5]'));
        expect(string, contains('isActive: true'));
      });
    });
  });
} 