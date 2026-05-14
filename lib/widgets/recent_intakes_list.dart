/// Recent Intakes List Widget
///
/// Displays a list of today's water intake entries, or an empty state if none exist.
/// Used on the dashboard to show recent hydration activity.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/water_intake.dart';
import '../utils/neumorphic_style.dart';

/// Widget that displays a list of recent water intakes for today, or an empty state.
class RecentIntakesList extends StatelessWidget {
  final List<WaterIntake> intakes;

  const RecentIntakesList({
    super.key,
    required this.intakes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Intake',
            style: NeumorphicStyle.neumorphicText(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          if (intakes.isEmpty)
            _buildEmptyState(context)
          else
            _buildIntakesList(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: NeumorphicStyle.neumorphicContainer(
        borderRadius: 16,
        isElevated: false,
      ),
      child: Column(
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 48,
            color: NeumorphicStyle.lightText,
          ),
          const SizedBox(height: 16),
          Text(
            'No water intake recorded today',
            style: NeumorphicStyle.neumorphicText(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: NeumorphicStyle.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your hydration journey by adding your first glass!',
            style: NeumorphicStyle.neumorphicText(
              fontSize: 14,
              color: NeumorphicStyle.lightText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIntakesList(BuildContext context) {
    return Column(
      children: [
        ...intakes.take(5).map((intake) => _buildIntakeTile(context, intake)),
        if (intakes.length > 5)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12.0),
            decoration: NeumorphicStyle.neumorphicContainer(
              borderRadius: 12,
              isElevated: false,
            ),
            child: Text(
              'And ${intakes.length - 5} more entries...',
              style: NeumorphicStyle.neumorphicText(
                fontSize: 12,
                color: NeumorphicStyle.lightText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildIntakeTile(BuildContext context, WaterIntake intake) {
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(intake.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: NeumorphicStyle.neumorphicContainer(
        borderRadius: 12,
        isElevated: false,
      ),
      child: Row(
        children: [
          // Water drop icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: NeumorphicStyle.neumorphicContainer(
              color: NeumorphicStyle.lightBlue,
              borderRadius: 8,
              isElevated: false,
            ),
            child: Icon(
              Icons.water_drop,
              color: NeumorphicStyle.primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          
          // Intake details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${intake.amount.round()} ml',
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (intake.note != null && intake.note!.isNotEmpty)
                  Text(
                    intake.note!,
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 12,
                      color: NeumorphicStyle.lightText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Time
          Text(
            timeString,
            style: NeumorphicStyle.neumorphicText(
              fontSize: 14,
              color: NeumorphicStyle.lightText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 