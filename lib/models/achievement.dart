/// Achievement Model
///
/// Defines achievement data for tracking user accomplishments and social sharing.
/// Includes various types of achievements and their unlock conditions.

enum AchievementType {
  streak,      // Streak-based achievements
  goal,        // Goal completion achievements
  milestone,   // Milestone achievements (total intake, etc.)
  social,      // Social achievements
  special,     // Special event achievements
}

enum AchievementTier {
  bronze,   // Basic achievements
  silver,   // Intermediate achievements
  gold,     // Advanced achievements
  platinum, // Master achievements
  diamond,  // Legendary achievements
}

/// Represents a user achievement with metadata and social sharing capabilities
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final AchievementTier tier;
  final int requirement; // Value needed to unlock
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final String? shareMessage;
  final String? shareImageUrl;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.tier,
    required this.requirement,
    this.unlockedAt,
    this.isUnlocked = false,
    this.shareMessage,
    this.shareImageUrl,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    AchievementTier? tier,
    int? requirement,
    DateTime? unlockedAt,
    bool? isUnlocked,
    String? shareMessage,
    String? shareImageUrl,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      requirement: requirement ?? this.requirement,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      shareMessage: shareMessage ?? this.shareMessage,
      shareImageUrl: shareImageUrl ?? this.shareImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.index,
      'tier': tier.index,
      'requirement': requirement,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
      'shareMessage': shareMessage,
      'shareImageUrl': shareImageUrl,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: AchievementType.values[json['type'] as int],
      tier: AchievementTier.values[json['tier'] as int],
      requirement: json['requirement'] as int,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      shareMessage: json['shareMessage'] as String?,
      shareImageUrl: json['shareImageUrl'] as String?,
    );
  }

  /// Gets the default share message for this achievement
  String get defaultShareMessage {
    if (shareMessage != null) return shareMessage!;
    
    switch (type) {
      case AchievementType.streak:
        return '🔥 I just achieved a $requirement-day hydration streak! #HydrationTracker';
      case AchievementType.goal:
        return '🎯 I met my daily hydration goal! #StayHydrated';
      case AchievementType.milestone:
        return '🏆 I reached a hydration milestone! #HydrationGoals';
      case AchievementType.social:
        return '👥 I completed a social hydration challenge! #HydrationCommunity';
      case AchievementType.special:
        return '⭐ I unlocked a special hydration achievement! #HydrationTracker';
    }
  }

  /// Gets the tier color for UI display
  String get tierColor {
    switch (tier) {
      case AchievementTier.bronze:
        return '#CD7F32';
      case AchievementTier.silver:
        return '#C0C0C0';
      case AchievementTier.gold:
        return '#FFD700';
      case AchievementTier.platinum:
        return '#E5E4E2';
      case AchievementTier.diamond:
        return '#B9F2FF';
    }
  }

  /// Gets the tier name for display
  String get tierName {
    switch (tier) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.diamond:
        return 'Diamond';
    }
  }
}

/// Predefined achievements for the app
class AchievementDefinitions {
  static List<Achievement> get allAchievements => [
    // Streak achievements
    Achievement(
      id: 'streak_3',
      title: 'Getting Started',
      description: 'Maintain a 3-day hydration streak',
      icon: '🔥',
      type: AchievementType.streak,
      tier: AchievementTier.bronze,
      requirement: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintain a 7-day hydration streak',
      icon: '🔥',
      type: AchievementType.streak,
      tier: AchievementTier.silver,
      requirement: 7,
    ),
    Achievement(
      id: 'streak_14',
      title: 'Fortnight Fighter',
      description: 'Maintain a 14-day hydration streak',
      icon: '🔥',
      type: AchievementType.streak,
      tier: AchievementTier.gold,
      requirement: 14,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Hydration Master',
      description: 'Maintain a 30-day hydration streak',
      icon: '🔥',
      type: AchievementType.streak,
      tier: AchievementTier.platinum,
      requirement: 30,
    ),
    Achievement(
      id: 'streak_100',
      title: 'Century Champion',
      description: 'Maintain a 100-day hydration streak',
      icon: '🔥',
      type: AchievementType.streak,
      tier: AchievementTier.diamond,
      requirement: 100,
    ),

    // Goal achievements
    Achievement(
      id: 'goal_7',
      title: 'Goal Getter',
      description: 'Meet your daily goal 7 days in a row',
      icon: '🎯',
      type: AchievementType.goal,
      tier: AchievementTier.bronze,
      requirement: 7,
    ),
    Achievement(
      id: 'goal_30',
      title: 'Goal Guardian',
      description: 'Meet your daily goal 30 days in a row',
      icon: '🎯',
      type: AchievementType.goal,
      tier: AchievementTier.silver,
      requirement: 30,
    ),

    // Milestone achievements
    Achievement(
      id: 'total_1000',
      title: 'Thirst Quencher',
      description: 'Drink 1,000ml of water total',
      icon: '💧',
      type: AchievementType.milestone,
      tier: AchievementTier.bronze,
      requirement: 1000,
    ),
    Achievement(
      id: 'total_10000',
      title: 'Water Warrior',
      description: 'Drink 10,000ml of water total',
      icon: '💧',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      requirement: 10000,
    ),
    Achievement(
      id: 'total_100000',
      title: 'Hydration Hero',
      description: 'Drink 100,000ml of water total',
      icon: '💧',
      type: AchievementType.milestone,
      tier: AchievementTier.gold,
      requirement: 100000,
    ),
  ];

  /// Gets achievements by type
  static List<Achievement> getByType(AchievementType type) {
    return allAchievements.where((achievement) => achievement.type == type).toList();
  }

  /// Gets achievements by tier
  static List<Achievement> getByTier(AchievementTier tier) {
    return allAchievements.where((achievement) => achievement.tier == tier).toList();
  }

  /// Gets unlocked achievements
  static List<Achievement> getUnlocked(List<Achievement> achievements) {
    return achievements.where((achievement) => achievement.isUnlocked).toList();
  }

  /// Gets locked achievements
  static List<Achievement> getLocked(List<Achievement> achievements) {
    return achievements.where((achievement) => !achievement.isUnlocked).toList();
  }
} 