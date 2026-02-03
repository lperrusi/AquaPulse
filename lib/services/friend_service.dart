/// Friend Service
///
/// Handles friend relationships, friend requests, and social connections.
/// Manages friend discovery, requests, and relationship status using Firebase.

import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../models/user.dart';
import 'firebase_service.dart';

/// Service for managing friend relationships and social connections using Firebase
class FriendService {
  final FirebaseService _firebaseService = FirebaseService();
  static FriendService? _instance;
  factory FriendService() => _instance ??= FriendService._internal();
  FriendService._internal();

  /// Sends a friend request to another user
  Future<bool> sendFriendRequest({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String message,
  }) async {
    try {
      await _firebaseService.sendFriendRequest(
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        message: message,
      );
      return true;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return false;
    }
  }

  /// Accepts a friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      await _firebaseService.acceptFriendRequest(requestId);
      return true;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return false;
    }
  }

  /// Declines a friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      await _firebaseService.declineFriendRequest(requestId);
      return true;
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      return false;
    }
  }

  /// Gets all friends for a user (returns a stream for real-time updates)
  Stream<List<Friend>> getFriendsStream(String userId) {
    return _firebaseService.getUserFriends(userId);
  }

  /// Gets all friends for a user (one-time fetch)
  Future<List<Friend>> getFriends(String userId) async {
    try {
      return await _firebaseService.getUserFriends(userId).first;
    } catch (e) {
      debugPrint('Error getting friends: $e');
      return [];
    }
  }

  /// Gets pending friend requests for a user (returns a stream for real-time updates)
  Stream<List<FriendRequest>> getPendingRequestsStream(String userId) {
    return _firebaseService.getPendingFriendRequests(userId);
  }

  /// Gets pending friend requests for a user (one-time fetch)
  Future<List<FriendRequest>> getPendingRequests(String userId) async {
    try {
      return await _firebaseService.getPendingFriendRequests(userId).first;
    } catch (e) {
      debugPrint('Error getting pending requests: $e');
      return [];
    }
  }

  /// Searches for users by email or name
  Future<List<User>> searchUsers(String query) async {
    try {
      return await _firebaseService.searchUsers(query);
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Removes a friend
  Future<bool> removeFriend(String userId, String friendId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Remove friend functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return false;
    }
  }

  /// Blocks a user
  Future<bool> blockUser(String userId, String blockedUserId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Block user functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  /// Gets friend suggestions based on mutual friends and activity
  Future<List<User>> getFriendSuggestions(String userId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty list as this feature needs to be added
      debugPrint('Friend suggestions functionality needs to be implemented in FirebaseService');
      return [];
    } catch (e) {
      debugPrint('Error getting friend suggestions: $e');
      return [];
    }
  }

  /// Updates friend interaction timestamp
  Future<bool> updateFriendInteraction(String userId, String friendId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return false as this feature needs to be added
      debugPrint('Update friend interaction functionality needs to be implemented in FirebaseService');
      return false;
    } catch (e) {
      debugPrint('Error updating friend interaction: $e');
      return false;
    }
  }

  /// Gets friend activity feed
  Future<List<Map<String, dynamic>>> getFriendActivity(String userId) async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll return an empty list as this feature needs to be added
      debugPrint('Friend activity functionality needs to be implemented in FirebaseService');
      return [];
    } catch (e) {
      debugPrint('Error getting friend activity: $e');
      return [];
    }
  }

  /// Checks if two users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final friends = await getFriends(userId1);
      return friends.any((friend) => friend.id == userId2);
    } catch (e) {
      debugPrint('Error checking friend status: $e');
      return false;
    }
  }

  /// Gets friend statistics
  Future<Map<String, dynamic>> getFriendStats(String userId) async {
    try {
      final friends = await getFriends(userId);
      final pendingRequests = await getPendingRequests(userId);
      
      return {
        'totalFriends': friends.length,
        'pendingRequests': pendingRequests.length,
        'activeFriends': friends.where((f) => f.status == FriendStatus.accepted).length,
      };
    } catch (e) {
      debugPrint('Error getting friend stats: $e');
      return {};
    }
  }
} 