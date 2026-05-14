/// Profile Screen
///
/// This screen allows the user to view and update their personal information, including name, weight, activity level, and hydration goal.
/// It also displays user statistics and provides a logout option. Uses Riverpod for state management.
// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_element, unused_local_variable
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';
import '../config/app_capabilities.dart';
import '../config/app_urls.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import 'notification_settings_screen.dart';
import '../utils/neumorphic_style.dart';

/// The main ProfileScreen widget, which is a stateful consumer widget for user profile management.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

/// State class for ProfileScreen. Handles form state, user data loading, and profile updates.
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _goalController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();
  final _goalFocusNode = FocusNode();

  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  String? _selectedGender;
  bool _isLoading = false;
  // Track provider user so we only sync when provider actually changes (e.g. after save)
  String? _lastProviderUserId;
  int? _lastProviderUpdatedAt;
  static const int _minDailyGoal = 100;
  static const int _maxDailyGoal = 10000;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider);
    final dailyGoal = ref.read(dailyGoalProvider);
    if (user != null) {
      _nameController.text = user.name ?? '';
      _ageController.text = user.age?.toString() ?? '';
      _weightController.text = user.weight.toString();
      _goalController.text = dailyGoal.toInt().toString();
      _selectedActivityLevel = user.activityLevel;
      _selectedGender = _normalizedGenderForUi(user.gender);
      _lastProviderUserId = user.id;
      _lastProviderUpdatedAt = user.updatedAt.millisecondsSinceEpoch;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _weightFocusNode.dispose();
    _goalFocusNode.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        // Parse weight with error handling
        final weightText = _weightController.text.trim();
        if (weightText.isEmpty) {
          throw Exception('Weight is required');
        }
        final weight = double.tryParse(weightText);
        if (weight == null || weight < 1 || weight > 500) {
          throw Exception('Please enter a valid weight (1-500 kg)');
        }

        // Parse age (optional)
        int? age;
        final ageText = _ageController.text.trim();
        if (ageText.isNotEmpty) {
          age = int.tryParse(ageText);
          if (age != null && (age < 1 || age > 150)) {
            throw Exception('Please enter a valid age (1-150)');
          }
        }

        final updatedUser = user.copyWith(
          age: age,
          weight: weight,
          gender: _genderForPersistence(_selectedGender),
          activityLevel: _selectedActivityLevel,
          updatedAt: DateTime.now(),
        );

        debugPrint('Updating user profile: ${updatedUser.toJson()}');
        await ref.read(currentUserProvider.notifier).updateUser(updatedUser);
        debugPrint('User profile updated successfully');

        // Update local state to reflect the saved changes immediately
        setState(() {
          _selectedActivityLevel = updatedUser.activityLevel;
          _selectedGender = updatedUser.gender;
        });

        // Reload user data to reflect changes in the UI (for controllers, etc.)
        _loadUserData();

        // Daily goal will be recalculated automatically by the provider

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('No user found');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<TextInputFormatter>? _inputFormattersForField(String label) {
    if (label == 'Age') {
      return <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly];
    }
    if (label == 'Weight') {
      return <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
      ];
    }
    return null;
  }

  Future<void> _updateDailyGoalFromInput(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final newGoal = double.tryParse(trimmed);
    if (newGoal == null || newGoal < _minDailyGoal || newGoal > _maxDailyGoal) {
      return;
    }

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;
      await ref.read(currentUserProvider.notifier).updateUser(
            currentUser.copyWith(customGoal: newGoal),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update hydration goal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final hydrationState = ref.watch(hydrationStateProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Sync local state only when the provider user actually changed (e.g. after save or load)
    // This prevents resetting user selections while they're editing (provider still has old data)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final providerChanged = _lastProviderUserId != user.id ||
          _lastProviderUpdatedAt != user.updatedAt.millisecondsSinceEpoch;
      if (providerChanged) {
        setState(() {
          _selectedActivityLevel = user.activityLevel;
          _selectedGender = _normalizedGenderForUi(user.gender);
          _lastProviderUserId = user.id;
          _lastProviderUpdatedAt = user.updatedAt.millisecondsSinceEpoch;
        });
      }
    });

    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue, // #FAFCFF
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // pb-24
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header - matches Figma: px-6 py-6 flex items-center justify-between
                  Padding(
                    padding: const EdgeInsets.all(24), // px-6 py-6
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 24, // text-2xl = 24px
                                fontWeight: FontWeight.bold,
                                color: NeumorphicStyle.darkText,
                              ),
                            ),
                            const SizedBox(height: 4), // mt-1 = 4px
                            Text(
                              AppCapabilities.authEnabled
                                  ? 'Manage your account settings'
                                  : 'Manage your profile settings',
                              style: TextStyle(
                                fontSize: 14, // text-sm = 14px
                                color: NeumorphicStyle.lightText,
                              ),
                            ),
                          ],
                        ),
                        if (AppCapabilities.authEnabled)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: NeumorphicStyle.softBorder,
                                width: 1,
                              ),
                            ),
                            child: TextButton.icon(
                              onPressed: () => _showLogoutDialog(),
                              icon: Icon(
                                Icons.logout,
                                color: NeumorphicStyle.lightText,
                                size: 16,
                              ),
                              label: Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: NeumorphicStyle.lightText,
                                ),
                              ),
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
                        // Personal Information - matches Figma
                        _buildPersonalInfoSection(),
                        const SizedBox(height: 24),

                        // Activity Level - matches Figma
                        _buildActivityLevelSection(user),
                        const SizedBox(height: 24),

                        // Daily Hydration Goal - matches Figma
                        _buildDailyGoalSection(dailyGoal),
                        const SizedBox(height: 24),

                        // Update Button - matches Figma
                        Container(
                          decoration: BoxDecoration(
                            gradient: NeumorphicStyle.primaryGradient(),
                            borderRadius:
                                BorderRadius.circular(16), // rounded-2xl
                            boxShadow: [
                              BoxShadow(
                                color: NeumorphicStyle.primaryBlue
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16), // py-4
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Update Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Notification Settings - matches Figma
                        _buildNotificationSettingsSection(),
                        const SizedBox(height: 24),

                        // Legal, privacy, and account section
                        _buildLegalSection(),

                        // Show "Go No Ads" in offline mode (or for unauthenticated users if auth is enabled)
                        if (!AppCapabilities.authEnabled ||
                            ref.watch(authProvider) ==
                                AuthState.unauthenticated) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFD54F).withOpacity(0.1),
                                  const Color(0xFFFFC107).withOpacity(0.05),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFFFC107).withOpacity(0.3),
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
                                onTap: () => _showNoAdsDialog(context),
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 18, horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD54F),
                                              Color(0xFFFFC107)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.block,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Go No Ads',
                                        style: TextStyle(
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age and Weight - matches Figma: grid grid-cols-2 gap-4
          Row(
            children: [
              Expanded(
                child: _buildInfoField(
                  label: 'Age',
                  icon: Icons.calendar_today_outlined,
                  controller: _ageController,
                  focusNode: _ageFocusNode,
                  hintText: 'Age',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null; // Age is optional
                    }
                    final age = int.tryParse(value.trim());
                    if (age == null) {
                      return 'Please enter a valid age';
                    }
                    if (age < 1 || age > 150) {
                      return 'Please enter a valid age (1-150)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16), // gap-4 = 16px
              Expanded(
                child: _buildInfoField(
                  label: 'Weight',
                  icon: Icons.monitor_weight_outlined,
                  controller: _weightController,
                  focusNode: _weightFocusNode,
                  hintText: 'Weight',
                  suffix: Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: NeumorphicStyle.lightText,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Weight is required';
                    }
                    final weight = double.tryParse(value.trim());
                    if (weight == null) {
                      return 'Please enter a valid weight';
                    }
                    if (weight < 1 || weight > 500) {
                      return 'Please enter a valid weight (1-500 kg)';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gender - matches Figma
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Gender',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: NeumorphicStyle.lightText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGenderButton('male', _selectedGender == 'male'),
              ),
              const SizedBox(width: 12), // gap-3 = 12px
              Expanded(
                child:
                    _buildGenderButton('female', _selectedGender == 'female'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? hintText,
    bool readOnly = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NeumorphicStyle.lightText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: NeumorphicStyle.surfaceBlue, // #F5F9FF
            borderRadius: BorderRadius.circular(12), // rounded-xl
            border: Border.all(
              color: NeumorphicStyle.softBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  icon,
                  color: NeumorphicStyle.lightText,
                  size: 20, // w-5 h-5 = 20px
                ),
              ),
              const SizedBox(width: 12), // gap-3 = 12px
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  validator: validator,
                  keyboardType: label == 'Age'
                      ? TextInputType.number
                      : label == 'Weight'
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                  inputFormatters: _inputFormattersForField(label),
                  style: TextStyle(
                    fontSize: 16,
                    color: readOnly
                        ? NeumorphicStyle.lightText
                        : NeumorphicStyle.darkText,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12), // py-3 = 12px
                    hintStyle: TextStyle(color: NeumorphicStyle.lightText),
                    errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (suffix != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: suffix,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderButton(String gender, bool isSelected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
        FocusScope.of(context).unfocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12), // py-3
        decoration: BoxDecoration(
          gradient: isSelected ? NeumorphicStyle.primaryGradient() : null,
          color: isSelected ? null : NeumorphicStyle.surfaceBlue,
          borderRadius: BorderRadius.circular(12), // rounded-xl
          border: Border.all(
            color: isSelected ? Colors.transparent : NeumorphicStyle.softBorder,
            width: 1,
          ),
        ),
        child: Text(
          gender == 'male' ? 'Male' : 'Female',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500, // font-medium
            color: isSelected ? Colors.white : NeumorphicStyle.lightText,
          ),
        ),
      ),
    );
  }

  String? _normalizedGenderForUi(String? rawGender) {
    if (rawGender == null || rawGender.isEmpty) return null;
    final normalized = rawGender.trim().toLowerCase();
    if (normalized == 'm' || normalized == 'male') return 'male';
    if (normalized == 'f' || normalized == 'female') return 'female';
    return null;
  }

  String? _genderForPersistence(String? uiGender) {
    if (uiGender == null || uiGender.isEmpty) return null;
    return uiGender == 'male' ? 'M' : 'F';
  }

  Widget _buildActivityLevelSection(User user) {
    // Use enum displayName for label/description; match by enum identity
    final currentActivity = {
      'label': _selectedActivityLevel.displayName,
      'description': _getActivityDescription(_selectedActivityLevel),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _showActivityLevelSheet();
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: NeumorphicStyle.darkText,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16), // px-4 py-3
              decoration: BoxDecoration(
                color: NeumorphicStyle.surfaceBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: NeumorphicStyle.softBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: NeumorphicStyle.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentActivity['label'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: NeumorphicStyle.darkText,
                          ),
                        ),
                        const SizedBox(height: 4), // mt-1 = 4px
                        Text(
                          currentActivity['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: NeumorphicStyle.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: NeumorphicStyle.lightText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationSettingsScreen(),
          ),
        );
      },
      child: Container(
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
                color: NeumorphicStyle.lightBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications,
                color: NeumorphicStyle.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Settings',
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
            Icon(
              Icons.chevron_right,
              color: NeumorphicStyle.lightText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalSection(double dailyGoal) {
    // Only update controller text if field is not focused and value changed externally
    // This prevents cursor jumping when user is typing
    if (!_goalFocusNode.hasFocus) {
      final currentValue = _goalController.text.trim();
      final newValue = dailyGoal.toInt().toString();
      if (currentValue != newValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_goalFocusNode.hasFocus) {
            final selection = _goalController.selection;
            _goalController.text = newValue;
            // Restore cursor position if it was at the end
            if (selection.isValid && selection.end == currentValue.length) {
              _goalController.selection =
                  TextSelection.collapsed(offset: newValue.length);
            }
          }
        });
      }
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Hydration Goal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: NeumorphicStyle.darkText,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NeumorphicStyle.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NeumorphicStyle.softBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag,
                  color: NeumorphicStyle.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _goalController,
                    focusNode: _goalFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'Please enter a daily goal';
                      }
                      final goal = int.tryParse(trimmed);
                      if (goal == null ||
                          goal < _minDailyGoal ||
                          goal > _maxDailyGoal) {
                        return 'Use a goal between $_minDailyGoal and $_maxDailyGoal ml';
                      }
                      return null;
                    },
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: NeumorphicStyle.darkText,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      _updateDailyGoalFromInput(value);
                    },
                  ),
                ),
                Text(
                  'ml/day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NeumorphicStyle.lightText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityLevelSheet() async {
    final selected = await showModalBottomSheet<ActivityLevel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: NeumorphicStyle.backgroundBlue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NeumorphicStyle.softBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with icon and title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
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
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Activity Level',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: NeumorphicStyle.darkText,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
            // Activity level options
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: ActivityLevel.values.map((level) {
                  final isSelected = _selectedActivityLevel == level;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                NeumorphicStyle.primaryBlue.withOpacity(0.15),
                                NeumorphicStyle.primaryBlue.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : NeumorphicStyle.surfaceBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? NeumorphicStyle.primaryBlue.withOpacity(0.3)
                            : NeumorphicStyle.softBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(level),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF4FC3F7),
                                            Color(0xFF2196F3)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : NeumorphicStyle.surfaceBlue,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: NeumorphicStyle.softBorder,
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF2196F3)
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: isSelected
                                      ? Colors.white
                                      : NeumorphicStyle.lightText,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      level.displayName,
                                      style: NeumorphicStyle.neumorphicText(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? NeumorphicStyle.primaryBlue
                                            : NeumorphicStyle.darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getActivityDescription(level),
                                      style: NeumorphicStyle.neumorphicText(
                                        fontSize: 12,
                                        color: NeumorphicStyle.lightText,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4FC3F7),
                                        Color(0xFF2196F3)
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedActivityLevel = selected;
      });
      // Ensure no text field regains focus after activity level selection
      // Use a delayed approach to ensure the modal is fully dismissed
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _nameFocusNode.unfocus();
          _weightFocusNode.unfocus();
          FocusScope.of(context).unfocus();
        }
      });
    }
  }

  String _getActivityDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise';
      case ActivityLevel.lightlyActive:
        return 'Light exercise/sports 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise/sports 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise/sports 6-7 days/week';
      case ActivityLevel.extremelyActive:
        return 'Very hard exercise, physical job';
    }
  }

  // Bottom navigation bar has been moved to the dashboard screen

  void _showNoAdsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
            children: [
              // Header with icon and title
              Container(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
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
                        Icons.block,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Go No Ads',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enjoy an ad-free experience',
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Benefits of going ad-free:',
                        style: NeumorphicStyle.neumorphicText(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: NeumorphicStyle.darkText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.block, 'No Banner Ads',
                          'Remove all banner advertisements'),
                      _buildFeatureItem(
                          Icons.fullscreen_exit,
                          'No Interstitial Ads',
                          'No full-screen ad interruptions'),
                      _buildFeatureItem(Icons.speed, 'Faster Experience',
                          'Smoother app performance'),
                      _buildFeatureItem(Icons.favorite, 'Support Development',
                          'Help us continue improving the app'),
                    ],
                  ),
                ),
              ),
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
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
                              'Maybe Later',
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
                                colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFFC107).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // Placeholder until payment integration is wired in.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Payment integration coming soon!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.block,
                                  color: Colors.white, size: 20),
                              label: const Text(
                                'Remove Ads',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD54F).withOpacity(0.1),
            const Color(0xFFFFC107).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFC107).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
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
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC107).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NeumorphicStyle.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
    );
  }

  Widget _buildLegalSection() {
    return Container(
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
          _buildLegalRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchUrl(AppUrls.privacyPolicyUrl),
          ),
          Divider(height: 1, indent: 20, endIndent: 20, color: NeumorphicStyle.softBorder),
          _buildLegalRow(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _launchUrl(AppUrls.termsOfServiceUrl),
          ),
          Divider(height: 1, indent: 20, endIndent: 20, color: NeumorphicStyle.softBorder),
          _buildLegalRow(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            titleColor: const Color(0xFFE53935),
            iconColor: const Color(0xFFE53935),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor ?? NeumorphicStyle.lightText),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? NeumorphicStyle.darkText,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: NeumorphicStyle.lightText),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
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
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE53935).withOpacity(0.1),
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
                          colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delete Account',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will permanently delete your account and all hydration data. This action cannot be undone.',
                      textAlign: TextAlign.center,
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
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
                                colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await ref
                                    .read(authProvider.notifier)
                                    .deleteAccount();
                                if (mounted && !result.success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result.message ??
                                            'Failed to delete account',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Delete',
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
      ),
    );
  }

  void _showLogoutDialog() {
    if (!AppCapabilities.authEnabled) {
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
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
            children: [
              // Header with icon and gradient
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEF5350).withOpacity(0.1),
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
                          colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Logout',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Are you sure you want to logout?',
                      textAlign: TextAlign.center,
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        // Cancel button
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
                        // Logout button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFE53935).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await ref.read(authProvider.notifier).logout();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Logout',
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
      ),
    );
  }
}
