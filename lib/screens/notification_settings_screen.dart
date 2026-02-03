/// Notification Settings Screen
///
/// Screen for managing notification preferences including types, sound, vibration, and do not disturb.
/// Matches Figma design exactly.

import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const NotificationSettingsScreen({
    super.key,
    this.onBack,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _sound = true;
  bool _vibration = true;
  bool _doNotDisturb = false;
  TimeOfDay _dndStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dndEnd = const TimeOfDay(hour: 7, minute: 0);

  final Map<String, bool> _notificationTypes = {
    'hydration': true,
    'goals': true,
    'streaks': true,
    'tips': false,
  };

  final List<Map<String, dynamic>> _notificationTypeList = [
    {
      'id': 'hydration',
      'title': 'Hydration Reminders',
      'description': 'Get reminded to drink water',
    },
    {
      'id': 'goals',
      'title': 'Goal Achievements',
      'description': 'Celebrate when you reach your goals',
    },
    {
      'id': 'streaks',
      'title': 'Streak Milestones',
      'description': 'Track your consistency achievements',
    },
    {
      'id': 'tips',
      'title': 'Health Tips',
      'description': 'Get hydration tips and insights',
    },
  ];

  Future<void> _selectDndStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dndStart,
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
        _dndStart = picked;
      });
    }
  }

  Future<void> _selectDndEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dndEnd,
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
        _dndEnd = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  IconButton(
                    onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NeumorphicStyle.surfaceBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: NeumorphicStyle.primaryBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Settings',
                          style: NeumorphicStyle.neumorphicText(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your notification preferences',
                          style: NeumorphicStyle.neumorphicText(
                            fontSize: 14,
                            color: NeumorphicStyle.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Master Toggle
                    Container(
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
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _notificationsEnabled
                                  ? NeumorphicStyle.lightBlue
                                  : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _notificationsEnabled
                                  ? Icons.notifications
                                  : Icons.notifications_off,
                              color: _notificationsEnabled
                                  ? NeumorphicStyle.primaryBlue
                                  : NeumorphicStyle.lightText,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Notifications',
                                  style: NeumorphicStyle.neumorphicText(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Turn all notifications on/off',
                                  style: NeumorphicStyle.neumorphicText(
                                    fontSize: 14,
                                    color: NeumorphicStyle.lightText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                            activeColor: NeumorphicStyle.primaryBlue,
                          ),
                        ],
                      ),
                    ),

                    if (_notificationsEnabled) ...[
                      const SizedBox(height: 24),

                      // Notification Types
                      Text(
                        'Notification Types',
                        style: NeumorphicStyle.neumorphicText(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._notificationTypeList.map((type) {
                        final id = type['id'] as String;
                        final isEnabled = _notificationTypes[id] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type['title'] as String,
                                      style: NeumorphicStyle.neumorphicText(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      type['description'] as String,
                                      style: NeumorphicStyle.neumorphicText(
                                        fontSize: 14,
                                        color: NeumorphicStyle.lightText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _notificationTypes[id] = value;
                                  });
                                },
                                activeColor: NeumorphicStyle.primaryBlue,
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Alert Style
                      Text(
                        'Alert Style',
                        style: NeumorphicStyle.neumorphicText(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sound
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                                color: _sound
                                    ? NeumorphicStyle.lightBlue
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _sound ? Icons.volume_up : Icons.volume_off,
                                color: _sound
                                    ? NeumorphicStyle.primaryBlue
                                    : NeumorphicStyle.lightText,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sound',
                                    style: NeumorphicStyle.neumorphicText(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Play notification sound',
                                    style: NeumorphicStyle.neumorphicText(
                                      fontSize: 14,
                                      color: NeumorphicStyle.lightText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _sound,
                              onChanged: (value) {
                                setState(() {
                                  _sound = value;
                                });
                              },
                              activeColor: NeumorphicStyle.primaryBlue,
                            ),
                          ],
                        ),
                      ),

                      // Vibration
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                                color: _vibration
                                    ? NeumorphicStyle.lightBlue
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.vibration,
                                color: _vibration
                                    ? NeumorphicStyle.primaryBlue
                                    : NeumorphicStyle.lightText,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vibration',
                                    style: NeumorphicStyle.neumorphicText(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Vibrate on notifications',
                                    style: NeumorphicStyle.neumorphicText(
                                      fontSize: 14,
                                      color: NeumorphicStyle.lightText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _vibration,
                              onChanged: (value) {
                                setState(() {
                                  _vibration = value;
                                });
                              },
                              activeColor: NeumorphicStyle.primaryBlue,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Do Not Disturb
                      Text(
                        'Do Not Disturb',
                        style: NeumorphicStyle.neumorphicText(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
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
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _doNotDisturb
                                        ? NeumorphicStyle.lightBlue
                                        : Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.nightlight_round,
                                    color: _doNotDisturb
                                        ? NeumorphicStyle.primaryBlue
                                        : NeumorphicStyle.lightText,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quiet Hours',
                                        style: NeumorphicStyle.neumorphicText(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pause notifications during sleep',
                                        style: NeumorphicStyle.neumorphicText(
                                          fontSize: 14,
                                          color: NeumorphicStyle.lightText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _doNotDisturb,
                                  onChanged: (value) {
                                    setState(() {
                                      _doNotDisturb = value;
                                    });
                                  },
                                  activeColor: NeumorphicStyle.primaryBlue,
                                ),
                              ],
                            ),
                            if (_doNotDisturb) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: NeumorphicStyle.softBorder,
                                      width: 1,
                                    ),
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
                                            style: NeumorphicStyle.neumorphicText(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: NeumorphicStyle.lightText,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: _selectDndStartTime,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: NeumorphicStyle.surfaceBlue,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: NeumorphicStyle.softBorder,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    _formatTime(_dndStart),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: NeumorphicStyle.darkText,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.arrow_drop_down,
                                                    color: NeumorphicStyle.lightText,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
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
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: NeumorphicStyle.lightText,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: _selectDndEndTime,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: NeumorphicStyle.surfaceBlue,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: NeumorphicStyle.softBorder,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    _formatTime(_dndEnd),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: NeumorphicStyle.darkText,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.arrow_drop_down,
                                                    color: NeumorphicStyle.lightText,
                                                    size: 20,
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
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
