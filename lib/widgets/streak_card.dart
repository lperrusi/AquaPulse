/// Streak Card Widget
///
/// Displays the user's current hydration streak, achievement level, and next milestone.
/// Used on the dashboard to motivate users to maintain their hydration habit.

import 'package:flutter/material.dart';
import '../services/hydration_service.dart';
import '../utils/neumorphic_style.dart';

/// Widget that displays the current streak, achievement level, and next milestone.
class StreakCard extends StatelessWidget {
  final int streak;

  const StreakCard({
    super.key,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final achievementLevel = HydrationService.getAchievementLevel(streak);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicCard(),
      child: Row(
        children: [
          // Streak icon with neumorphic effect
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicStyle.neumorphicContainer(
              color: NeumorphicStyle.lightBlue,
              borderRadius: 16,
            ),
            child: Icon(
              _getStreakIcon(streak),
              color: NeumorphicStyle.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),

          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Streak',
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 14,
                    color: NeumorphicStyle.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$streak days',
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: NeumorphicStyle.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievementLevel,
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NeumorphicStyle.secondaryBlue,
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: NeumorphicStyle.neumorphicContainer(
                  color: NeumorphicStyle.surfaceBlue,
                  borderRadius: 12,
                  isElevated: false,
                ),
                child: Text(
                  '${_getNextMilestone(streak)}',
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeumorphicStyle.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Next Goal',
                style: NeumorphicStyle.neumorphicText(
                  fontSize: 12,
                  color: NeumorphicStyle.lightText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStreakIcon(int streak) {
    if (streak >= 30) return Icons.emoji_events;
    if (streak >= 21) return Icons.star;
    if (streak >= 14) return Icons.local_fire_department;
    if (streak >= 7) return Icons.whatshot;
    if (streak >= 3) return Icons.trending_up;
    return Icons.water_drop;
  }

  int _getNextMilestone(int streak) {
    if (streak < 3) return 3;
    if (streak < 7) return 7;
    if (streak < 14) return 14;
    if (streak < 21) return 21;
    if (streak < 30) return 30;
    if (streak < 60) return 60;
    if (streak < 100) return 100;
    return streak + 30; // Every 30 days after 100
  }
} 