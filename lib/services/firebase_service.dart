/// Firebase Service
///
/// Centralized service for all Firebase operations including authentication,
/// Firestore database operations, and real-time updates.
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../models/friend.dart';
import '../models/challenge.dart';
import '../models/leaderboard.dart';

/// Centralized Firebase service for all app operations
class FirebaseService {
  static FirebaseService? _instance;
  factory FirebaseService() => _instance ??= FirebaseService._internal();
  FirebaseService._internal();

  // Firebase instances
  late firebase_auth.FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseAnalytics _analytics;
  late FirebaseFunctions _functions;

  /// Initialize Firebase services
  /// Note: Firebase.initializeApp() should already be called in main.dart
  /// This method just initializes the service instances
  Future<void> initialize() async {
    // Firebase must be initialized in main.dart before this service is used.
    // Avoiding fallback initializeApp() here prevents accidental init with
    // missing/default options in secondary startup paths.
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'FirebaseService.initialize called before Firebase.initializeApp in main().',
      );
    }
    _auth = firebase_auth.FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _analytics = FirebaseAnalytics.instance;
    _functions = FirebaseFunctions.instance;
  }

  /// Get current authenticated user
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of authentication state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // ==================== AUTHENTICATION ====================

  /// Sign in with email and password
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await _analytics.logLogin();
      return credential;
    } catch (e) {
      await _analytics.logEvent(
          name: 'login_error',
          parameters: <String, Object>{'error': e.toString()});
      rethrow;
    }
  }

  /// Create user with email and password
  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _analytics.logSignUp(signUpMethod: 'email');
      return credential;
    } catch (e) {
      await _analytics.logEvent(
          name: 'signup_error',
          parameters: <String, Object>{'error': e.toString()});
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _analytics.logEvent(name: 'logout');
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
    await _analytics.logEvent(name: 'password_reset_requested');
  }

  /// Requests a password reset verification code via Cloud Function
  Future<Map<String, dynamic>> requestPasswordResetCode(String email) async {
    final callable = _functions.httpsCallable('requestPasswordResetCode');
    final response = await callable.call(<String, dynamic>{'email': email});
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Verifies a password reset code and returns a reset session token
  Future<Map<String, dynamic>> verifyPasswordResetCode(
      String email, String code) async {
    final callable = _functions.httpsCallable('verifyPasswordResetCode');
    final response = await callable.call(<String, dynamic>{
      'email': email,
      'code': code,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Confirms password reset with a verified reset session token
  Future<Map<String, dynamic>> confirmPasswordResetWithCode({
    required String email,
    required String resetSessionToken,
    required String newPassword,
  }) async {
    final callable = _functions.httpsCallable('confirmPasswordResetWithCode');
    final response = await callable.call(<String, dynamic>{
      'email': email,
      'resetSessionToken': resetSessionToken,
      'newPassword': newPassword,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Fetches current weather via Cloud Function (OpenWeather key stays on server).
  /// Returns the OpenWeatherMap-shaped JSON map expected by [WeatherData.fromJson].
  Future<Map<String, dynamic>> getCurrentWeatherViaProxy({
    required double lat,
    required double lon,
    String units = 'metric',
  }) async {
    final callable = _functions.httpsCallable('getCurrentWeatherProxy');
    final response = await callable.call(<String, dynamic>{
      'lat': lat,
      'lon': lon,
      'units': units,
    });
    final map = Map<String, dynamic>.from(response.data as Map);
    final weather = map['weather'];
    if (weather is Map) {
      return Map<String, dynamic>.from(weather);
    }
    throw StateError('Invalid weather proxy response');
  }

  /// Sign in with Google (returns Firebase UserCredential)
  Future<firebase_auth.UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google sign-in was canceled',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    await _analytics.logLogin();
    return userCredential;
  }

  // ==================== USER MANAGEMENT ====================

  /// Create or update user profile
  Future<void> createOrUpdateUser(User user) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '[ProfilePersistence] Firestore.createOrUpdateUser: writing profile');
      }
      await _firestore.collection('users').doc(user.id).set(user.toJson());
      await _analytics.logEvent(name: 'user_profile_updated');
      if (kDebugMode) {
        debugPrint('[ProfilePersistence] Firestore.createOrUpdateUser: done');
      }
    } catch (e) {
      await _analytics.logEvent(
          name: 'user_profile_error',
          parameters: <String, Object>{'error': e.toString()});
      if (kDebugMode) {
        debugPrint(
            '[ProfilePersistence] Firestore.createOrUpdateUser error: $e');
      }
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = User.fromJson(doc.data()!);
        if (kDebugMode) {
          debugPrint('[ProfilePersistence] Firestore.getUser: profile loaded');
        }
        return user;
      }
      if (kDebugMode) {
        debugPrint(
            '[ProfilePersistence] Firestore.getUser: no profile document');
      }
      return null;
    } catch (e) {
      await _analytics.logEvent(
          name: 'get_user_error',
          parameters: <String, Object>{'error': e.toString()});
      if (kDebugMode) {
        debugPrint('[ProfilePersistence] Firestore.getUser error: $e');
      }
      rethrow;
    }
  }

  /// Delete user Firestore document and Firebase Auth account
  Future<void> deleteUserAccountData(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
    await _auth.currentUser?.delete();
    await _analytics.logEvent(name: 'account_deleted');
  }

  /// Search users by name or email
  Future<List<User>> searchUsers(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: queryLower)
          .where('name', isLessThan: '$queryLower\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
    } catch (e) {
      await _analytics.logEvent(
          name: 'search_users_error',
          parameters: <String, Object>{'error': e.toString()});
      rethrow;
    }
  }

  // ==================== FRIENDS SYSTEM ====================

  /// Send friend request
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    String? message,
  }) async {
    try {
      final request = {
        'id': _firestore.collection('friend_requests').doc().id,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'message': message ?? 'Hey! Let\'s stay hydrated together!',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('friend_requests').add(request);
      await _analytics.logEvent(name: 'friend_request_sent');
    } catch (e) {
      await _analytics.logEvent(
          name: 'friend_request_error',
          parameters: <String, Object>{'error': e.toString()});
      rethrow;
    }
  }

  /// Get pending friend requests
  Stream<List<FriendRequest>> getPendingFriendRequests(String userId) {
    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromJson(doc.data()))
            .toList());
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final batch = _firestore.batch();

      // Update request status
      final requestRef =
          _firestore.collection('friend_requests').doc(requestId);
      batch.update(requestRef, {'status': 'accepted'});

      // Get request details
      final requestDoc = await requestRef.get();
      final requestData = requestDoc.data()!;

      // Create friend relationships
      final fromUserId = requestData['fromUserId'] as String;
      final toUserId = requestData['toUserId'] as String;
      final fromUserName = requestData['fromUserName'] as String;

      // Add to friends collection
      final friendRef1 = _firestore.collection('friends').doc();
      batch.set(friendRef1, {
        'id': friendRef1.id,
        'userId': fromUserId,
        'friendId': toUserId,
        'friendName': 'User', // Will be updated with actual name
        'status': 'accepted',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final friendRef2 = _firestore.collection('friends').doc();
      batch.set(friendRef2, {
        'id': friendRef2.id,
        'userId': toUserId,
        'friendId': fromUserId,
        'friendName': fromUserName,
        'status': 'accepted',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      await _analytics.logEvent(name: 'friend_request_accepted');
    } catch (e) {
      await _analytics.logEvent(
          name: 'accept_friend_request_error',
          parameters: <String, Object>{'error': e.toString()});
      rethrow;
    }
  }

  /// Decline friend request
  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'declined',
      });
      await _analytics.logEvent(name: 'friend_request_declined');
    } catch (e) {
      await _analytics.logEvent(
          name: 'decline_friend_request_error',
          parameters: <String, Object>{'error': e.toString()});
      rethrow;
    }
  }

  /// Get user's friends
  Stream<List<Friend>> getUserFriends(String userId) {
    return _firestore
        .collection('friends')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snapshot) async {
      final friends = <Friend>[];
      for (final doc in snapshot.docs) {
        final friendData = doc.data();
        final friendUser = await getUser(friendData['friendId']);
        if (friendUser != null) {
          friends.add(Friend(
            id: doc.id,
            userId: userId,
            friendId: friendUser.id,
            friendName: friendUser.name ?? 'Unknown User',
            status: FriendStatus.accepted,
            createdAt: DateTime.now(),
          ));
        }
      }
      return friends;
    });
  }

  // ==================== CHALLENGES ====================

  /// Create new challenge
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
      final challengeRef = _firestore.collection('challenges').doc();
      final challenge = Challenge(
        id: challengeRef.id,
        title: title,
        description: description,
        type: type,
        startDate: startDate,
        endDate: endDate,
        rules: rules,
        createdBy: createdBy,
        createdByName: createdByName,
        status: ChallengeStatus.active,
        participants: participants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await challengeRef.set(challenge.toJson());

      // Add participants
      for (final participantId in participants) {
        await _firestore.collection('challenge_participants').add({
          'challengeId': challengeRef.id,
          'userId': participantId,
          'userName': 'User', // Will be updated with actual name
          'progress': {},
          'score': 0.0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }

      await _analytics.logEvent(
          name: 'challenge_created',
          parameters: <String, Object>{'challenge_type': type.toString()});
      return challenge;
    } catch (e) {
      await _analytics.logEvent(
          name: 'create_challenge_error',
          parameters: <String, Object>{'error': e.toString()});
      rethrow;
    }
  }

  /// Get user's challenges
  Stream<List<Challenge>> getUserChallenges(String userId) {
    return _firestore
        .collection('challenge_participants')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final challengeIds =
          snapshot.docs.map((doc) => doc.data()['challengeId']).toList();
      final challenges = <Challenge>[];

      for (final challengeId in challengeIds) {
        final challengeDoc =
            await _firestore.collection('challenges').doc(challengeId).get();
        if (challengeDoc.exists) {
          challenges.add(Challenge.fromJson(challengeDoc.data()!));
        }
      }

      return challenges;
    });
  }

  /// Get challenge participants
  Stream<List<ChallengeParticipant>> getChallengeParticipants(
      String challengeId) {
    return _firestore
        .collection('challenge_participants')
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('score', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChallengeParticipant.fromJson(doc.data()))
            .toList());
  }

  // ==================== LEADERBOARDS ====================

  /// Get global leaderboard
  Stream<Leaderboard?> getGlobalLeaderboard({
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
    int limit = 50,
  }) {
    return _firestore
        .collection('leaderboard_entries')
        .where('type', isEqualTo: 'global')
        .where('period', isEqualTo: period.index)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final entries = snapshot.docs
          .map((doc) => LeaderboardEntry.fromJson(doc.data()))
          .toList();

      return Leaderboard(
        id: 'global_${period.index}',
        title: 'Global Leaderboard',
        description: 'Global hydration leaderboard',
        type: LeaderboardType.global,
        period: period,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        entries: entries,
        totalParticipants: entries.length,
        lastUpdated: DateTime.now(),
      );
    });
  }

  /// Get streak leaderboard
  Stream<Leaderboard?> getStreakLeaderboard({int limit = 50}) {
    return _firestore
        .collection('leaderboard_entries')
        .where('type', isEqualTo: 'streak')
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final entries = snapshot.docs
          .map((doc) => LeaderboardEntry.fromJson(doc.data()))
          .toList();

      return Leaderboard(
        id: 'streak_alltime',
        title: 'Streak Leaderboard',
        description: 'Longest hydration streaks',
        type: LeaderboardType.streak,
        period: LeaderboardPeriod.allTime,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        entries: entries,
        totalParticipants: entries.length,
        lastUpdated: DateTime.now(),
      );
    });
  }

  /// Update user's leaderboard score
  Future<void> updateUserScore({
    required String userId,
    required double score,
    required Map<String, dynamic> stats,
    LeaderboardType type = LeaderboardType.global,
    LeaderboardPeriod period = LeaderboardPeriod.weekly,
  }) async {
    try {
      await _firestore.collection('leaderboard_entries').add({
        'userId': userId,
        'userName': 'User', // Will be updated with actual name
        'type': type.toString().split('.').last,
        'period': period.index,
        'score': score,
        'stats': stats,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'leaderboard_score_updated',
        parameters: <String, Object>{
          'score': score,
          'type': type.toString(),
          'period': period.toString(),
        },
      );
    } catch (e) {
      await _analytics.logEvent(
          name: 'update_score_error',
          parameters: <String, Object>{'error': e.toString()});
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Log custom analytics event
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Get Firestore instance for direct access
  FirebaseFirestore get firestore => _firestore;

  /// Get Auth instance for direct access
  firebase_auth.FirebaseAuth get auth => _auth;
}
