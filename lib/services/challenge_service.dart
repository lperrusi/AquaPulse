/// Challenge Service
///
/// Handles friend challenges, competitions, and challenge management.
/// Manages challenge creation, participation, progress tracking, and results using Firebase.

import 'package:flutter/foundation.dart';
import '../models/challenge.dart';
import 'firebase_service.dart';

/// Service for managing challenges and competitions using Firebase
class ChallengeService {
  final FirebaseService _firebaseService = FirebaseService();
  static ChallengeService? _instance;
  factory ChallengeService() => _instance ??= ChallengeService._internal();
  ChallengeService._internal();

  /// Creates a new challenge
  Future<Challenge?> createChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> rules,
    required List<String> participants,
    required String createdBy,
    required String createdByName,
  }) async {
    try {
      return await _firebaseService.createChallenge(
        title: title,
        description: description,
        type: type,
        startDate: startDate,
        endDate: endDate,
        rules: rules,
        participants: participants,
        createdBy: createdBy,
        createdByName: createdByName,
      );
    } catch (e) {
      debugPrint('Error creating challenge: $e');
      return null;
    }
  }

  /// Gets all challenges for a user (returns a stream for real-time updates)
  Stream<List<Challenge>> getUserChallengesStream(String userId) {
    return _firebaseService.getUserChallenges(userId);
  }

  /// Gets all challenges for a user (one-time fetch)
  Future<List<Challenge>> getUserChallenges(String userId) async {
    try {
      return await _firebaseService.getUserChallenges(userId).first;
    } catch (e) {
      debugPrint('Error getting user challenges: $e');
      return [];
    }
  }

  /// Gets active challenges for a user
  Future<List<Challenge>> getActiveChallenges(String userId) async {
    try {
      final allChallenges = await getUserChallenges(userId);
      final now = DateTime.now();
      return allChallenges.where((challenge) {
        return challenge.status == ChallengeStatus.active &&
               challenge.startDate.isBefore(now) &&
               challenge.endDate.isAfter(now);
      }).toList();
    } catch (e) {
      debugPrint('Error getting active challenges: $e');
      return [];
    }
  }

  /// Joins a challenge
  Future<bool> joinChallenge(String challengeId, String userId, String userName) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Join challenge functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error joining challenge: $e');
      return false;
    }
  }

  /// Leaves a challenge
  Future<bool> leaveChallenge(String challengeId, String userId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Leave challenge functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error leaving challenge: $e');
      return false;
    }
  }

  /// Gets challenge participants and their progress (returns a stream for real-time updates)
  Stream<List<ChallengeParticipant>> getChallengeParticipantsStream(String challengeId) {
    return _firebaseService.getChallengeParticipants(challengeId);
  }

  /// Gets challenge participants and their progress (one-time fetch)
  Future<List<ChallengeParticipant>> getChallengeParticipants(String challengeId) async {
    try {
      return await _firebaseService.getChallengeParticipants(challengeId).first;
    } catch (e) {
      debugPrint('Error getting challenge participants: $e');
      return [];
    }
  }

  /// Updates challenge progress for a participant
  Future<bool> updateChallengeProgress({
    required String challengeId,
    required String userId,
    required Map<String, dynamic> progress,
    required double score,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Update challenge progress functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error updating challenge progress: $e');
      return false;
    }
  }

  /// Gets challenge details
  Future<Challenge?> getChallenge(String challengeId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return null as this feature needs to be added
      debugPrint('Get challenge functionality needs to be implemented in FirebaseService');
      return null;
    } catch (e) {
      debugPrint('Error getting challenge: $e');
      return null;
    }
  }

  /// Starts a challenge (changes status from pending to active)
  Future<bool> startChallenge(String challengeId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Start challenge functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error starting challenge: $e');
      return false;
    }
  }

  /// Ends a challenge
  Future<bool> endChallenge(String challengeId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('End challenge functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error ending challenge: $e');
      return false;
    }
  }

  /// Gets challenge results
  Future<List<ChallengeParticipant>> getChallengeResults(String challengeId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty list as this feature needs to be added
      debugPrint('Get challenge results functionality needs to be implemented in FirebaseService');
      return [];
    } catch (e) {
      debugPrint('Error getting challenge results: $e');
      return [];
    }
  }

  /// Invites friends to a challenge
  Future<bool> inviteToChallenge({
    required String challengeId,
    required List<String> friendIds,
    required String message,
  }) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Invite to challenge functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error inviting to challenge: $e');
      return false;
    }
  }

  /// Gets challenge leaderboard
  Future<List<ChallengeParticipant>> getChallengeLeaderboard(String challengeId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty list as this feature needs to be added
      debugPrint('Get challenge leaderboard functionality needs to be implemented in FirebaseService');
      return [];
    } catch (e) {
      debugPrint('Error getting challenge leaderboard: $e');
      return [];
    }
  }

  /// Gets challenge statistics
  Future<Map<String, dynamic>> getChallengeStats(String challengeId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty map as this feature needs to be added
      debugPrint('Get challenge stats functionality needs to be implemented in FirebaseService');
      return {};
    } catch (e) {
      debugPrint('Error getting challenge stats: $e');
      return {};
    }
  }

  /// Calculates challenge score based on type and progress
  double calculateChallengeScore(ChallengeType type, Map<String, dynamic> progress) {
    switch (type) {
      case ChallengeType.dailyGoal:
        final goalMet = progress['goalMet'] as bool? ?? false;
        final daysCompleted = progress['daysCompleted'] as int? ?? 0;
        return goalMet ? daysCompleted * 100.0 : daysCompleted * 50.0;

      case ChallengeType.streak:
        final currentStreak = progress['currentStreak'] as int? ?? 0;
        final longestStreak = progress['longestStreak'] as int? ?? 0;
        return (currentStreak * 10.0) + (longestStreak * 5.0);

      case ChallengeType.totalIntake:
        final totalIntake = progress['totalIntake'] as double? ?? 0.0;
        final targetIntake = progress['targetIntake'] as double? ?? 1000.0;
        final progressPercentage = (totalIntake / targetIntake).clamp(0.0, 1.0);
        return progressPercentage * 1000.0;

      case ChallengeType.consistency:
        final goalDays = progress['goalDays'] as int? ?? 0;
        final totalDays = progress['totalDays'] as int? ?? 1;
        final consistencyRate = (goalDays / totalDays).clamp(0.0, 1.0);
        return consistencyRate * 1000.0;

      case ChallengeType.custom:
        final customScore = progress['customScore'] as double? ?? 0.0;
        return customScore;

      default:
        return 0.0;
    }
  }

  /// Gets challenge templates for quick creation
  Future<List<Map<String, dynamic>>> getChallengeTemplates() async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty list as this feature needs to be added
      debugPrint('Get challenge templates functionality needs to be implemented in FirebaseService');
      return [];
    } catch (e) {
      debugPrint('Error getting challenge templates: $e');
      return [];
    }
  }
} 