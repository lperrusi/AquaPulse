/// Notification Permission Screen
///
/// Screen to request notification permissions from the user.
/// Matches Figma design exactly.

import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class NotificationPermissionScreen extends StatefulWidget {
  /// Called when user taps "Enable Notifications". Receives this screen's
  /// [BuildContext] so navigation works after onboarding was replaced.
  final Future<void> Function(BuildContext context) onAllow;
  /// Called when user taps "Maybe Later" or "Skip". Receives this screen's context.
  final void Function(BuildContext context) onSkip;

  const NotificationPermissionScreen({
    super.key,
    required this.onAllow,
    required this.onSkip,
  });

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: NeumorphicStyle.splashGradient(),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Skip Button
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: () => widget.onSkip(context),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: NeumorphicStyle.primaryBlue,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with animation and badge
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                gradient: NeumorphicStyle.primaryGradient(),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 80,
                              ),
                            ),
                            // Notification Badge
                            Positioned(
                              top: -8,
                              right: -8,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
                                  ),
                                ),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '💧',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: Text(
                            'Enable Notifications',
                            style: NeumorphicStyle.neumorphicText(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: Text(
                            'Get timely reminders to drink water throughout the day and stay on track with your hydration goals',
                            style: NeumorphicStyle.neumorphicText(
                              fontSize: 18,
                              color: NeumorphicStyle.darkText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Benefits
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: Column(
                            children: [
                              _buildBenefit('Smart hydration reminders'),
                              const SizedBox(height: 16),
                              _buildBenefit('Customizable notification times'),
                              const SizedBox(height: 16),
                              _buildBenefit('Track your progress daily'),
                              const SizedBox(height: 16),
                              _buildBenefit('Achieve your health goals'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Buttons
              Positioned(
                bottom: 48,
                left: 32,
                right: 32,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Enable Notifications Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: NeumorphicStyle.primaryGradient(),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              await widget.onAllow(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Enable Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Maybe Later Button
                        TextButton(
                          onPressed: () => widget.onSkip(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Maybe Later',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: NeumorphicStyle.primaryBlue,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildBenefit(String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: NeumorphicStyle.lightBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 20,
            color: NeumorphicStyle.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: NeumorphicStyle.neumorphicText(
              fontSize: 16,
              color: NeumorphicStyle.darkText,
            ),
          ),
        ),
      ],
    );
  }
}
