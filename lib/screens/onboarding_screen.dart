/// Onboarding Screen
///
/// Modern onboarding screen with clean design, progress indicator, and intuitive form layout.
/// Captures user profile information and creates local user account.
// ignore_for_file: deprecated_member_use
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/app_providers.dart';
import '../utils/neumorphic_style.dart';
import '../services/notification_service.dart';
import 'notification_permission_screen.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';

/// The main OnboardingScreen widget with modern design
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// State class for OnboardingScreen with enhanced UI
class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController(text: '25');
  final _weightController = TextEditingController(text: '70');
  final _ageFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();

  String _selectedGender = 'M';
  String _selectedWeightUnit = 'kg';
  ActivityLevel _selectedActivityLevel = ActivityLevel.lightlyActive;
  bool _isLoading = false;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _ageFocusNode.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping anywhere on the screen
            FocusScope.of(context).unfocus();
          },
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header Section
                _buildHeader(),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // Age and Gender Section
                        _buildAgeGenderSection(),

                        const SizedBox(height: 32),

                        // Weight Section
                        _buildWeightSection(),

                        const SizedBox(height: 32),

                        // Activity Level Section
                        _buildActivityLevelSection(),

                        const SizedBox(height: 48),

                        // Continue Button
                        _buildContinueButton(),

                        const SizedBox(
                            height: 100), // Extra bottom padding for keyboard
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // AquaPulse Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AquaPulse',
                style: NeumorphicStyle.neumorphicText(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 4,
                decoration: BoxDecoration(
                  color: NeumorphicStyle.softBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 4,
                decoration: BoxDecoration(
                  color: NeumorphicStyle.softBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Title - matches Figma: text-3xl = 30px, font-bold
          Text(
            'TELL US ABOUT YOURSELF',
            style: NeumorphicStyle.neumorphicText(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age',
          style: NeumorphicStyle.neumorphicText(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Age Input
            Expanded(
              child: TextFormField(
                controller: _ageController,
                focusNode: _ageFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE1EFF9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE1EFF9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF2196F3), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0A2463),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 120) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            // Gender Selection
            _buildGenderButton('M', 'Male'),
            const SizedBox(width: 12),
            _buildGenderButton('F', 'Female'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderButton(String value, String label) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedGender = value);
        // Dismiss keyboard when selecting gender
        FocusScope.of(context).unfocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? NeumorphicStyle.primaryGradient() : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25), // rounded-[25px]
          border: Border.all(
            color:
                isSelected ? Colors.transparent : NeumorphicStyle.primaryBlue,
            width: 2, // border-2 = 2px
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600, // font-semibold
            color: isSelected ? Colors.white : NeumorphicStyle.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight',
          style: NeumorphicStyle.neumorphicText(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Weight Input
            Expanded(
              child: TextFormField(
                controller: _weightController,
                focusNode: _weightFocusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
                ],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: NeumorphicStyle.neumorphicInput(
                  hintText: 'Weight',
                ),
                style: NeumorphicStyle.neumorphicText(
                  fontSize: 16,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 20 || weight > 300) {
                    return 'Please enter a valid weight';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            // Unit Selection - matches Figma exactly
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // rounded-xl
                border: Border.all(
                  color: NeumorphicStyle.softBorder,
                  width: 1,
                ),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // kg button
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedWeightUnit = 'kg');
                      FocusScope.of(context).unfocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedWeightUnit == 'kg'
                            ? NeumorphicStyle.primaryBlue
                            : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        'kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedWeightUnit == 'kg'
                              ? Colors.white
                              : NeumorphicStyle.lightText,
                        ),
                      ),
                    ),
                  ),
                  // lbs button
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedWeightUnit = 'lbs');
                      FocusScope.of(context).unfocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedWeightUnit == 'lbs'
                            ? NeumorphicStyle.primaryBlue
                            : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        'lbs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedWeightUnit == 'lbs'
                              ? Colors.white
                              : NeumorphicStyle.lightText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity level',
          style: NeumorphicStyle.neumorphicText(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Dismiss keyboard before showing activity level menu
            FocusScope.of(context).unfocus();
            _showActivityLevelMenu();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: NeumorphicStyle.neumorphicContainer(
              color: NeumorphicStyle.surfaceBlue,
              borderRadius: 12,
            ),
            child: Row(
              children: [
                Icon(
                  _getActivityIcon(_selectedActivityLevel),
                  color: NeumorphicStyle.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActivityTitle(_selectedActivityLevel),
                        style: NeumorphicStyle.neumorphicText(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getActivityDescription(_selectedActivityLevel),
                        style: NeumorphicStyle.neumorphicText(
                          fontSize: 14,
                          color: NeumorphicStyle.lightText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: NeumorphicStyle.primaryBlue,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showActivityLevelMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white, // bg-white in Figma
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)), // rounded-t-[24px]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar - matches Figma: w-10 h-1 = 40px x 4px
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    NeumorphicStyle.lightText.withOpacity(0.3), // bg-gray-300
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24), // mb-6 = 24px

            // Title - matches Figma: text-xl font-bold
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Activity Level',
                style: NeumorphicStyle.neumorphicText(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16), // mb-4 = 16px

            // Activity options
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: ActivityLevel.values
                      .map((level) => _buildActivityMenuItem(level))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20), // Extra bottom margin
          ],
        ),
      ),
    );
  }

  Widget _buildActivityMenuItem(ActivityLevel level) {
    final isSelected = _selectedActivityLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedActivityLevel = level);
        Navigator.of(context).pop();
        // Ensure no text field regains focus after activity level selection
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _ageFocusNode.unfocus();
            _weightFocusNode.unfocus();
            FocusScope.of(context).unfocus();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4), // space-y-3 = 12px, but we use 4px margin
        padding: const EdgeInsets.all(16), // p-4 = 16px
        decoration: BoxDecoration(
          gradient: isSelected ? NeumorphicStyle.primaryGradient() : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12), // rounded-xl = 12px
          border: Border.all(
            color: isSelected ? Colors.transparent : NeumorphicStyle.softBorder,
            width: 2, // border-2 = 2px
          ),
        ),
        child: Row(
          children: [
            // Icon - using emoji like in Figma
            Text(
              _getActivityEmoji(level),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12), // gap-3 = 12px
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getActivityTitle(level),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600, // font-semibold
                      color:
                          isSelected ? Colors.white : NeumorphicStyle.darkText,
                    ),
                  ),
                  Text(
                    _getActivityDescription(level),
                    style: TextStyle(
                      fontSize: 14, // text-sm = 14px
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : NeumorphicStyle.lightText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 20, // w-5 h-5 = 20px
              ),
          ],
        ),
      ),
    );
  }

  String _getActivityEmoji(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return '🪑';
      case ActivityLevel.lightlyActive:
        return '🚶';
      case ActivityLevel.moderatelyActive:
        return '🏃';
      case ActivityLevel.veryActive:
        return '💪';
      case ActivityLevel.extremelyActive:
        return '🏋️';
    }
  }

  IconData _getActivityIcon(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return Icons.airline_seat_flat;
      case ActivityLevel.lightlyActive:
        return Icons.directions_walk;
      case ActivityLevel.moderatelyActive:
        return Icons.directions_run;
      case ActivityLevel.veryActive:
        return Icons.fitness_center;
      case ActivityLevel.extremelyActive:
        return Icons.sports_gymnastics;
    }
  }

  String _getActivityTitle(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  String _getActivityDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise';
      case ActivityLevel.lightlyActive:
        return 'Light exercise 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise 6-7 days/week';
      case ActivityLevel.extremelyActive:
        return 'Very hard exercise, physical job';
    }
  }

  Widget _buildContinueButton() {
    final isValid = _ageController.text.isNotEmpty &&
        _selectedGender.isNotEmpty &&
        _weightController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || !isValid) ? null : _createProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16), // py-4 = 16px
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // rounded-2xl = 16px
          ),
          disabledBackgroundColor: NeumorphicStyle.lightText.withOpacity(0.3),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: isValid && !_isLoading
                ? NeumorphicStyle.primaryGradient()
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isValid && !_isLoading
                ? [
                    BoxShadow(
                      color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16, // text-base = 16px
                      fontWeight: FontWeight.w600, // font-semibold
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = User(
        id: const Uuid().v4(),
        email: 'user_${DateTime.now().millisecondsSinceEpoch}@local.com',
        name: 'User',
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel,
        location: null,
        latitude: null,
        longitude: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(currentUserProvider.notifier).createUser(user);

      if (mounted) {
        // Navigate to notification permission screen after onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NotificationPermissionScreen(
              onAllow: (permissionScreenContext) async {
                // Request notification permissions
                try {
                  final notificationService = NotificationService();
                  await notificationService.requestPermissions();
                } catch (e) {
                  debugPrint('Error requesting notification permissions: $e');
                }
                // Navigate to dashboard using the permission screen's context
                if (permissionScreenContext.mounted) {
                  Navigator.of(permissionScreenContext).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AppRouter()),
                    (route) => false,
                  );
                }
              },
              onSkip: (permissionScreenContext) {
                // Skip and go to dashboard using the permission screen's context
                if (permissionScreenContext.mounted) {
                  Navigator.of(permissionScreenContext).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AppRouter()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: $e'),
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
}
