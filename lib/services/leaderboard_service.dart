/// Leaderboard Service
///
/// Handles leaderboards, rankings, and competitive statistics.
/// Manages different types of leaderboards and user rankings using Firebase.
library;

import 'package:flutter/foundation.dart';
import '../models/leaderboard.dart';
import 'firebase_service.dart';

/// Service for managing leaderboards and rankings using Firebase
class LeaderboardService {
  final FirebaseService _firebaseService = FirebaseService();
  static LeaderboardService? _instance;
  factory LeaderboardService() => _instance ??= LeaderboardService._internal();
  LeaderboardService._internal();

  /// Gets global leaderboard (returns a stream for real-time updates)
  Stream<Leaderboard?> getGlobalLeaderboardStream({
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
    int limit = 50,
  }) {
    return _firebaseService.getGlobalLeaderboard(period: period, limit: limit);
  }

  /// Gets global leaderboard (one-time fetch)
  Future<Leaderboard?> getGlobalLeaderboard({
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
    int limit = 50,
  }) async {
    try {
      return await _firebaseService.getGlobalLeaderboard(period: period, limit: limit).first;
    } catch (e) {
      debugPrint('Error getting global leaderboard: $e');
      return null;
    }
  }

  /// Gets friends leaderboard
  Future<Leaderboard?> getFriendsLeaderboard({
    required String userId,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return null as this feature needs to be added
      debugPrint('Friends leaderboard functionality needs to be implemented in FirebaseService');
      return null;
    } catch (e) {
      debugPrint('Error getting friends leaderboard: $e');
      return null;
    }
  }

  /// Gets weekly leaderboard
  Future<Leaderboard?> getWeeklyLeaderboard({
    required DateTime weekStart,
    int limit = 50,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return null as this feature needs to be added
      debugPrint('Weekly leaderboard functionality needs to be implemented in FirebaseService');
      return null;
    } catch (e) {
      debugPrint('Error getting weekly leaderboard: $e');
      return null;
    }
  }

  /// Gets monthly leaderboard
  Future<Leaderboard?> getMonthlyLeaderboard({
    required DateTime monthStart,
    int limit = 50,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return null as this feature needs to be added
      debugPrint('Monthly leaderboard functionality needs to be implemented in FirebaseService');
      return null;
    } catch (e) {
      debugPrint('Error getting monthly leaderboard: $e');
      return null;
    }
  }

  /// Gets streak leaderboard (returns a stream for real-time updates)
  Stream<Leaderboard?> getStreakLeaderboardStream({int limit = 50}) {
    return _firebaseService.getStreakLeaderboard(limit: limit);
  }

  /// Gets streak leaderboard (one-time fetch)
  Future<Leaderboard?> getStreakLeaderboard({int limit = 50}) async {
    try {
      return await _firebaseService.getStreakLeaderboard(limit: limit).first;
    } catch (e) {
      debugPrint('Error getting streak leaderboard: $e');
      return null;
    }
  }

  /// Gets total intake leaderboard
  Future<Leaderboard?> getTotalIntakeLeaderboard({int limit = 50}) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return null as this feature needs to be added
      debugPrint('Total intake leaderboard functionality needs to be implemented in FirebaseService');
      return null;
    } catch (e) {
      debugPrint('Error getting total intake leaderboard: $e');
      return null;
    }
  }

  /// Gets user's rank in a leaderboard
  Future<int?> getUserRank({
    required String userId,
    required LeaderboardType type,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return null as this feature needs to be added
      debugPrint('Get user rank functionality needs to be implemented in FirebaseService');
      return null;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return null;
    }
  }

  /// Updates user's leaderboard score
  Future<bool> updateUserScore({
    required String userId,
    required double score,
    required Map<String, dynamic> stats,
    LeaderboardType type = LeaderboardType.global,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
  }) async {
    try {
      await _firebaseService.updateUserScore(
        userId: userId,
        score: score,
        stats: stats,
        type: type,
        period: period,
      );
      return true;
    } catch (e) {
      debugPrint('Error updating user score: $e');
      return false;
    }
  }

  /// Gets leaderboard statistics
  Future<LeaderboardStats?> getLeaderboardStats({
    required LeaderboardType type,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return null as this feature needs to be added
      debugPrint('Get leaderboard stats functionality needs to be implemented in FirebaseService');
      return null;
    } catch (e) {
      debugPrint('Error getting leaderboard stats: $e');
      return null;
    }
  }

  /// Gets user's leaderboard history
  Future<List<LeaderboardEntry>> getUserLeaderboardHistory({
    required String userId,
    required LeaderboardType type,
    int limit = 10,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty list as this feature needs to be added
      debugPrint('Get user leaderboard history functionality needs to be implemented in FirebaseService');
      return [];
    } catch (e) {
      debugPrint('Error getting user leaderboard history: $e');
      return [];
    }
  }

  /// Gets top performers for a specific metric
  Future<List<LeaderboardEntry>> getTopPerformers({
    required String metric,
    int limit = 10,
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty list as this feature needs to be added
      debugPrint('Get top performers functionality needs to be implemented in FirebaseService');
      return [];
    } catch (e) {
      debugPrint('Error getting top performers: $e');
      return [];
    }
  }

  /// Calculates user score based on various metrics
  double calculateUserScore({
    required int currentStreak,
    required int longestStreak,
    required double totalIntake,
    required int goalDays,
    required int totalDays,
    required double averageIntake,
    required double goal,
  }) {
    double score = 0.0;

    // Streak bonus (30% of total score)
    final streakScore = (currentStreak * 10.0) + (longestStreak * 5.0);
    score += streakScore * 0.3;

    // Consistency bonus (25% of total score)
    final consistencyRate = totalDays > 0 ? goalDays / totalDays : 0.0;
    final consistencyScore = consistencyRate * 1000.0;
    score += consistencyScore * 0.25;

    // Total intake bonus (20% of total score)
    final intakeScore = totalIntake / 1000.0; // Normalize to 1000ml base
    score += intakeScore * 0.2;

    // Average intake bonus (15% of total score)
    final averageScore = averageIntake / goal; // Ratio to goal
    score += averageScore * 1000.0 * 0.15;

    // Goal achievement bonus (10% of total score)
    final goalAchievementScore = goalDays * 100.0;
    score += goalAchievementScore * 0.1;

    return score;
  }

  /// Gets leaderboard categories
  Future<List<Map<String, dynamic>>> getLeaderboardCategories() async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty list as this feature needs to be added
      debugPrint('Get leaderboard categories functionality needs to be implemented in FirebaseService');
      return [];
    } catch (e) {
      debugPrint('Error getting leaderboard categories: $e');
      return [];
    }
  }

  /// Gets trending leaderboards
  Future<List<Leaderboard>> getTrendingLeaderboards() async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty list as this feature needs to be added
      debugPrint('Get trending leaderboards functionality needs to be implemented in FirebaseService');
      return [];
    } catch (e) {
      debugPrint('Error getting trending leaderboards: $e');
      return [];
    }
  }

  /// Subscribes to leaderboard updates
  Future<bool> subscribeToLeaderboard({
    required String userId,
    required LeaderboardType type,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Subscribe to leaderboard functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error subscribing to leaderboard: $e');
      return false;
    }
  }

  /// Unsubscribes from leaderboard updates
  Future<bool> unsubscribeFromLeaderboard({
    required String userId,
    required LeaderboardType type,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Unsubscribe from leaderboard functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error unsubscribing from leaderboard: $e');
      return false;
    }
  }
} 