/// Reminders Screen
///
/// Allows users to view, add, edit, and delete hydration reminders. Integrates with local notifications and supports custom times and days.
/// Uses Riverpod for state management.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';
import '../providers/app_providers.dart';
import '../models/reminder.dart';
import '../widgets/smart_notification_suggestions.dart';
import '../widgets/add_reminder_dialog.dart';
import '../utils/neumorphic_style.dart';


/// The main RemindersScreen widget, which is a stateful consumer widget for managing hydration reminders.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

/// State class for RemindersScreen. Handles reminder CRUD operations, dialog management, and UI updates.
class _RemindersScreenState extends ConsumerState<RemindersScreen> with AutomaticKeepAliveClientMixin {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final List<int> _selectedDays = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  

  int _selectedIntervalMinutes = 120; // Default: 2 hours
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  bool _intervalEnabled = false; // State for interval reminder toggle
  bool _hasInitialized = false; // Track if we've initialized the state from reminders

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Hydration Reminder';
    _messageController.text = 'Time to drink some water! 💧';
    // Initialize interval enabled state based on existing reminders (only once on first load)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _initializeIntervalEnabledState();
        _hasInitialized = true;
      }
    });
  }

  /// Initializes the interval enabled state based on existing active interval reminders
  /// This only runs once on first load
  void _initializeIntervalEnabledState() {
    final reminders = ref.read(remindersProvider);
    final hasActiveIntervalReminder = reminders.any(
      (reminder) => reminder.isInterval && reminder.isActive,
    );
    if (mounted) {
      setState(() {
        _intervalEnabled = hasActiveIntervalReminder;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final reminders = ref.watch(remindersProvider);
    final remindersError = ref.watch(remindersErrorProvider);
    
    // Don't auto-update the toggle state in build - it should only be set:
    // 1. On initial load (in initState)
    // 2. When user manually toggles it
    // This prevents the toggle from resetting when switching tabs

    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue, // #FAFCFF
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // pb-24
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header - matches Figma: px-6 py-6
              Padding(
                padding: const EdgeInsets.all(24), // px-6 py-6
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminders',
                      style: TextStyle(
                        fontSize: 24, // text-2xl = 24px
                        fontWeight: FontWeight.bold,
                        color: NeumorphicStyle.darkText,
                      ),
                    ),
                    const SizedBox(height: 4), // mt-1 = 4px
                    Text(
                      'Never forget to stay hydrated',
                      style: TextStyle(
                        fontSize: 14, // text-sm = 14px
                        color: NeumorphicStyle.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content - matches Figma: px-6 space-y-6 max-w-2xl mx-auto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24), // px-6
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Interval Reminders - matches Figma
                    _buildIntervalRemindersCard(_intervalEnabled),
                    const SizedBox(height: 24), // space-y-6 = 24px
                    
                    // Quick Add - matches Figma
                    _buildQuickAddSection(),
                    const SizedBox(height: 24),
                    
                    // My Reminders - matches Figma
                    _buildRemindersList(reminders),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalRemindersCard(bool intervalEnabled) {
    return Container(
      padding: const EdgeInsets.all(20), // p-5 = 20px
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        boxShadow: [
          BoxShadow(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, // w-10 = 40px
                    height: 40,
                    decoration: BoxDecoration(
                      color: NeumorphicStyle.lightBlue, // #E8F4FD
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.access_time,
                      color: NeumorphicStyle.primaryBlue,
                      size: 20, // w-5 h-5 = 20px
                    ),
                  ),
                  const SizedBox(width: 12), // gap-3 = 12px
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interval Reminders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: NeumorphicStyle.darkText,
                        ),
                      ),
                      Text(
                        'Remind me every hour',
                        style: TextStyle(
                          fontSize: 14, // text-sm = 14px
                          color: NeumorphicStyle.lightText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: intervalEnabled,
                onChanged: (value) {
                  setState(() {
                    _intervalEnabled = value;
                  });
                },
                activeColor: NeumorphicStyle.primaryBlue,
              ),
            ],
          ),
          // Start/End time fields when enabled
          if (intervalEnabled) ...[
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: NeumorphicStyle.softBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: NeumorphicStyle.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (picked != null) {
                              setState(() {
                                _startTime = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12), // px-4 py-3
                            decoration: BoxDecoration(
                              color: NeumorphicStyle.surfaceBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: NeumorphicStyle.softBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTimeOfDay(_startTime),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: NeumorphicStyle.darkText,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: NeumorphicStyle.lightText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16), // gap-4 = 16px
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: NeumorphicStyle.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (picked != null) {
                              setState(() {
                                _endTime = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: NeumorphicStyle.surfaceBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: NeumorphicStyle.softBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTimeOfDay(_endTime),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: NeumorphicStyle.darkText,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: NeumorphicStyle.lightText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAddSection() {
    final quickAddButtons = [
      {'label': 'Morning', 'time': '8:00 AM', 'icon': Icons.wb_sunny},
      {'label': 'Lunch', 'time': '12:00 PM', 'icon': Icons.restaurant},
      {'label': 'Evening', 'time': '6:00 PM', 'icon': Icons.nights_stay},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Add',
          style: TextStyle(
            fontSize: 18, // text-lg = 18px
            fontWeight: FontWeight.w600, // font-semibold
            color: NeumorphicStyle.darkText,
          ),
        ),
        const SizedBox(height: 12), // mb-3 = 12px
        Row(
          children: quickAddButtons.map((button) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  final label = button['label'] as String;
                  final timeStr = button['time'] as String;
                  // Parse time string (e.g., "8:00 AM" or "12:00 PM")
                  final timeParts = timeStr.split(' ');
                  final time = timeParts[0].split(':');
                  final hour = int.parse(time[0]);
                  final minute = int.parse(time[1]);
                  final isPM = timeParts[1] == 'PM';
                  
                  final timeOfDay = TimeOfDay(
                    hour: isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour),
                    minute: minute,
                  );
                  
                  _addQuickReminder(
                    '$label Reminder',
                    'Time to drink water! 💧',
                    timeOfDay,
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: button == quickAddButtons.last ? 0 : 12, // gap-3 = 12px
                  ),
                  padding: const EdgeInsets.all(16), // p-4 = 16px
                  decoration: BoxDecoration(
                    color: NeumorphicStyle.lightBlue, // #E8F4FD
                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                    border: Border.all(
                      color: NeumorphicStyle.mediumBorder, // #B8D4F0
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48, // w-12 = 48px
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: NeumorphicStyle.primaryGradient(),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          button['icon'] as IconData,
                          color: Colors.white,
                          size: 24, // w-6 h-6 = 24px
                        ),
                      ),
                      const SizedBox(height: 12), // gap-3 = 12px
                      Text(
                        button['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: NeumorphicStyle.darkText,
                        ),
                      ),
                      Text(
                        button['time'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: NeumorphicStyle.lightText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRemindersList(List<Reminder> reminders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Reminders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: NeumorphicStyle.darkText,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: NeumorphicStyle.primaryGradient(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: () => _showAddReminderDialog(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text(
                  'Add New',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // mb-3 = 12px
        // Reminders list
        ...reminders.map((reminder) => _buildReminderCard(reminder, ref)),
      ],
    );
  }

  Widget _buildReminderCard(Reminder reminder, WidgetRef ref) {
    IconData icon;
    switch (reminder.title.toLowerCase()) {
      case 'morning hydration':
        icon = Icons.wb_sunny;
        break;
      case 'lunch break':
        icon = Icons.restaurant;
        break;
      case 'evening reminder':
        icon = Icons.nights_stay;
        break;
      default:
        icon = Icons.notifications;
    }

    final timeString = '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')} ${reminder.time.hour >= 12 ? 'PM' : 'AM'}';
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // space-y-3 = 12px
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: reminder.isActive ? NeumorphicStyle.lightBlue : NeumorphicStyle.surfaceBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: reminder.isActive ? NeumorphicStyle.primaryBlue : NeumorphicStyle.lightText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NeumorphicStyle.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 14,
                    color: NeumorphicStyle.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: reminder.daysOfWeek.map((dayIndex) {
                    // Reminder uses 1-based days (1=Monday), dayNames is 0-based
                    final dayName = dayNames[dayIndex - 1];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: reminder.isActive ? NeumorphicStyle.lightBlue : NeumorphicStyle.surfaceBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: reminder.isActive ? NeumorphicStyle.primaryBlue : NeumorphicStyle.lightText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: reminder.isActive,
                onChanged: (value) async {
                  final updatedReminder = reminder.copyWith(isActive: value);
                  await ref.read(remindersProvider.notifier).updateReminder(updatedReminder);
                },
                activeColor: NeumorphicStyle.primaryBlue,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) => EditReminderForm(reminder: reminder),
                      );
                    },
                    icon: Icon(
                      Icons.edit,
                      size: 18,
                      color: NeumorphicStyle.primaryBlue,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Reminder'),
                          content: Text('Are you sure you want to delete "${reminder.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
                                Navigator.pop(context);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reminder deleted')),
                                  );
                                }
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load reminders',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalRemindersSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeumorphicStyle.backgroundBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: NeumorphicStyle.primaryBlue.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and gradient
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interval Reminders',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: NeumorphicStyle.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get reminded at regular intervals',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 12,
                        color: NeumorphicStyle.lightText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildIntervalButton(
                  context,
                  icon: Icons.hourglass_empty,
                  label: 'Every Hour',
                  interval: '60 min',
                  onTap: () => _addIntervalReminder('Hourly Hydration', 'Time for a water break! 💧', 60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIntervalButton(
                  context,
                  icon: Icons.timer,
                  label: 'Every 2 Hours',
                  interval: '120 min',
                  onTap: () => _addIntervalReminder('2-Hour Hydration', 'Stay hydrated! Drink water! 🥤', 120),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIntervalButton(
                  context,
                  icon: Icons.access_time,
                  label: 'Custom',
                  interval: 'Custom',
                  onTap: () => _showIntervalReminderDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String interval,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NeumorphicStyle.primaryBlue.withOpacity(0.1),
                NeumorphicStyle.primaryBlue.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NeumorphicStyle.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: NeumorphicStyle.neumorphicText(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NeumorphicStyle.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                interval,
                style: NeumorphicStyle.neumorphicText(
                  fontSize: 10,
                  color: NeumorphicStyle.lightText,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtonsSection(BuildContext context, List<Reminder> reminders) {
    return Column(
      children: [
        // Smart Suggestions Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NeumorphicStyle.primaryBlue.withOpacity(0.1),
                NeumorphicStyle.primaryBlue.withOpacity(0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: NeumorphicStyle.primaryBlue.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showSmartSuggestionsDialog(context),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Smart Suggestions',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: NeumorphicStyle.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Your Reminders Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NeumorphicStyle.primaryBlue.withOpacity(0.1),
                NeumorphicStyle.primaryBlue.withOpacity(0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: NeumorphicStyle.primaryBlue.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showYourRemindersDialog(context, reminders),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.list_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Your Reminders (${reminders.length})',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: NeumorphicStyle.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateReminderButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showAddReminderDialog(context),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text(
          'Create Custom Reminder',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }









  Future<void> _addQuickReminder(String title, String message, TimeOfDay time) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final reminder = Reminder(
      id: const Uuid().v4(),
      userId: user.id,
      title: title,
      message: message,
      time: time,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Daily
      isActive: true,
      isInterval: false,
    );

    await ref.read(remindersProvider.notifier).addReminder(reminder);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $title reminder!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _addIntervalReminder(String title, String message, int intervalMinutes) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final reminder = Reminder(
      id: const Uuid().v4(),
      userId: user.id,
      title: title,
      message: message,
      time: _startTime,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Daily
      isActive: true,
      isInterval: true,
      intervalMinutes: intervalMinutes,
      startTime: _startTime,
      endTime: _endTime,
    );

    await ref.read(remindersProvider.notifier).addReminder(reminder);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $title interval reminder!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showIntervalReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: NeumorphicStyle.backgroundBlue,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildIntervalReminderForm(context),
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(
        onSave: (reminder) async {
          // Set the correct user ID
          final reminderWithUserId = Reminder(
            id: reminder.id,
            userId: user.id,
            title: reminder.title,
            message: reminder.message,
            time: reminder.time,
            daysOfWeek: reminder.daysOfWeek,
            isActive: reminder.isActive,
            isInterval: reminder.isInterval,
            intervalMinutes: reminder.intervalMinutes,
            startTime: reminder.startTime,
            endTime: reminder.endTime,
          );

          await ref.read(remindersProvider.notifier).addReminder(reminderWithUserId);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reminder added!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showReminderDialog(BuildContext context, Reminder? reminder) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: NeumorphicStyle.backgroundBlue,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildReminderForm(context, reminder),
        ),
      ),
    );
  }

  Widget _buildReminderForm(BuildContext context, Reminder? reminder) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon and title
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2196F3).withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      reminder == null ? 'Add Reminder' : 'Edit Reminder',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder == null ? 'Create a custom hydration reminder' : 'Update your reminder settings',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 14,
                        color: NeumorphicStyle.lightText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: NeumorphicStyle.neumorphicText(
                          fontSize: 14,
                          color: NeumorphicStyle.lightText,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: NeumorphicStyle.softBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: NeumorphicStyle.softBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: NeumorphicStyle.primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: NeumorphicStyle.surfaceBlue,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 16,
                        color: NeumorphicStyle.darkText,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        labelStyle: NeumorphicStyle.neumorphicText(
                          fontSize: 14,
                          color: NeumorphicStyle.lightText,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: NeumorphicStyle.softBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: NeumorphicStyle.softBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: NeumorphicStyle.primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: NeumorphicStyle.surfaceBlue,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 16,
                        color: NeumorphicStyle.darkText,
                      ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: NeumorphicStyle.surfaceBlue,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: NeumorphicStyle.softBorder,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                'Time',
                                style: NeumorphicStyle.neumorphicText(
                                  fontSize: 14,
                                  color: NeumorphicStyle.lightText,
                                ),
                              ),
                              subtitle: Text(
                                _selectedTime.format(context),
                                style: NeumorphicStyle.neumorphicText(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedTime,
                                );
                                if (time != null) {
                                  setState(() => _selectedTime = time);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDaysSelectorForDialog(setState),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: NeumorphicStyle.softBorder,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: NeumorphicStyle.neumorphicText(
                                      fontSize: 16,
                                      color: NeumorphicStyle.lightText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2196F3).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _saveReminder(reminder),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      reminder == null ? 'Add' : 'Save',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntervalReminderForm(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon and title
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2196F3).withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Custom Interval Reminder',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set up recurring reminders',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 14,
                        color: NeumorphicStyle.lightText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Title',
                              labelStyle: NeumorphicStyle.neumorphicText(
                                fontSize: 14,
                                color: NeumorphicStyle.lightText,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: NeumorphicStyle.softBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: NeumorphicStyle.softBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: NeumorphicStyle.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: NeumorphicStyle.surfaceBlue,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: NeumorphicStyle.neumorphicText(
                              fontSize: 16,
                              color: NeumorphicStyle.darkText,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              labelText: 'Message',
                              labelStyle: NeumorphicStyle.neumorphicText(
                                fontSize: 14,
                                color: NeumorphicStyle.lightText,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: NeumorphicStyle.softBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: NeumorphicStyle.softBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: NeumorphicStyle.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: NeumorphicStyle.surfaceBlue,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: NeumorphicStyle.neumorphicText(
                              fontSize: 16,
                              color: NeumorphicStyle.darkText,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          // Interval Selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Interval',
                                style: NeumorphicStyle.neumorphicText(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: NeumorphicStyle.darkText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                          value: _selectedIntervalMinutes,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: NeumorphicStyle.softBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: NeumorphicStyle.softBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: NeumorphicStyle.primaryBlue,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: NeumorphicStyle.surfaceBlue,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: NeumorphicStyle.neumorphicText(
                            fontSize: 16,
                            color: NeumorphicStyle.darkText,
                          ),
                          dropdownColor: NeumorphicStyle.surfaceBlue,
                          items: [
                            DropdownMenuItem(value: 30, child: Text('Every 30 minutes')),
                            DropdownMenuItem(value: 60, child: Text('Every hour')),
                            DropdownMenuItem(value: 90, child: Text('Every 1.5 hours')),
                            DropdownMenuItem(value: 120, child: Text('Every 2 hours')),
                            DropdownMenuItem(value: 180, child: Text('Every 3 hours')),
                            DropdownMenuItem(value: 240, child: Text('Every 4 hours')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedIntervalMinutes = value!;
                            });
                          },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Time Range
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Time',
                                    style: NeumorphicStyle.neumorphicText(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: NeumorphicStyle.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: NeumorphicStyle.surfaceBlue,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: NeumorphicStyle.softBorder,
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        _startTime.format(context),
                                        style: NeumorphicStyle.neumorphicText(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.access_time,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _startTime,
                                        );
                                        if (time != null) {
                                          setState(() => _startTime = time);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Time',
                                    style: NeumorphicStyle.neumorphicText(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: NeumorphicStyle.darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: NeumorphicStyle.surfaceBlue,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: NeumorphicStyle.softBorder,
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        _endTime.format(context),
                                        style: NeumorphicStyle.neumorphicText(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.access_time,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _endTime,
                                        );
                                        if (time != null) {
                                          setState(() => _endTime = time);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: NeumorphicStyle.softBorder,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: NeumorphicStyle.neumorphicText(
                                    fontSize: 16,
                                    color: NeumorphicStyle.lightText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2196F3).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () => _saveIntervalReminder(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDaysSelectorForDialog(Function setState) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Days',
          style: NeumorphicStyle.neumorphicText(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: NeumorphicStyle.darkText,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final dayNumber = index + 1;
            final isSelected = _selectedDays.contains(dayNumber);
            return FilterChip(
              label: Text(
                days[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : NeumorphicStyle.darkText,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(dayNumber);
                  } else {
                    _selectedDays.remove(dayNumber);
                  }
                });
              },
              selectedColor: NeumorphicStyle.primaryBlue,
              checkmarkColor: Colors.white,
              backgroundColor: NeumorphicStyle.surfaceBlue,
              side: BorderSide(
                color: isSelected
                    ? NeumorphicStyle.primaryBlue
                    : NeumorphicStyle.softBorder,
                width: isSelected ? 2 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _saveIntervalReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final newReminder = Reminder(
      id: const Uuid().v4(),
      userId: user.id,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      time: _startTime,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Daily for interval reminders
      isActive: true,
      isInterval: true,
      intervalMinutes: _selectedIntervalMinutes,
      startTime: _startTime,
      endTime: _endTime,
    );

    await ref.read(remindersProvider.notifier).addReminder(newReminder);
    Navigator.pop(context);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interval reminder added!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveReminder(Reminder? reminder) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final newReminder = Reminder(
      id: reminder?.id ?? const Uuid().v4(),
      userId: user.id,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      time: _selectedTime,
      daysOfWeek: _selectedDays,
      isActive: reminder?.isActive ?? true,
      isInterval: false,
    );

    if (reminder == null) {
      await ref.read(remindersProvider.notifier).addReminder(newReminder);
    } else {
      await ref.read(remindersProvider.notifier).updateReminder(newReminder);
    }

    Navigator.pop(context);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reminder == null ? 'Reminder added!' : 'Reminder updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSmartSuggestionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: NeumorphicStyle.backgroundBlue,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon and title
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD54F).withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Smart Suggestions',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalized reminder suggestions',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 14,
                        color: NeumorphicStyle.lightText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const SmartNotificationSuggestions(),
                ),
              ),
              // Close button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showYourRemindersDialog(BuildContext context, List<Reminder> reminders) {
    showDialog(
      context: context,
      builder: (context) => const RemindersDialog(),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _toggleReminder(WidgetRef ref, Reminder reminder, bool isActive) async {
    final updatedReminder = reminder.copyWith(isActive: isActive);
    await ref.read(remindersProvider.notifier).updateReminder(updatedReminder);
  }

  void _showEditReminderDialog(BuildContext context, WidgetRef ref, Reminder reminder) {
    // Show the edit dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EditReminderForm(reminder: reminder),
    );
  }

  void _showDeleteReminderDialog(BuildContext context, WidgetRef ref, Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
              Navigator.pop(context); // Close delete dialog
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

}

/// A ConsumerWidget for editing reminders
class EditReminderForm extends ConsumerStatefulWidget {
  final Reminder reminder;
  
  const EditReminderForm({super.key, required this.reminder});

  @override
  ConsumerState<EditReminderForm> createState() => _EditReminderFormState();
}

class _EditReminderFormState extends ConsumerState<EditReminderForm> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final List<int> _selectedDays = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.reminder.title;
    _messageController.text = widget.reminder.message;
    _selectedTime = widget.reminder.time;
    _selectedDays.addAll(widget.reminder.daysOfWeek);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Reminder',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(_selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() => _selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildDaysSelector(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _saveReminder(),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelector() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Days',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final dayNumber = index + 1;
            final isSelected = _selectedDays.contains(dayNumber);
            return FilterChip(
              label: Text(days[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(dayNumber);
                  } else {
                    _selectedDays.remove(dayNumber);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final updatedReminder = widget.reminder.copyWith(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      time: _selectedTime,
      daysOfWeek: _selectedDays,
    );

    await ref.read(remindersProvider.notifier).updateReminder(updatedReminder);
    Navigator.pop(context);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// A ConsumerWidget that displays the reminders dialog with real-time updates
class RemindersDialog extends ConsumerWidget {
  const RemindersDialog({super.key});

  static Future<void> _toggleReminder(WidgetRef ref, Reminder reminder, bool isActive) async {
    final updatedReminder = reminder.copyWith(isActive: isActive);
    await ref.read(remindersProvider.notifier).updateReminder(updatedReminder);
  }

  static void _showEditReminderDialog(BuildContext context, WidgetRef ref, Reminder reminder) {
    // Show the edit dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EditReminderForm(reminder: reminder),
    );
  }

  static void _showDeleteReminderDialog(BuildContext context, WidgetRef ref, Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
              Navigator.pop(context); // Close delete dialog
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: NeumorphicStyle.backgroundBlue,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with icon and title
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.list_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Reminders',
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reminders.length} ${reminders.length == 1 ? 'reminder' : 'reminders'}',
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 14,
                      color: NeumorphicStyle.lightText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            if (reminders.isEmpty)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No reminders yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your first reminder to get started!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: reminders.map((reminder) => 
                      _buildReminderCardForDialog(context, ref, reminder)
                    ).toList(),
                  ),
                ),
              ),
            // Close button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCardForDialog(BuildContext context, WidgetRef ref, Reminder reminder) {
    final theme = Theme.of(context);
    final time = reminder.time;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and switch
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: reminder.isActive 
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    reminder.isActive ? Icons.notifications_active : Icons.notifications_off,
                    color: reminder.isActive 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reminder.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: reminder.isActive,
                  onChanged: (value) => RemindersDialog._toggleReminder(ref, reminder, value),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Message
            if (reminder.message.isNotEmpty) ...[
              Text(
                reminder.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Time and days info
            Row(
              children: [
                Icon(
                  reminder.isInterval ? Icons.schedule : Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  reminder.isInterval 
                      ? 'Every ${_formatInterval(reminder.intervalMinutes!)}'
                      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    reminder.isInterval 
                        ? '${reminder.startTime?.format(context)} - ${reminder.endTime?.format(context)}'
                        : _formatDays(reminder.daysOfWeek),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => RemindersDialog._showEditReminderDialog(context, ref, reminder),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => RemindersDialog._showDeleteReminderDialog(context, ref, reminder),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDays(List<int> daysOfWeek) {
    if (daysOfWeek.length == 7) return 'Daily';
    if (daysOfWeek.length == 5 && daysOfWeek.every((d) => [1, 2, 3, 4, 5].contains(d))) return 'Weekdays';
    if (daysOfWeek.length == 2 && daysOfWeek.every((d) => [6, 7].contains(d))) return 'Weekends';
    
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return daysOfWeek.map((d) => dayNames[d - 1]).join(', ');
  }

  String _formatInterval(int minutes) {
    if (minutes < 60) {
      return '${minutes} minutes';
    } else if (minutes == 60) {
      return 'hour';
    } else if (minutes < 120) {
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hours';
    } else {
      final hours = minutes / 60;
      return '${hours.toInt()} hours';
    }
  }

} 