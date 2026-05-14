/// Challenge Models
///
/// Defines challenge and competition models for friend challenges and leaderboards.
/// Handles different types of challenges, progress tracking, and results.
library;

enum ChallengeType {
  dailyGoal,      // Daily goal completion challenge
  streak,         // Streak building challenge
  totalIntake,    // Total intake challenge
  consistency,    // Consistency challenge (meet goal X days in a row)
  custom,         // Custom challenge with specific rules
}

enum ChallengeStatus {
  pending,        // Challenge created, waiting for participants
  active,         // Challenge is currently running
  completed,      // Challenge has ended
  cancelled,      // Challenge was cancelled
}

enum ChallengeParticipantStatus {
  invited,        // User invited to challenge
  accepted,       // User accepted the challenge
  declined,       // User declined the challenge
  active,         // User is actively participating
  completed,      // User completed the challenge
  failed,         // User failed the challenge
}

/// Represents a challenge between friends
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeStatus status;
  final String createdBy;
  final String createdByName;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> rules; // Challenge-specific rules
  final List<String> participants; // User IDs
  final DateTime createdAt;
  final DateTime? updatedAt;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.startDate,
    required this.endDate,
    required this.rules,
    required this.participants,
    required this.createdAt,
    this.updatedAt,
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeStatus? status,
    String? createdBy,
    String? createdByName,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? rules,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rules: rules ?? this.rules,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'status': status.index,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'rules': rules,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeType.values[json['type'] as int],
      status: ChallengeStatus.values[json['status'] as int],
      createdBy: json['createdBy'] as String,
      createdByName: json['createdByName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      rules: Map<String, dynamic>.from(json['rules'] as Map),
      participants: List<String>.from(json['participants'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Gets the challenge duration in days
  int get durationInDays {
    return endDate.difference(startDate).inDays;
  }

  /// Checks if the challenge is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == ChallengeStatus.active && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }

  /// Gets the challenge progress percentage
  double get progressPercentage {
    if (status != ChallengeStatus.active) return 0.0;
    
    final now = DateTime.now();
    final totalDuration = endDate.difference(startDate).inDays;
    final elapsed = now.difference(startDate).inDays;
    
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }
}

/// Represents a participant's progress in a challenge
class ChallengeParticipant {
  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final ChallengeParticipantStatus status;
  final Map<String, dynamic> progress; // Challenge-specific progress data
  final double score; // Overall score/performance
  final int rank; // Current rank in the challenge
  final DateTime joinedAt;
  final DateTime? completedAt;

  ChallengeParticipant({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.status,
    required this.progress,
    required this.score,
    required this.rank,
    required this.joinedAt,
    this.completedAt,
  });

  ChallengeParticipant copyWith({
    String? id,
    String? challengeId,
    String? userId,
    String? userName,
    String? userAvatar,
    ChallengeParticipantStatus? status,
    Map<String, dynamic>? progress,
    double? score,
    int? rank,
    DateTime? joinedAt,
    DateTime? completedAt,
  }) {
    return ChallengeParticipant(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      joinedAt: joinedAt ?? this.joinedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'status': status.index,
      'progress': progress,
      'score': score,
      'rank': rank,
      'joinedAt': joinedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      status: ChallengeParticipantStatus.values[json['status'] as int],
      progress: Map<String, dynamic>.from(json['progress'] as Map),
      score: (json['score'] as num).toDouble(),
      rank: json['rank'] as int,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

/// Challenge factory for creating different types of challenges
class ChallengeFactory {
  /// Creates a daily goal challenge
  static Challenge createDailyGoalChallenge({
    required String id,
    required String title,
    required String description,
    required String createdBy,
    required String createdByName,
    required DateTime startDate,
    required DateTime endDate,
    required double targetGoal,
    required List<String> participants,
  }) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      type: ChallengeType.dailyGoal,
      status: ChallengeStatus.pending,
      createdBy: createdBy,
      createdByName: createdByName,
      startDate: startDate,
      endDate: endDate,
      rules: {
        'targetGoal': targetGoal,
        'goalType': 'daily',
        'measurement': 'ml',
      },
      participants: participants,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a streak challenge
  static Challenge createStreakChallenge({
    required String id,
    required String title,
    required String description,
    required String createdBy,
    required String createdByName,
    required DateTime startDate,
    required DateTime endDate,
    required int targetStreak,
    required List<String> participants,
  }) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      type: ChallengeType.streak,
      status: ChallengeStatus.pending,
      createdBy: createdBy,
      createdByName: createdByName,
      startDate: startDate,
      endDate: endDate,
      rules: {
        'targetStreak': targetStreak,
        'streakType': 'consecutive',
        'goalRequired': true,
      },
      participants: participants,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a total intake challenge
  static Challenge createTotalIntakeChallenge({
    required String id,
    required String title,
    required String description,
    required String createdBy,
    required String createdByName,
    required DateTime startDate,
    required DateTime endDate,
    required double targetIntake,
    required List<String> participants,
  }) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      type: ChallengeType.totalIntake,
      status: ChallengeStatus.pending,
      createdBy: createdBy,
      createdByName: createdByName,
      startDate: startDate,
      endDate: endDate,
      rules: {
        'targetIntake': targetIntake,
        'measurement': 'ml',
        'period': 'total',
      },
      participants: participants,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a consistency challenge
  static Challenge createConsistencyChallenge({
    required String id,
    required String title,
    required String description,
    required String createdBy,
    required String createdByName,
    required DateTime startDate,
    required DateTime endDate,
    required int targetDays,
    required List<String> participants,
  }) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      type: ChallengeType.consistency,
      status: ChallengeStatus.pending,
      createdBy: createdBy,
      createdByName: createdByName,
      startDate: startDate,
      endDate: endDate,
      rules: {
        'targetDays': targetDays,
        'goalRequired': true,
        'consecutive': false,
      },
      participants: participants,
      createdAt: DateTime.now(),
    );
  }
} 