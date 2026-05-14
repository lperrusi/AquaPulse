/// Hydration Service
///
/// Provides business logic for hydration goal calculation, progress tracking, streaks, and health tips.
/// Centralizes all hydration-related algorithms and utilities for the app.
library;

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/water_intake.dart';
import 'weather_service.dart';

/// Service class for hydration goal calculation, progress, streaks, and health tips.
class HydrationService {
  /// Calculates the base daily hydration goal (in ml) based on user weight and activity level.
  ///
  /// [user] - The user whose goal is being calculated.
  /// Returns the base hydration goal in milliliters.
  static double calculateBaseHydrationGoal(User user) {
    // Base formula: 30-35ml per kg of body weight
    double baseAmount = user.weight * 32.5; // 32.5ml per kg
    
    // Apply activity level multiplier
    baseAmount *= user.activityLevel.multiplier;
    
    return baseAmount;
  }

  /// Calculates a weather-based adjustment factor for hydration needs.
  ///
  /// [temperature] - Optional temperature in Celsius.
  /// [humidity] - Optional humidity percentage.
  /// [location] - Optional location string.
  /// Returns a multiplier (e.g., 1.1 for 10% increase).
  static double calculateWeatherAdjustment({
    double? temperature,
    double? humidity,
    String? location,
  }) {
    // Default adjustment factor
    double adjustment = 1.0;
    
    if (temperature != null) {
      // Increase hydration for high temperatures
      if (temperature > 25) {
        adjustment += 0.1; // 10% increase for temperatures above 25°C
      }
      if (temperature >= 30) {
        adjustment += 0.1; // Additional 10% for temperatures at or above 30°C
      }
    }
    
    if (humidity != null) {
      // Increase hydration for high humidity
      if (humidity > 70) {
        adjustment += 0.05; // 5% increase for humidity above 70%
      }
    }
    
    return adjustment;
  }

  /// Calculates the final daily hydration goal, including weather adjustment.
  ///
  /// [user] - The user whose goal is being calculated.
  /// [weatherData] - Optional weather data for automatic adjustment.
  /// [temperature], [humidity], [location] - Optional weather/location data (legacy support).
  /// Returns the final daily goal in milliliters.
  static double calculateDailyGoal(User user, {
    WeatherData? weatherData,
    double? temperature,
    double? humidity,
    String? location,
  }) {
    double baseGoal = calculateBaseHydrationGoal(user);
    
    // Use weather data if available, otherwise use legacy parameters
    double weatherAdjustment;
    if (weatherData != null) {
      final weatherService = WeatherService();
      weatherAdjustment = weatherService.calculateWeatherAdjustment(weatherData);
    } else {
      weatherAdjustment = calculateWeatherAdjustment(
        temperature: temperature,
        humidity: humidity,
        location: location,
      );
    }
    
    return baseGoal * weatherAdjustment;
  }

  /// Calculates the progress percentage toward the daily goal.
  ///
  /// [currentIntake] - The amount of water consumed so far (ml).
  /// [goal] - The daily goal (ml).
  /// Returns a value between 0.0 and 1.0.
  static double calculateProgress(double currentIntake, double goal) {
    if (goal <= 0) return 0.0;
    return (currentIntake / goal).clamp(0.0, 1.0);
  }

  /// Returns true if the daily goal has been met or exceeded.
  ///
  /// [currentIntake] - The amount of water consumed so far (ml).
  /// [goal] - The daily goal (ml).
  static bool isGoalMet(double currentIntake, double goal) {
    return currentIntake >= goal;
  }

  /// Calculates the remaining amount needed to reach the daily goal.
  ///
  /// [currentIntake] - The amount of water consumed so far (ml).
  /// [goal] - The daily goal (ml).
  /// Returns the remaining amount in milliliters.
  static double calculateRemaining(double currentIntake, double goal) {
    return (goal - currentIntake).clamp(0.0, goal);
  }

  /// Returns a hydration status message based on progress.
  ///
  /// [progress] - The progress percentage (0.0 to 1.0).
  static String getHydrationStatus(double progress) {
    if (progress >= 1.0) {
      return 'Goal achieved! 🎉';
    } else if (progress >= 0.8) {
      return 'Almost there! 💪';
    } else if (progress >= 0.6) {
      return 'Good progress! 👍';
    } else if (progress >= 0.4) {
      return 'Keep going! 💧';
    } else if (progress >= 0.2) {
      return 'Getting started! 🌊';
    } else {
      return 'Time to hydrate! 💦';
    }
  }

