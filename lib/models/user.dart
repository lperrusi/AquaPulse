/// User Model
///
/// Defines the User data model, including personal information, hydration preferences, and goal customization.
/// Also includes the ActivityLevel enum and extension for display and calculation logic.
class User {
  final String id;
  final String email;
  final String? name;
  final int? age;
  final double weight; // in kg
  final String? gender;
  final ActivityLevel activityLevel;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? customGoal;

  User({
    required this.id,
    required this.email,
    this.name,
    this.age,
    required this.weight,
    this.gender,
    required this.activityLevel,
    this.location,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.customGoal,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    double? weight,
    String? gender,
    ActivityLevel? activityLevel,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? customGoal,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customGoal: customGoal ?? this.customGoal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'weight': weight,
      'gender': gender,
      'activityLevel': activityLevel.index,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'customGoal': customGoal,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      age: json['age'] as int?,
      weight: json['weight'] as double,
      gender: json['gender'] as String?,
      activityLevel: ActivityLevel.values[json['activityLevel'] as int],
      location: json['location'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      customGoal: json['customGoal'] != null ? (json['customGoal'] as num).toDouble() : null,
    );
  }
}

/// Enum representing the user's activity level for hydration goal calculation.
enum ActivityLevel {
  sedentary,    // Little or no exercise
  lightlyActive, // Light exercise/sports 1-3 days/week
  moderatelyActive, // Moderate exercise/sports 3-5 days/week
  veryActive,   // Hard exercise/sports 6-7 days a week
  extremelyActive, // Very hard exercise, physical job
}

/// Extension for ActivityLevel to provide display names and multipliers.
extension ActivityLevelExtension on ActivityLevel {
  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.0;
      case ActivityLevel.lightlyActive:
        return 1.1;
      case ActivityLevel.moderatelyActive:
        return 1.2;
      case ActivityLevel.veryActive:
        return 1.3;
      case ActivityLevel.extremelyActive:
        return 1.4;
    }
  }
} 