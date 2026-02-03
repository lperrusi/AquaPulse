/// Streak Model
///
/// Defines the Streak data model for tracking hydration streaks, longest streaks, and achievement progress.
class Streak {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastGoalMet;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Streak({
    required this.id,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastGoalMet,
    required this.createdAt,
    required this.updatedAt,
  });

  Streak copyWith({
    String? id,
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastGoalMet,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Streak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastGoalMet: lastGoalMet ?? this.lastGoalMet,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_goal_met': lastGoalMet.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      lastGoalMet: DateTime.fromMillisecondsSinceEpoch(json['last_goal_met'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
    );
  }

  @override
  String toString() {
    return 'Streak(id: $id, userId: $userId, currentStreak: $currentStreak, longestStreak: $longestStreak, lastGoalMet: $lastGoalMet, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Streak &&
        other.id == id &&
        other.userId == userId &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.lastGoalMet == lastGoalMet &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        currentStreak.hashCode ^
        longestStreak.hashCode ^
        lastGoalMet.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
} 