/// Notification Analytics Service
///
/// Tracks user interaction patterns with notifications and optimizes notification timing.
/// Analyzes when users are most likely to drink water and adjusts notification schedules accordingly.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_intake.dart';

/// Analytics data for notification optimization
class NotificationAnalytics {
  final Map<int, int> hourlyIntakePattern; // Hour -> intake count
  final Map<int, double> hourlyIntakeAmount; // Hour -> average intake amount
  final List<DateTime> notificationDismissals;
  final List<DateTime> notificationResponses;
  final DateTime lastAnalysis;

  NotificationAnalytics({
    required this.hourlyIntakePattern,
    required this.hourlyIntakeAmount,
    required this.notificationDismissals,
    required this.notificationResponses,
    required this.lastAnalysis,
  });

  Map<String, dynamic> toJson() {
    return {
      'hourlyIntakePattern': hourlyIntakePattern,
      'hourlyIntakeAmount': hourlyIntakeAmount,
      'notificationDismissals': notificationDismissals.map((d) => d.toIso8601String()).toList(),
      'notificationResponses': notificationResponses.map((d) => d.toIso8601String()).toList(),
      'lastAnalysis': lastAnalysis.toIso8601String(),
    };
  }

  factory NotificationAnalytics.fromJson(Map<String, dynamic> json) {
    return NotificationAnalytics(
      hourlyIntakePattern: Map<int, int>.from(json['hourlyIntakePattern'] ?? {}),
      hourlyIntakeAmount: Map<int, double>.from(json['hourlyIntakeAmount'] ?? {}),
      notificationDismissals: (json['notificationDismissals'] as List?)
          ?.map((d) => DateTime.parse(d))
          .toList() ?? [],
      notificationResponses: (json['notificationResponses'] as List?)
          ?.map((d) => DateTime.parse(d))
          .toList() ?? [],
      lastAnalysis: DateTime.parse(json['lastAnalysis']),
    );
  }
}

/// Service for analyzing user patterns and optimizing notifications
class NotificationAnalyticsService {
  static const String _analyticsKey = 'notification_analytics';
  static NotificationAnalyticsService? _instance;
  factory NotificationAnalyticsService() => _instance ??= NotificationAnalyticsService._internal();
  NotificationAnalyticsService._internal();

  /// Analyzes user intake patterns and returns optimal notification times
  Future<List<int>> getOptimalNotificationHours(List<WaterIntake> intakes) async {
    final analytics = await _analyzeIntakePatterns(intakes);
    return _calculateOptimalHours(analytics);
  }

  /// Records when a user responds to a notification (drinks water)
  Future<void> recordNotificationResponse() async {
    final analytics = await _loadAnalytics();
    
    analytics.notificationResponses.add(DateTime.now());
    
    // Keep only last 30 days of data
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    analytics.notificationResponses.removeWhere((date) => date.isBefore(thirtyDaysAgo));
    
    await _saveAnalytics(analytics);
  }



  /// Records when a user dismisses a notification
  Future<void> recordNotificationDismissal() async {
    final analytics = await _loadAnalytics();
    
    analytics.notificationDismissals.add(DateTime.now());
    
    // Keep only last 30 days of data
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    analytics.notificationDismissals.removeWhere((date) => date.isBefore(thirtyDaysAgo));
    
    await _saveAnalytics(analytics);
  }

  /// Analyzes intake patterns from water intake data
  Future<NotificationAnalytics> _analyzeIntakePatterns(List<WaterIntake> intakes) async {
    final Map<int, int> hourlyPattern = {};
    final Map<int, double> hourlyAmount = {};
    final Map<int, int> hourlyCount = {};

    // Initialize hourly maps
    for (int hour = 0; hour < 24; hour++) {
      hourlyPattern[hour] = 0;
      hourlyAmount[hour] = 0.0;
      hourlyCount[hour] = 0;
    }

    // Analyze intake patterns
    for (final intake in intakes) {
      final hour = intake.timestamp.hour;
      hourlyPattern[hour] = (hourlyPattern[hour] ?? 0) + 1;
      hourlyAmount[hour] = (hourlyAmount[hour] ?? 0.0) + intake.amount;
      hourlyCount[hour] = (hourlyCount[hour] ?? 0) + 1;
    }

    // Calculate averages
    for (int hour = 0; hour < 24; hour++) {
      if (hourlyCount[hour]! > 0) {
        hourlyAmount[hour] = hourlyAmount[hour]! / hourlyCount[hour]!;
      }
    }

    final analytics = await _loadAnalytics();
    return NotificationAnalytics(
      hourlyIntakePattern: hourlyPattern,
      hourlyIntakeAmount: hourlyAmount,
      notificationDismissals: analytics.notificationDismissals,
      notificationResponses: analytics.notificationResponses,
      lastAnalysis: DateTime.now(),
    );
  }

