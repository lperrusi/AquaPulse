import 'package:flutter_test/flutter_test.dart';
import 'package:hydration_tracker/models/user.dart';
import 'package:hydration_tracker/models/water_intake.dart';
import 'package:hydration_tracker/services/hydration_service.dart';

void main() {
  group('HydrationService Tests', () {
    late User testUser;

    setUp(() {
      testUser = User(
        id: 'test-user',
        email: 'test@example.com',
        name: 'Test User',
        weight: 70.0, // 70kg
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('calculateBaseHydrationGoal', () {
      test('should calculate correct base goal for moderately active user', () {
        final goal = HydrationService.calculateBaseHydrationGoal(testUser);
        
        // Expected: 70kg * 32.5ml * 1.2 (moderately active multiplier)
        final expected = 70.0 * 32.5 * 1.2;
        expect(goal, equals(expected));
      });

      test('should calculate different goals for different activity levels', () {
        final sedentaryUser = testUser.copyWith(
          activityLevel: ActivityLevel.sedentary,
        );
        final veryActiveUser = testUser.copyWith(
          activityLevel: ActivityLevel.veryActive,
        );

        final sedentaryGoal = HydrationService.calculateBaseHydrationGoal(sedentaryUser);
        final veryActiveGoal = HydrationService.calculateBaseHydrationGoal(veryActiveUser);

        expect(veryActiveGoal, greaterThan(sedentaryGoal));
      });
    });

    group('calculateWeatherAdjustment', () {
      test('should return 1.0 for no weather data', () {
        final adjustment = HydrationService.calculateWeatherAdjustment();
        expect(adjustment, equals(1.0));
      });

      test('should increase adjustment for high temperature', () {
        final adjustment = HydrationService.calculateWeatherAdjustment(
          temperature: 30.0,
        );
        expect(adjustment, closeTo(1.2, 0.001)); // 1.0 + 0.1 + 0.1
      });

      test('should increase adjustment for high humidity', () {
        final adjustment = HydrationService.calculateWeatherAdjustment(
          humidity: 80.0,
        );
        expect(adjustment, closeTo(1.05, 0.001)); // 1.0 + 0.05
      });

      test('should combine temperature and humidity adjustments', () {
        final adjustment = HydrationService.calculateWeatherAdjustment(
          temperature: 28.0,
          humidity: 75.0,
        );
        expect(adjustment, closeTo(1.15, 0.001)); // 1.0 + 0.1 + 0.05
      });
    });

    group('calculateDailyGoal', () {
      test('should calculate goal with weather adjustment', () {
        final goal = HydrationService.calculateDailyGoal(
          testUser,
          temperature: 25.0,
          humidity: 60.0,
        );

        final baseGoal = HydrationService.calculateBaseHydrationGoal(testUser);
        final weatherAdjustment = HydrationService.calculateWeatherAdjustment(
          temperature: 25.0,
          humidity: 60.0,
        );
        final expected = baseGoal * weatherAdjustment;

        expect(goal, closeTo(expected, 0.001));
      });
    });

    group('calculateProgress', () {
      test('should calculate correct progress percentage', () {
        final progress = HydrationService.calculateProgress(1000.0, 2000.0);
        expect(progress, closeTo(0.5, 0.001));
      });

      test('should clamp progress to 1.0 when goal exceeded', () {
        final progress = HydrationService.calculateProgress(2500.0, 2000.0);
        expect(progress, closeTo(1.0, 0.001));
      });

      test('should return 0.0 for zero goal', () {
        final progress = HydrationService.calculateProgress(1000.0, 0.0);
        expect(progress, closeTo(0.0, 0.001));
      });
    });

    group('isGoalMet', () {
      test('should return true when intake meets goal', () {
        final isMet = HydrationService.isGoalMet(2000.0, 2000.0);
        expect(isMet, isTrue);
      });

      test('should return true when intake exceeds goal', () {
        final isMet = HydrationService.isGoalMet(2500.0, 2000.0);
        expect(isMet, isTrue);
      });

      test('should return false when intake below goal', () {
        final isMet = HydrationService.isGoalMet(1500.0, 2000.0);
        expect(isMet, isFalse);
      });
    });

    group('calculateRemaining', () {
      test('should calculate correct remaining amount', () {
        final remaining = HydrationService.calculateRemaining(1500.0, 2000.0);
        expect(remaining, closeTo(500.0, 0.001));
      });

      test('should return 0.0 when goal met', () {
        final remaining = HydrationService.calculateRemaining(2000.0, 2000.0);
        expect(remaining, closeTo(0.0, 0.001));
      });

      test('should return 0.0 when goal exceeded', () {
        final remaining = HydrationService.calculateRemaining(2500.0, 2000.0);
        expect(remaining, closeTo(0.0, 0.001));
      });
    });

    group('getHydrationStatus', () {
      test('should return correct status for different progress levels', () {
        expect(HydrationService.getHydrationStatus(1.0), contains('Goal achieved'));
        expect(HydrationService.getHydrationStatus(0.9), contains('Almost there'));
        expect(HydrationService.getHydrationStatus(0.7), contains('Good progress'));
        expect(HydrationService.getHydrationStatus(0.5), contains('Keep going'));
        expect(HydrationService.getHydrationStatus(0.3), contains('Getting started'));
        expect(HydrationService.getHydrationStatus(0.1), contains('Time to hydrate'));
      });
    });

    group('calculateWeeklyAverage', () {
      test('should calculate correct weekly average', () {
        final intakes = [
          WaterIntake(
            id: '1',
            userId: 'test',
            amount: 1000.0,
            timestamp: DateTime.now(),
          ),
          WaterIntake(
            id: '2',
            userId: 'test',
            amount: 1500.0,
            timestamp: DateTime.now(),
          ),
        ];

        final average = HydrationService.calculateWeeklyAverage(intakes);
        expect(average, closeTo(1250.0, 0.001));
      });

      test('should return 0.0 for empty list', () {
        final average = HydrationService.calculateWeeklyAverage([]);
        expect(average, closeTo(0.0, 0.001));
      });
    });

    group('getOptimalCupSize', () {
      test('should return optimal cup size', () {
        final availableSizes = [250.0, 500.0, 750.0];
        final remaining = 600.0;

        final optimalSize = HydrationService.getOptimalCupSize(remaining, availableSizes);
        expect(optimalSize, closeTo(500.0, 0.001));
      });

      test('should return smallest size when all sizes exceed remaining', () {
        final availableSizes = [500.0, 750.0];
        final remaining = 300.0;

        final optimalSize = HydrationService.getOptimalCupSize(remaining, availableSizes);
        expect(optimalSize, closeTo(500.0, 0.001));
      });

      test('should return default size for empty list', () {
        final optimalSize = HydrationService.getOptimalCupSize(500.0, []);
        expect(optimalSize, equals(250.0));
      });
    });

    group('calculateStreakImpact', () {
      test('should increment streak when goal met', () {
        final newStreak = HydrationService.calculateStreakImpact(true, 5);
        expect(newStreak, equals(6));
      });

      test('should reset streak when goal not met', () {
        final newStreak = HydrationService.calculateStreakImpact(false, 5);
        expect(newStreak, equals(0));
      });
    });

    group('getAchievementLevel', () {
      test('should return correct achievement levels', () {
        expect(HydrationService.getAchievementLevel(35), contains('Hydration Master'));
        expect(HydrationService.getAchievementLevel(25), contains('Consistency Champion'));
        expect(HydrationService.getAchievementLevel(15), contains('Week Warrior'));
        expect(HydrationService.getAchievementLevel(10), contains('Week Warrior'));
        expect(HydrationService.getAchievementLevel(5), contains('Getting Started'));
        expect(HydrationService.getAchievementLevel(1), contains('Newcomer'));
      });
    });

    group('getHealthTip', () {
      test('should return appropriate health tips', () {
        expect(
          HydrationService.getHealthTip(1.0, 2000.0, 2000.0),
          contains('Great job'),
        );
        expect(
          HydrationService.getHealthTip(0.9, 1800.0, 2000.0),
          contains('almost there'),
        );
        expect(
          HydrationService.getHealthTip(0.1, 200.0, 2000.0),
          contains('small goals'),
        );
      });
    });
  });
} 