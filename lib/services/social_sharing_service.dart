/// Social Sharing Service
///
/// Handles sharing achievements, stats, and milestones to social media platforms.
/// Provides methods for creating shareable content and managing social interactions.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/user.dart';


/// Social sharing data for tracking shared content
class SocialShare {
  final String id;
  final String type; // 'achievement', 'milestone', 'streak', 'goal'
  final String title;
  final String message;
  final String? imageUrl;
  final DateTime sharedAt;
  final int likes;
  final int shares;

  SocialShare({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.sharedAt,
    this.likes = 0,
    this.shares = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'sharedAt': sharedAt.toIso8601String(),
      'likes': likes,
      'shares': shares,
    };
  }

  factory SocialShare.fromJson(Map<String, dynamic> json) {
    return SocialShare(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      imageUrl: json['imageUrl'] as String?,
      sharedAt: DateTime.parse(json['sharedAt'] as String),
      likes: json['likes'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
    );
  }
}

/// Service for handling social sharing and interactions
class SocialSharingService {
  static const String _sharesKey = 'social_shares';
  static SocialSharingService? _instance;
  factory SocialSharingService() => _instance ??= SocialSharingService._internal();
  SocialSharingService._internal();

  /// Creates a shareable message for an achievement
  String createAchievementShareMessage(Achievement achievement, User user) {
    final baseMessage = achievement.defaultShareMessage;
    final personalizedMessage = baseMessage.replaceAll(
      'I just achieved',
      '${user.name ?? 'I'} just achieved'
    );
    
    return '$personalizedMessage\n\nDownload AquaPulse to track your own progress! #StayHydrated #AquaPulse';
  }

  /// Creates a shareable message for a streak milestone
  String createStreakShareMessage(int streak, User user) {
    String message;
    if (streak >= 100) {
      message = '🔥 ${user.name ?? 'I'} just reached a $streak-day hydration streak! Century champion!';
    } else if (streak >= 30) {
      message = '🔥 ${user.name ?? 'I'} just reached a $streak-day hydration streak! Hydration master!';
    } else if (streak >= 14) {
      message = '🔥 ${user.name ?? 'I'} just reached a $streak-day hydration streak! Fortnight fighter!';
    } else if (streak >= 7) {
      message = '🔥 ${user.name ?? 'I'} just reached a $streak-day hydration streak! Week warrior!';
    } else {
      message = '🔥 ${user.name ?? 'I'} just reached a $streak-day hydration streak! Getting started!';
    }
    
    return '$message\n\nDownload AquaPulse to build your own streak! #StayHydrated #AquaPulse';
  }

  /// Creates a shareable message for goal completion
  String createGoalShareMessage(double goal, User user) {
    return '🎯 ${user.name ?? 'I'} just met my daily hydration goal of ${goal.toInt()}ml! 💧\n\nDownload AquaPulse to set and achieve your own goals! #StayHydrated #AquaPulse';
  }

  /// Creates a shareable message for milestone completion
  String createMilestoneShareMessage(String milestone, double amount, User user) {
    return '🏆 ${user.name ?? 'I'} just reached the $milestone milestone with ${amount.toInt()}ml total! 💧\n\nDownload AquaPulse to track your own milestones! #StayHydrated #AquaPulse';
  }

  /// Creates a shareable message for weekly stats
  String createWeeklyStatsMessage(Map<String, dynamic> stats, User user) {
    final averageIntake = stats['averageIntake'] as double;
    final goalDays = stats['goalDays'] as int;
    final totalIntake = stats['totalIntake'] as double;
    
    return '📊 ${user.name ?? 'My'} weekly hydration stats:\n'
           '💧 Average daily intake: ${averageIntake.toInt()}ml\n'
           '🎯 Goal days: $goalDays/7\n'
           '📈 Total intake: ${totalIntake.toInt()}ml\n\n'
           'Download AquaPulse to track your own stats! #StayHydrated #AquaPulse';
  }

  /// Records a social share
  Future<void> recordShare(SocialShare share) async {
    final prefs = await SharedPreferences.getInstance();
    final shares = await getShares();
    shares.add(share);
    
    // Keep only last 50 shares
    if (shares.length > 50) {
      shares.removeRange(0, shares.length - 50);
    }
    
    final sharesJson = shares.map((s) => s.toJson()).toList();
    await prefs.setString(_sharesKey, json.encode(sharesJson));
  }

  /// Gets all recorded shares
  Future<List<SocialShare>> getShares() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_sharesKey);
    
    if (data != null) {
      try {
        final List<dynamic> sharesJson = json.decode(data);
        return sharesJson.map((json) => SocialShare.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Error loading shares: $e');
      }
    }
    
    return [];
  }

  /// Gets share statistics
  Future<Map<String, dynamic>> getShareStats() async {
    final shares = await getShares();
    final totalShares = shares.length;
    final totalLikes = shares.fold(0, (sum, share) => sum + share.likes);
    final totalSharesCount = shares.fold(0, (sum, share) => sum + share.shares);
    
    // Group by type
    final Map<String, int> sharesByType = {};
    for (final share in shares) {
      sharesByType[share.type] = (sharesByType[share.type] ?? 0) + 1;
    }
    
    return {
      'totalShares': totalShares,
      'totalLikes': totalLikes,
      'totalSharesCount': totalSharesCount,
      'sharesByType': sharesByType,
    };
  }

  /// Creates a shareable image data (placeholder for future implementation)
  Map<String, dynamic> createShareableImageData(Achievement achievement) {
    return {
      'title': achievement.title,
      'description': achievement.description,
      'icon': achievement.icon,
      'tier': achievement.tierName,
      'tierColor': achievement.tierColor,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Generates hashtags for social sharing
  List<String> getDefaultHashtags() {
    return [
      '#StayHydrated',
      '#HydrationTracker',
      '#WaterGoals',
      '#HealthGoals',
      '#Wellness',
    ];
  }

  /// Creates a personalized share message with user's name
  String personalizeMessage(String message, User user) {
    if (user.name != null && user.name!.isNotEmpty) {
      return message.replaceAll('I', user.name!);
    }
    return message;
  }

  /// Validates if content is appropriate for sharing
  bool isContentAppropriate(String content) {
    // Basic content validation
    final inappropriateWords = ['bad', 'inappropriate']; // Add more as needed
    final lowerContent = content.toLowerCase();
    
    for (final word in inappropriateWords) {
      if (lowerContent.contains(word)) {
        return false;
      }
    }
    
    return true;
  }

  /// Gets trending hashtags based on current time/season
  List<String> getTrendingHashtags() {
    final now = DateTime.now();
    final month = now.month;
    final hour = now.hour;
    
    final hashtags = ['#StayHydrated', '#HydrationTracker'];
    
    // Seasonal hashtags
    if (month >= 6 && month <= 8) {
      hashtags.add('#SummerHydration');
    } else if (month >= 12 || month <= 2) {
      hashtags.add('#WinterHydration');
    }
    
    // Time-based hashtags
    if (hour >= 6 && hour <= 10) {
      hashtags.add('#MorningHydration');
    } else if (hour >= 12 && hour <= 14) {
      hashtags.add('#LunchHydration');
    } else if (hour >= 15 && hour <= 18) {
      hashtags.add('#AfternoonHydration');
    }
    
    return hashtags;
  }
} 