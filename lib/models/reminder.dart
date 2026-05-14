/// Reminder Model
///
/// Defines the Reminder data model for hydration notifications, including time, days, and active state.
library;

import 'package:flutter/material.dart';

/// Represents a hydration reminder, including time, days of week, and active status.
class Reminder {
  final String id;
  final String userId;
  final String title;
  final String message;
  final TimeOfDay time;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  final bool isActive;
  // Interval-based reminder fields
  final bool isInterval; // true if this is an interval reminder
  final int? intervalMinutes; // interval in minutes (e.g., 60 for every hour)
  final TimeOfDay? startTime; // start time for interval reminders
  final TimeOfDay? endTime; // end time for interval reminders

  const Reminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.time,
    required this.daysOfWeek,
    this.isActive = true,
    this.isInterval = false,
    this.intervalMinutes,
    this.startTime,
    this.endTime,
  });

  Reminder copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? isActive,
    bool? isInterval,
    int? intervalMinutes,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      isInterval: isInterval ?? this.isInterval,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'time_hour': time.hour,
      'time_minute': time.minute,
      'days_of_week': daysOfWeek.join(','),
      'is_active': isActive ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
      'is_interval': isInterval ? 1 : 0,
      'interval_minutes': intervalMinutes,
      'start_time_hour': startTime?.hour,
      'start_time_minute': startTime?.minute,
      'end_time_hour': endTime?.hour,
      'end_time_minute': endTime?.minute,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final daysString = json['days_of_week'] as String? ?? json['daysOfWeek'] as String? ?? '';
    final daysList = daysString.isEmpty ? <int>[] : daysString.split(',').map((e) => int.parse(e)).toList();
    
    // Handle time parsing - support both old and new format
    TimeOfDay time;
    if (json['time'] != null) {
      final timeString = json['time'] as String;
      final parts = timeString.split(':');
      time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      time = TimeOfDay(
        hour: json['time_hour'] as int,
        minute: json['time_minute'] as int,
      );
    }
    
    return Reminder(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      time: time,
      daysOfWeek: daysList,
      isActive: (json['is_active'] as int?) == 1 || (json['isActive'] as int?) == 1,
      isInterval: (json['is_interval'] as int?) == 1,
      intervalMinutes: json['interval_minutes'] as int?,
      startTime: (json['start_time_hour'] != null && json['start_time_minute'] != null)
        ? TimeOfDay(hour: json['start_time_hour'] as int, minute: json['start_time_minute'] as int)
        : null,
      endTime: (json['end_time_hour'] != null && json['end_time_minute'] != null)
        ? TimeOfDay(hour: json['end_time_hour'] as int, minute: json['end_time_minute'] as int)
        : null,
    );
  }

  @override
  String toString() {
    return 'Reminder(id: $id, title: $title, message: $message, time: $time, daysOfWeek: $daysOfWeek, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder &&
        other.id == id &&
        other.title == title &&
        other.message == message &&
        other.time == time &&
        other.daysOfWeek == daysOfWeek &&
        other.isActive == isActive &&
        other.isInterval == isInterval &&
        other.intervalMinutes == intervalMinutes &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        message.hashCode ^
        time.hashCode ^
        daysOfWeek.hashCode ^
        isActive.hashCode ^
        isInterval.hashCode ^
        intervalMinutes.hashCode ^
        startTime.hashCode ^
        endTime.hashCode;
  }
} 