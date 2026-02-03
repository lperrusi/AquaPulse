/// Friend Model
///
/// Defines friend relationships and social connections for the hydration tracker app.
/// Handles friend requests, status, and social interactions.

enum FriendStatus {
  pending,    // Friend request sent, waiting for response
  accepted,   // Friend request accepted
  declined,   // Friend request declined
  blocked,    // User blocked by friend
}

enum FriendRequestType {
  sent,       // Request sent by current user
  received,   // Request received by current user
}

/// Represents a friend relationship between users
class Friend {
  final String id;
  final String userId;
  final String friendId;
  final String friendName;
  final String? friendEmail;
  final String? friendAvatar;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? lastInteractionAt;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendName,
    this.friendEmail,
    this.friendAvatar,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.lastInteractionAt,
  });

  Friend copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? friendName,
    String? friendEmail,
    String? friendAvatar,
    FriendStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? lastInteractionAt,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      friendEmail: friendEmail ?? this.friendEmail,
      friendAvatar: friendAvatar ?? this.friendAvatar,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'friendName': friendName,
      'friendEmail': friendEmail,
      'friendAvatar': friendAvatar,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'lastInteractionAt': lastInteractionAt?.toIso8601String(),
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      userId: json['userId'] as String,
      friendId: json['friendId'] as String,
      friendName: json['friendName'] as String,
      friendEmail: json['friendEmail'] as String?,
      friendAvatar: json['friendAvatar'] as String?,
      status: FriendStatus.values[json['status'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null 
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      lastInteractionAt: json['lastInteractionAt'] != null 
          ? DateTime.parse(json['lastInteractionAt'] as String)
          : null,
    );
  }
}

/// Represents a friend request
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserEmail;
  final String? fromUserAvatar;
  final String toUserId;
  final String message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final FriendStatus? response;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserEmail,
    this.fromUserAvatar,
    required this.toUserId,
    required this.message,
    required this.createdAt,
    this.respondedAt,
    this.response,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
      'fromUserAvatar': fromUserAvatar,
      'toUserId': toUserId,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'response': response?.index,
    };
  }

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      fromUserEmail: json['fromUserEmail'] as String?,
      fromUserAvatar: json['fromUserAvatar'] as String?,
      toUserId: json['toUserId'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      response: json['response'] != null 
          ? FriendStatus.values[json['response'] as int]
          : null,
    );
  }
} 