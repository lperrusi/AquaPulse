/// Smart Notification Suggestions Widget
///
/// Displays intelligent notification timing suggestions based on user drinking patterns.
/// Shows optimal times for notifications and allows users to create reminders from suggestions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/notification_analytics_service.dart';
import '../models/reminder.dart';
import 'package:uuid/uuid.dart';

/// Widget that displays smart notification timing suggestions
class SmartNotificationSuggestions extends ConsumerStatefulWidget {
  const SmartNotificationSuggestions({super.key});

  @override
  ConsumerState<SmartNotificationSuggestions> createState() => _SmartNotificationSuggestionsState();
}

class _SmartNotificationSuggestionsState extends ConsumerState<SmartNotificationSuggestions> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    
    try {
      final intakes = ref.read(waterIntakeProvider);
      final analyticsService = NotificationAnalyticsService();
      final suggestions = await analyticsService.getSmartNotificationSuggestions(intakes);
      
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Smart Suggestions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Smart Suggestions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Not enough data yet. Keep using the app and responding to notifications to get personalized suggestions!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '💡 Tip: The more you use the app and respond to notifications, the smarter the suggestions become!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Smart Suggestions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSuggestions,
                  tooltip: 'Refresh suggestions',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your drinking patterns and notification response rates, here are the best times for reminders:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ..._suggestions.map((suggestion) => _buildSuggestionTile(context, suggestion)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, Map<String, dynamic> suggestion) {
    final theme = Theme.of(context);
    final hour = suggestion['hour'] as int;
    final message = suggestion['message'] as String;
    final responseRate = suggestion['responseRate'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Time and message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                ),
                if (responseRate > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 12,
                        color: responseRate > 0.5 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(responseRate * 100).toInt()}% response rate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: responseRate > 0.5 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'New suggestion - try it out!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Add reminder button
          IconButton(
            icon: const Icon(Icons.add_alarm),
            onPressed: () => _createReminderFromSuggestion(hour, message),
            tooltip: 'Create reminder',
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  void _createReminderFromSuggestion(int hour, String message) {
    final authService = ref.read(authServiceProvider);
    final userId = authService.currentUser?.id ?? 'default_user';
    
    final reminder = Reminder(
      id: const Uuid().v4(),
      userId: userId,
      title: 'Smart Hydration Reminder',
      message: message,
      time: TimeOfDay(hour: hour, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Every day
      isActive: true,
    );

    ref.read(remindersProvider.notifier).addReminder(reminder);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder created for ${hour.toString().padLeft(2, '0')}:00'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 