  /// Calculates the average daily intake for a week.
  ///
  /// [weeklyIntakes] - List of WaterIntake objects for the week.
  /// Returns the average intake per day in milliliters.
  static double calculateWeeklyAverage(List<WaterIntake> weeklyIntakes) {
    if (weeklyIntakes.isEmpty) return 0.0;
    
    double totalAmount = weeklyIntakes.fold(0.0, (sum, intake) => sum + intake.amount);
    return totalAmount / weeklyIntakes.length; // Mean of provided intakes
  }

  /// Returns a list of recommended intake times (for future AI-based reminders).
  static List<TimeOfDay> getRecommendedIntakeTimes() {
    return [
      const TimeOfDay(hour: 8, minute: 0),   // Morning
      const TimeOfDay(hour: 10, minute: 0),  // Mid-morning
      const TimeOfDay(hour: 12, minute: 0),  // Lunch
      const TimeOfDay(hour: 14, minute: 0),  // Afternoon
      const TimeOfDay(hour: 16, minute: 0),  // Mid-afternoon
      const TimeOfDay(hour: 18, minute: 0),  // Evening
      const TimeOfDay(hour: 20, minute: 0),  // Night
    ];
  }

  /// Returns the optimal cup size from available sizes based on remaining goal.
  ///
  /// [remaining] - The remaining amount to reach the goal (ml).
  /// [availableSizes] - List of available cup sizes (ml).
  /// Returns the optimal cup size in milliliters.
  static double getOptimalCupSize(double remaining, List<double> availableSizes) {
    if (availableSizes.isEmpty) return 250.0; // Default size
    
    // Find the largest cup size that does not exceed remaining amount
    availableSizes.sort();
    double? best;
    for (double size in availableSizes) {
      if (size <= remaining) {
        best = size;
      }
    }
    if (best != null) return best;
    // If all sizes are too large, return the smallest
    return availableSizes.first;
  }

  /// Returns a health tip string based on progress and goal.
  ///
  /// [progress] - The progress percentage (0.0 to 1.0).
  /// [currentIntake] - The amount of water consumed so far (ml).
  /// [goal] - The daily goal (ml).
  static String getHealthTip(double progress, double currentIntake, double goal) {
    if (progress >= 1.0) {
      return 'Great job! Remember to maintain consistency.';
    } else if (progress >= 0.8) {
      return 'You\'re almost there! One more glass should do it.';
    } else if (progress >= 0.6) {
      return 'Good progress! Try to drink water with every meal.';
    } else if (progress >= 0.4) {
      return 'Keep a water bottle nearby to remind yourself to drink.';
    } else if (progress >= 0.2) {
      return 'Start your day with a glass of water to boost metabolism.';
    } else {
      return 'Set small goals - even one glass is a good start!';
    }
  }

  /// Calculates the new streak value based on whether the goal was met.
  ///
  /// [goalMet] - True if the daily goal was met.
  /// [currentStreak] - The user's current streak.
  /// Returns the updated streak value.
  static int calculateStreakImpact(bool goalMet, int currentStreak) {
    if (goalMet) {
      return currentStreak + 1;
    } else {
      return 0; // Reset streak
    }
  }

  /// Returns the achievement level string based on the user's streak.
  ///
  /// [streak] - The user's current streak.
  static String getAchievementLevel(int streak) {
    if (streak >= 30) return 'Hydration Master! 🏆';
    if (streak >= 21) return 'Consistency Champion! 🥇';
    if (streak >= 14) return 'Week Warrior! 🥈';
    if (streak >= 7) return 'Week Warrior! 🥉';
    if (streak >= 3) return 'Getting Started! 🌟';
    return 'Newcomer! 🌱';
  }
}

/// Extension for TimeOfDay to provide display formatting and comparison helpers.
extension TimeOfDayExtension on TimeOfDay {
  /// Returns the time as a formatted string (HH:mm).
  String get displayTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  
  /// Returns the total minutes since midnight.
  int get totalMinutes => hour * 60 + minute;
  
  /// Returns true if this time is after [other].
  bool isAfter(TimeOfDay other) {
    return totalMinutes > other.totalMinutes;
  }
  
  /// Returns true if this time is before [other].
  bool isBefore(TimeOfDay other) {
    return totalMinutes < other.totalMinutes;
  }
} 