  /// Calculates optimal notification hours based on analytics
  List<int> _calculateOptimalHours(NotificationAnalytics analytics) {
    final List<MapEntry<int, double>> hourScores = [];

    // Calculate scores for each hour based on:
    // 1. Low current intake (opportunity for improvement)
    // 2. High response rate to notifications
    // 3. Avoid hours with high natural intake

    for (int hour = 0; hour < 24; hour++) {
      double score = 0.0;
      
      // Lower score for hours with high natural intake
      final naturalIntake = analytics.hourlyIntakePattern[hour] ?? 0;
      if (naturalIntake > 0) {
        score -= naturalIntake * 0.1; // Penalize hours with high natural intake
      }

      // Higher score for hours with low intake (opportunity)
      if (naturalIntake == 0) {
        score += 2.0; // Bonus for hours with no intake
      }

      // Avoid very early and very late hours
      if (hour < 6 || hour > 22) {
        score -= 1.0;
      }

      // Prefer morning hours (6-10)
      if (hour >= 6 && hour <= 10) {
        score += 0.5;
      }

      // Prefer afternoon hours (12-18)
      if (hour >= 12 && hour <= 18) {
        score += 0.3;
      }

      hourScores.add(MapEntry(hour, score));
    }

    // Sort by score and return top 6 hours
    hourScores.sort((a, b) => b.value.compareTo(a.value));
    return hourScores.take(6).map((entry) => entry.key).toList();
  }

  /// Gets response rate for notifications
  double getNotificationResponseRate(NotificationAnalytics analytics) {
    final totalNotifications = analytics.notificationResponses.length + analytics.notificationDismissals.length;
    if (totalNotifications == 0) return 0.0;
    return analytics.notificationResponses.length / totalNotifications;
  }

  /// Loads analytics data from SharedPreferences
  Future<NotificationAnalytics> _loadAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_analyticsKey);
    
    if (data != null) {
      try {
        return NotificationAnalytics.fromJson(json.decode(data));
      } catch (e) {
        debugPrint('Error loading analytics: $e');
      }
    }

    // Return default analytics if none exist
    return NotificationAnalytics(
      hourlyIntakePattern: {},
      hourlyIntakeAmount: {},
      notificationDismissals: [],
      notificationResponses: [],
      lastAnalysis: DateTime.now(),
    );
  }

  /// Saves analytics data to SharedPreferences
  Future<void> _saveAnalytics(NotificationAnalytics analytics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_analyticsKey, json.encode(analytics.toJson()));
  }

  /// Gets smart notification timing suggestions
  Future<List<Map<String, dynamic>>> getSmartNotificationSuggestions(List<WaterIntake> intakes) async {
    final optimalHours = await getOptimalNotificationHours(intakes);
    final analytics = await _loadAnalytics();
    final responseRate = getNotificationResponseRate(analytics);

    return optimalHours.map((hour) {
      String message;
      if (hour >= 6 && hour <= 10) {
        message = 'Start your day hydrated! 💧';
      } else if (hour >= 12 && hour <= 14) {
        message = 'Lunch time hydration! 🥤';
      } else if (hour >= 15 && hour <= 18) {
        message = 'Afternoon pick-me-up! 💪';
      } else if (hour >= 19 && hour <= 22) {
        message = 'Evening hydration! 🌙';
      } else {
        message = 'Time to hydrate! 💦';
      }

      return {
        'hour': hour,
        'message': message,
        'responseRate': responseRate,
      };
    }).toList();
  }
} 