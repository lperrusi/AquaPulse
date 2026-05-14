/// Add Reminder Dialog
///
/// Dialog for creating new reminders with icon selection, time picker, and day selection.
/// Matches Figma design exactly.
// ignore_for_file: deprecated_member_use
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import '../utils/neumorphic_style.dart';

class AddReminderDialog extends StatefulWidget {
  final Function(Reminder) onSave;

  const AddReminderDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _titleController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  final List<String> _selectedDays = [];
  String _selectedIcon = 'bell';

  final List<Map<String, dynamic>> _icons = [
    {'value': 'bell', 'icon': Icons.notifications, 'label': 'Bell'},
    {'value': 'sun', 'icon': Icons.wb_sunny, 'label': 'Morning'},
    {'value': 'coffee', 'icon': Icons.local_cafe, 'label': 'Coffee'},
    {'value': 'utensils', 'icon': Icons.restaurant, 'label': 'Meal'},
    {'value': 'dumbbell', 'icon': Icons.fitness_center, 'label': 'Workout'},
    {'value': 'moon', 'icon': Icons.nightlight, 'label': 'Night'},
  ];

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {}); // Update button state when text changes
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: NeumorphicStyle.primaryBlue,
              onPrimary: Colors.white,
              onSurface: NeumorphicStyle.darkText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty || _selectedDays.isEmpty) {
      return;
    }

    // Convert day strings to numbers (Mon=1, Tue=2, ..., Sun=7)
    final daysOfWeek = _selectedDays.map((day) {
      return _weekDays.indexOf(day) + 1;
    }).toList();

    final reminder = Reminder(
      id: const Uuid().v4(),
      userId: 'current_user', // Will be set by the provider
      title: _titleController.text.trim(),
      message: 'Time to drink some water! 💧',
      time: _selectedTime,
      daysOfWeek: daysOfWeek,
      isActive: true,
    );

    widget.onSave(reminder);

    // Reset form
    _titleController.clear();
    _selectedTime = const TimeOfDay(hour: 8, minute: 0);
    _selectedDays.clear();
    _selectedIcon = 'bell';

    Navigator.of(context).pop();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 500,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: NeumorphicStyle.softBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Reminder',
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NeumorphicStyle.surfaceBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: NeumorphicStyle.lightText,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Reminder Name',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Morning Hydration',
                        filled: true,
                        fillColor: NeumorphicStyle.surfaceBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: NeumorphicStyle.softBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: NeumorphicStyle.softBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: NeumorphicStyle.primaryBlue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintStyle: TextStyle(
                          color: NeumorphicStyle.lightText,
                        ),
                      ),
                      style: TextStyle(
                        color: NeumorphicStyle.darkText,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Icon Selection
                    Text(
                      'Choose Icon',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75, // Reduced to allow more height
                      ),
                      itemCount: _icons.length,
                      itemBuilder: (context, index) {
                        final iconData = _icons[index];
                        final isSelected = _selectedIcon == iconData['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = iconData['value'] as String;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), // Reduced padding
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? NeumorphicStyle.lightBlue
                                  : NeumorphicStyle.surfaceBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? NeumorphicStyle.primaryBlue
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  iconData['icon'] as IconData,
                                  size: 20, // Reduced from 24 to 20
                                  color: isSelected
                                      ? NeumorphicStyle.primaryBlue
                                      : NeumorphicStyle.lightText,
                                ),
                                const SizedBox(height: 2), // Reduced from 4 to 2
                                Text(
                                  iconData['label'] as String,
                                  style: TextStyle(
                                    fontSize: 9, // Reduced from 10 to 9
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? NeumorphicStyle.primaryBlue
                                        : NeumorphicStyle.lightText,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: NeumorphicStyle.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Time',
                          style: NeumorphicStyle.neumorphicText(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: NeumorphicStyle.surfaceBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: NeumorphicStyle.softBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _formatTime(_selectedTime),
                              style: TextStyle(
                                fontSize: 16,
                                color: NeumorphicStyle.darkText,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_drop_down,
                              color: NeumorphicStyle.lightText,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Days
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: NeumorphicStyle.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Repeat On',
                          style: NeumorphicStyle.neumorphicText(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _weekDays.length,
                      itemBuilder: (context, index) {
                        final day = _weekDays[index];
                        final isSelected = _selectedDays.contains(day);
                        return GestureDetector(
                          onTap: () => _toggleDay(day),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? NeumorphicStyle.primaryBlue
                                  : NeumorphicStyle.surfaceBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : NeumorphicStyle.softBorder,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                day[0], // First letter
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : NeumorphicStyle.lightText,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedDays.clear();
                                _selectedDays.addAll(_weekDays);
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: NeumorphicStyle.lightBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Every Day',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: NeumorphicStyle.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedDays.clear();
                                _selectedDays.addAll(_weekDays.sublist(0, 5));
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: NeumorphicStyle.lightBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Weekdays',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: NeumorphicStyle.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Reduced vertical padding
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: NeumorphicStyle.softBorder,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _titleController.text.trim().isNotEmpty &&
                          _selectedDays.isNotEmpty
                      ? _handleSave
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _titleController.text.trim().isNotEmpty &&
                            _selectedDays.isNotEmpty
                        ? null
                        : NeumorphicStyle.mediumBorder,
                    disabledBackgroundColor: NeumorphicStyle.mediumBorder,
                    padding: EdgeInsets.zero, // Remove button padding, use container padding instead
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        if (states.contains(WidgetState.disabled)) {
                          return NeumorphicStyle.mediumBorder;
                        }
                        return Colors.transparent;
                      },
                    ),
                  ),
                  child: Container(
                    decoration: _titleController.text.trim().isNotEmpty &&
                            _selectedDays.isNotEmpty
                        ? BoxDecoration(
                            gradient: NeumorphicStyle.primaryGradient(),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          )
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 16 to 12
                    child: Text(
                      'Save Reminder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _titleController.text.trim().isNotEmpty &&
                                _selectedDays.isNotEmpty
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
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
}
