/// Water Intake Model
///
/// Defines the WaterIntake data model for logging water consumption events, and DailyWaterGoal for daily goal tracking and weather adjustment.
class WaterIntake {
  final String id;
  final String userId;
  final double amount; // in ml
  final DateTime timestamp;
  final String? note;

  WaterIntake({
    required this.id,
    required this.userId,
    required this.amount,
    required this.timestamp,
    this.note,
  });

  WaterIntake copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? timestamp,
    String? note,
  }) {
    return WaterIntake(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory WaterIntake.fromJson(Map<String, dynamic> json) {
    return WaterIntake(
      id: json['id'],
      userId: json['userId'],
      amount: json['amount'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'],
    );
  }
}

/// Represents a user's daily water goal, including optional weather-based adjustment.
class DailyWaterGoal {
  final String userId;
  final double targetAmount; // in ml
  final DateTime date;
  final double? weatherAdjustment; // percentage adjustment based on weather

  DailyWaterGoal({
    required this.userId,
    required this.targetAmount,
    required this.date,
    this.weatherAdjustment,
  });

  DailyWaterGoal copyWith({
    String? userId,
    double? targetAmount,
    DateTime? date,
    double? weatherAdjustment,
  }) {
    return DailyWaterGoal(
      userId: userId ?? this.userId,
      targetAmount: targetAmount ?? this.targetAmount,
      date: date ?? this.date,
      weatherAdjustment: weatherAdjustment ?? this.weatherAdjustment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'targetAmount': targetAmount,
      'date': date.toIso8601String(),
      'weatherAdjustment': weatherAdjustment,
    };
  }

  factory DailyWaterGoal.fromJson(Map<String, dynamic> json) {
    return DailyWaterGoal(
      userId: json['userId'],
      targetAmount: json['targetAmount'].toDouble(),
      date: DateTime.parse(json['date']),
      weatherAdjustment: json['weatherAdjustment']?.toDouble(),
    );
  }
} 