/// Leaderboard Models
///
/// Defines leaderboard and ranking models for competitive features.
/// Handles different types of leaderboards, rankings, and competitive statistics.
library;

enum LeaderboardType {
  global,         // Global leaderboard
  friends,        // Friends-only leaderboard
  weekly,         // Weekly leaderboard
  monthly,        // Monthly leaderboard
  challenge,      // Challenge-specific leaderboard
  streak,         // Streak leaderboard
  totalIntake,    // Total intake leaderboard
}

enum LeaderboardPeriod {
  daily,          // Daily rankings
  weekly,         // Weekly rankings
  monthly,        // Monthly rankings
  allTime,        // All-time rankings
  custom,         // Custom period
}

/// Represents a leaderboard entry
class LeaderboardEntry {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rank;
  final double score;
  final Map<String, dynamic> stats; // Additional statistics
  final DateTime lastUpdated;
  final DateTime periodStart;
  final DateTime periodEnd;

  LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rank,
    required this.score,
    required this.stats,
    required this.lastUpdated,
    required this.periodStart,
    required this.periodEnd,
  });

  LeaderboardEntry copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    int? rank,
    double? score,
    Map<String, dynamic>? stats,
    DateTime? lastUpdated,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      stats: stats ?? this.stats,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rank': rank,
      'score': score,
      'stats': stats,
      'lastUpdated': lastUpdated.toIso8601String(),
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      rank: json['rank'] as int,
      score: (json['score'] as num).toDouble(),
      stats: Map<String, dynamic>.from(json['stats'] as Map<String, dynamic>),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
    );
  }
}

/// Represents a leaderboard
class Leaderboard {
  final String id;
  final String title;
  final String description;
  final LeaderboardType type;
  final LeaderboardPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final List<LeaderboardEntry> entries;
  final int totalParticipants;
  final DateTime lastUpdated;

  Leaderboard({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.entries,
    required this.totalParticipants,
    required this.lastUpdated,
  });

  Leaderboard copyWith({
    String? id,
    String? title,
    String? description,
    LeaderboardType? type,
    LeaderboardPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    List<LeaderboardEntry>? entries,
    int? totalParticipants,
    DateTime? lastUpdated,
  }) {
    return Leaderboard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      entries: entries ?? this.entries,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'period': period.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'totalParticipants': totalParticipants,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: LeaderboardType.values[json['type'] as int],
      period: LeaderboardPeriod.values[json['period'] as int],
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      entries: (json['entries'] as List)
          .map((entry) => LeaderboardEntry.fromJson(entry))
          .toList(),
      totalParticipants: json['totalParticipants'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Gets the top 3 entries
  List<LeaderboardEntry> get topThree {
    return entries.take(3).toList();
  }

  /// Gets the user's rank if they're in the leaderboard
  int? getUserRank(String userId) {
    final entry = entries.firstWhere(
      (entry) => entry.userId == userId,
      orElse: () => LeaderboardEntry(
        id: '',
        userId: '',
        userName: '',
        rank: 0,
        score: 0,
        stats: {},
        lastUpdated: DateTime.now(),
        periodStart: DateTime.now(),
        periodEnd: DateTime.now(),
      ),
    );
    return entry.userId.isNotEmpty ? entry.rank : null;
  }

  /// Checks if the leaderboard is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

/// Leaderboard factory for creating different types of leaderboards
class LeaderboardFactory {
  /// Creates a weekly leaderboard
  static Leaderboard createWeeklyLeaderboard({
    required String id,
    required String title,
    required String description,
    required DateTime weekStart,
    required List<LeaderboardEntry> entries,
  }) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return Leaderboard(
      id: id,
      title: title,
      description: description,
      type: LeaderboardType.weekly,
      period: LeaderboardPeriod.weekly,
      startDate: weekStart,
      endDate: weekEnd,
      entries: entries,
      totalParticipants: entries.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a monthly leaderboard
  static Leaderboard createMonthlyLeaderboard({
    required String id,
    required String title,
    required String description,
    required DateTime monthStart,
    required List<LeaderboardEntry> entries,
  }) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
    
    return Leaderboard(
      id: id,
      title: title,
      description: description,
      type: LeaderboardType.monthly,
      period: LeaderboardPeriod.monthly,
      startDate: monthStart,
      endDate: monthEnd,
      entries: entries,
      totalParticipants: entries.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a friends leaderboard
  static Leaderboard createFriendsLeaderboard({
    required String id,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required List<LeaderboardEntry> entries,
  }) {
    return Leaderboard(
      id: id,
      title: title,
      description: description,
      type: LeaderboardType.friends,
      period: LeaderboardPeriod.custom,
      startDate: startDate,
      endDate: endDate,
      entries: entries,
      totalParticipants: entries.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a streak leaderboard
  static Leaderboard createStreakLeaderboard({
    required String id,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required List<LeaderboardEntry> entries,
  }) {
    return Leaderboard(
      id: id,
      title: title,
      description: description,
      type: LeaderboardType.streak,
      period: LeaderboardPeriod.allTime,
      startDate: startDate,
      endDate: endDate,
      entries: entries,
      totalParticipants: entries.length,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Leaderboard statistics and analytics
class LeaderboardStats {
  final int totalParticipants;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final Map<String, int> scoreDistribution; // Score ranges and counts
  final DateTime lastUpdated;

  LeaderboardStats({
    required this.totalParticipants,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.scoreDistribution,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalParticipants': totalParticipants,
      'averageScore': averageScore,
      'highestScore': highestScore,
      'lowestScore': lowestScore,
      'scoreDistribution': scoreDistribution,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory LeaderboardStats.fromJson(Map<String, dynamic> json) {
    return LeaderboardStats(
      totalParticipants: json['totalParticipants'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      highestScore: (json['highestScore'] as num).toDouble(),
      lowestScore: (json['lowestScore'] as num).toDouble(),
      scoreDistribution: Map<String, int>.from(json['scoreDistribution'] as Map),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Calculates stats from a list of leaderboard entries
  factory LeaderboardStats.fromEntries(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) {
      return LeaderboardStats(
        totalParticipants: 0,
        averageScore: 0.0,
        highestScore: 0.0,
        lowestScore: 0.0,
        scoreDistribution: {},
        lastUpdated: DateTime.now(),
      );
    }

    final scores = entries.map((entry) => entry.score).toList();
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;
    final highestScore = scores.reduce((a, b) => a > b ? a : b);
    final lowestScore = scores.reduce((a, b) => a < b ? a : b);

    // Calculate score distribution
    final Map<String, int> distribution = {};
    for (final score in scores) {
      final range = _getScoreRange(score);
      distribution[range] = (distribution[range] ?? 0) + 1;
    }

    return LeaderboardStats(
      totalParticipants: entries.length,
      averageScore: averageScore,
      highestScore: highestScore,
      lowestScore: lowestScore,
      scoreDistribution: distribution,
      lastUpdated: DateTime.now(),
    );
  }

  static String _getScoreRange(double score) {
    if (score >= 1000) return '1000+';
    if (score >= 500) return '500-999';
    if (score >= 100) return '100-499';
    if (score >= 50) return '50-99';
    return '0-49';
  }
} 