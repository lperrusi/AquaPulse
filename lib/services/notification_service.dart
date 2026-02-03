/// Notification Service
///
/// Handles all local notification scheduling, permissions, and cancellation for hydration reminders and goal/streak alerts.
/// Integrates with flutter_local_notifications and timezone packages.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/reminder.dart';
import 'notification_analytics_service.dart';

/// Service class for managing local notifications for reminders, goals, and streaks.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final NotificationAnalyticsService _analyticsService = NotificationAnalyticsService();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Handles when user taps on a notification
  void _onNotificationResponse(NotificationResponse response) {
    // Track that user responded to notification
    _analyticsService.recordNotificationResponse();
    
    // Handle different notification types based on payload
    if (response.payload != null) {
      // Could add specific handling for different notification types
      debugPrint('Notification response: ${response.payload}');
    }
  }



  /// Records when user dismisses a notification (called from UI)
  Future<void> recordNotificationDismissal() async {
    await _analyticsService.recordNotificationDismissal();
  }

  /// Records when user responds to a notification by drinking water
  Future<void> recordNotificationResponse() async {
    await _analyticsService.recordNotificationResponse();
  }

  Future<void> requestPermissions() async {
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    
    await _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isActive) return;
    
    debugPrint('Scheduling reminder: ${reminder.title}');
    debugPrint('Reminder details: isInterval=${reminder.isInterval}, intervalMinutes=${reminder.intervalMinutes}');

    if (reminder.isInterval && reminder.intervalMinutes != null && reminder.startTime != null && reminder.endTime != null) {
      // Schedule interval-based reminders for each selected day
      for (int dayOfWeek in reminder.daysOfWeek) {
        final now = DateTime.now();
        final today = now.weekday;
        
        // Schedule for the next 4 weeks to ensure we have enough notifications scheduled
        for (int weekOffset = 0; weekOffset < 4; weekOffset++) {
          // Calculate days until target day
          int daysUntilTarget = dayOfWeek - today + (weekOffset * 7);
          if (daysUntilTarget < 0) {
            daysUntilTarget += 7;
          }
          
          final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: daysUntilTarget));
          
          // Calculate start and end times for this day
          DateTime start = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            reminder.startTime!.hour,
            reminder.startTime!.minute,
          );
          DateTime end = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            reminder.endTime!.hour,
            reminder.endTime!.minute,
          );
          
          // If this is today and start time has passed, find the next interval
          if (daysUntilTarget == 0 && now.isAfter(start)) {
            // Find the next interval time that hasn't passed
            DateTime nextInterval = start;
            while (nextInterval.isBefore(now) && nextInterval.isBefore(end)) {
              nextInterval = nextInterval.add(Duration(minutes: reminder.intervalMinutes!));
            }
            if (nextInterval.isBefore(end) || nextInterval.isAtSameMomentAs(end)) {
              start = nextInterval;
            } else {
              // All intervals for today have passed, skip to next week
              continue;
            }
          }
          
          // Schedule notifications starting from the start time, then every interval
          DateTime currentTime = start;
          int notificationCount = 0;
          
          while (currentTime.isBefore(end) || currentTime.isAtSameMomentAs(end)) {
            // Skip if this time has already passed (for today)
            if (daysUntilTarget == 0 && currentTime.isBefore(now)) {
              currentTime = currentTime.add(Duration(minutes: reminder.intervalMinutes!));
              notificationCount++;
              continue;
            }
            
            try {
              // Create unique ID for each notification (include week offset to ensure uniqueness)
              int notificationId = _getNotificationId(reminder.id, dayOfWeek) + notificationCount + (weekOffset * 1000);
              
              await _notifications.zonedSchedule(
                notificationId,
                reminder.title,
                reminder.message,
                tz.TZDateTime.from(currentTime, tz.local),
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'hydration_reminders',
                    'Hydration Reminders',
                    channelDescription: 'Reminders to drink water',
                    importance: Importance.high,
                    priority: Priority.high,
                    icon: '@mipmap/ic_launcher',
                  ),
                  iOS: DarwinNotificationDetails(
                    presentAlert: true,
                    presentBadge: true,
                    presentSound: true,
                  ),
                ),
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
                // Don't use matchDateTimeComponents for interval reminders - we schedule each occurrence explicitly
                // matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              );
              
              debugPrint('Scheduled interval notification for ${currentTime.year}-${currentTime.month.toString().padLeft(2, '0')}-${currentTime.day.toString().padLeft(2, '0')} ${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')}');
              
              // Move to next interval
              currentTime = currentTime.add(Duration(minutes: reminder.intervalMinutes!));
              notificationCount++;
            } catch (e) {
              debugPrint('Error scheduling notification: $e');
              break; // Stop if there's an error
            }
          }
        }
      }
    } else {
      // Time-based reminder (existing logic)
      for (int dayOfWeek in reminder.daysOfWeek) {
        await _scheduleWeeklyNotification(reminder, dayOfWeek);
      }
    }
  }

  Future<void> _scheduleWeeklyNotification(Reminder reminder, int dayOfWeek) async {
    final scheduledDate = _getNextInstanceOfDay(dayOfWeek, reminder.time);
    
    if (scheduledDate.isBefore(DateTime.now())) {
      // Schedule for next week
      scheduledDate.add(const Duration(days: 7));
    }

    try {
      await _notifications.zonedSchedule(
        _getNotificationId(reminder.id, dayOfWeek),
        reminder.title,
        reminder.message,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_reminders',
            'Hydration Reminders',
            channelDescription: 'Reminders to drink water',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Error scheduling weekly notification: $e');
    }
  }

  DateTime _getNextInstanceOfDay(int dayOfWeek, TimeOfDay time) {
    final now = DateTime.now();
    final today = now.weekday;
    
    int daysUntilNext = dayOfWeek - today;
    if (daysUntilNext <= 0) {
      daysUntilNext += 7;
    }
    
    final nextDate = DateTime(
      now.year,
      now.month,
      now.day + daysUntilNext,
      time.hour,
      time.minute,
    );
    
    return nextDate;
  }

  int _getNotificationId(String reminderId, int dayOfWeek) {
    // Create unique ID based on reminder ID and day of week
    return reminderId.hashCode + dayOfWeek;
  }

  Future<void> cancelReminder(Reminder reminder) async {
    for (int dayOfWeek in reminder.daysOfWeek) {
      // Cancel all notifications for this reminder and day
      // For interval reminders, we need to cancel multiple notifications
      if (reminder.isInterval && reminder.intervalMinutes != null && reminder.startTime != null && reminder.endTime != null) {
        // Calculate how many notifications were scheduled
        DateTime start = _getNextInstanceOfDay(dayOfWeek, reminder.startTime!);
        DateTime end = _getNextInstanceOfDay(dayOfWeek, reminder.endTime!);
        if (end.isBefore(start)) {
          end = end.add(const Duration(days: 7));
        }
        
        // Cancel all notifications for this reminder
        int notificationCount = 0;
        DateTime currentTime = start;
        while (currentTime.isBefore(end) || currentTime.isAtSameMomentAs(end)) {
          int notificationId = _getNotificationId(reminder.id, dayOfWeek) + notificationCount;
          await _notifications.cancel(notificationId);
          currentTime = currentTime.add(Duration(minutes: reminder.intervalMinutes!));
          notificationCount++;
        }
      } else {
        // For regular reminders, just cancel the single notification
        await _notifications.cancel(_getNotificationId(reminder.id, dayOfWeek));
      }
    }
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate_notifications',
          'Immediate Notifications',
          channelDescription: 'Immediate notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> scheduleGoalReminder({
    required String userId,
    required double remainingAmount,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledTime.isBefore(now)) {
      return; // Don't schedule for past time
    }

    await _notifications.zonedSchedule(
      'goal_reminder_$userId'.hashCode,
      'Hydration Goal Reminder',
      'You still need ${remainingAmount.toStringAsFixed(0)}ml to reach your daily goal!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reminders',
          'Goal Reminders',
          channelDescription: 'Reminders about daily hydration goals',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleStreakReminder({
    required String userId,
    required int currentStreak,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledTime.isBefore(now)) {
      return;
    }

    String message = 'Keep your streak going!';
    if (currentStreak >= 7) {
      message = 'Amazing! You\'re on a $currentStreak day streak! Keep it up!';
    } else if (currentStreak >= 3) {
      message = 'Great progress! You\'re on a $currentStreak day streak!';
    }

    await _notifications.zonedSchedule(
      'streak_reminder_$userId'.hashCode,
      'Streak Reminder',
      message,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminders',
          'Streak Reminders',
          channelDescription: 'Reminders to maintain hydration streaks',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Debug method to print all pending notifications
  Future<void> debugPrintPendingNotifications() async {
    final pendingNotifications = await getPendingNotifications();
    debugPrint('=== PENDING NOTIFICATIONS ===');
    for (final notification in pendingNotifications) {
      debugPrint('ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
    }
    debugPrint('=============================');
  }

  /// Debug method to test interval scheduling
  Future<void> debugTestIntervalScheduling(Reminder reminder) async {
    if (!reminder.isInterval || reminder.intervalMinutes == null || 
        reminder.startTime == null || reminder.endTime == null) {
      debugPrint('Debug: Reminder is not an interval reminder');
      return;
    }

    debugPrint('=== INTERVAL SCHEDULING DEBUG ===');
    debugPrint('Start Time: ${reminder.startTime!.hour}:${reminder.startTime!.minute.toString().padLeft(2, '0')}');
    debugPrint('End Time: ${reminder.endTime!.hour}:${reminder.endTime!.minute.toString().padLeft(2, '0')}');
    debugPrint('Interval: ${reminder.intervalMinutes} minutes');
    debugPrint('Days: ${reminder.daysOfWeek}');

    for (int dayOfWeek in reminder.daysOfWeek) {
      DateTime start = _getNextInstanceOfDay(dayOfWeek, reminder.startTime!);
      DateTime end = _getNextInstanceOfDay(dayOfWeek, reminder.endTime!);
      
      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 7));
      }

      debugPrint('Day $dayOfWeek:');
      debugPrint('  Start: ${start.hour}:${start.minute.toString().padLeft(2, '0')}');
      debugPrint('  End: ${end.hour}:${end.minute.toString().padLeft(2, '0')}');

      DateTime currentTime = start;
      int count = 0;
      while (currentTime.isBefore(end) || currentTime.isAtSameMomentAs(end)) {
        debugPrint('  Notification $count: ${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')}');
        currentTime = currentTime.add(Duration(minutes: reminder.intervalMinutes!));
        count++;
      }
    }
    debugPrint('================================');
  }
} 