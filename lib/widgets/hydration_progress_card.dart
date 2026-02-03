/// Hydration Progress Card Widget
///
/// Displays the user's daily hydration progress as an animated circular progress bar with motivational text and lap transitions.
/// Allows editing the daily hydration goal via a dialog. Used on the dashboard and profile screens.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/hydration_service.dart';
import '../utils/neumorphic_style.dart';
import 'water_wave_progress.dart';

/// Widget that displays the animated hydration progress card, including the progress ring, motivational text, and edit goal dialog.
class HydrationProgressCard extends ConsumerStatefulWidget {
  final HydrationState hydrationState;
  const HydrationProgressCard({super.key, required this.hydrationState});

  @override
  ConsumerState<HydrationProgressCard> createState() => _HydrationProgressCardState();
}

/// State class for HydrationProgressCard. Handles animation, lap transitions, and dialog logic.
class _HydrationProgressCardState extends ConsumerState<HydrationProgressCard> with SingleTickerProviderStateMixin {
  double _oldProgress = 0.0;
  int _oldLap = 0;
  double _displayedProgress = 0.0;
  int _displayedLap = 0;
  bool _isAnimating = false;
  
  // Animation controller for additional effects
  late AnimationController _effectController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _showMilestoneEffect = false;

  // Define a palette for lap colors matching the neumorphic theme
  static const List<Color> lapColors = [
    NeumorphicStyle.primaryBlue, // 1x goal
    NeumorphicStyle.secondaryBlue, // 2x goal
    Color(0xFF8B5CF6), // 3x goal - purple
    Color(0xFF06B6D4), // 4x goal - cyan
    Color(0xFFEF4444), // 5x goal - red
  ];

  @override
  void initState() {
    super.initState();
    final currentIntake = widget.hydrationState.currentIntake;
    final goal = widget.hydrationState.goal;
    _displayedLap = goal > 0 ? (currentIntake / goal).floor() : 0;
    _displayedProgress = goal > 0 ? (currentIntake % goal) / goal : 0.0;
    _oldLap = _displayedLap;
    _oldProgress = _displayedProgress;
    
    // Initialize animation controller for milestone effects
    _effectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Pulsing effect animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _effectController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Scale effect animation
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _effectController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HydrationProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIntake = widget.hydrationState.currentIntake;
    final goal = widget.hydrationState.goal;
    final newLap = goal > 0 ? (currentIntake / goal).floor() : 0;
    final newProgress = goal > 0 ? (currentIntake % goal) / goal : 0.0;

    // Check if we've reached a milestone (completed a lap or hit 25%, 50%, 75%, 100% of goal)
    final oldPercentage = (_oldLap + _oldProgress) * 100;
    final newPercentage = (newLap + newProgress) * 100;
    
    final milestones = [25, 50, 75, 100, 200, 300, 400, 500]; // percentages
    final hitMilestone = milestones.any((milestone) => 
      oldPercentage < milestone && newPercentage >= milestone);
      
    if (hitMilestone) {
      _showMilestoneAnimation();
    }

    if (newLap > _oldLap) {
      // Animate to 1.0, then to newProgress for the new lap
      _animateLapTransition(_oldProgress, newProgress, newLap);
    } else {
      _oldProgress = _displayedProgress;
      _displayedProgress = newProgress;
      _displayedLap = newLap;
    }
    _oldLap = newLap;
  }

  Future<void> _animateLapTransition(double from, double to, int newLap) async {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
    });
    
    // Show milestone animation when completing a lap
    _showMilestoneAnimation();
    
    // Step 1: Animate to 1.0 with a smoother transition
    _oldProgress = from;
    _displayedProgress = 1.0;
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Step 2: Animate from 0 to new progress with a nice elastic effect
    setState(() {
      _displayedLap = newLap;
      _oldProgress = 0.0;
      _displayedProgress = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 50)); // Ensure the animation resets to 0 visually
    setState(() {
      _displayedProgress = to;
      _isAnimating = false;
    });
  }

  void _showEditGoalDialog(BuildContext context, double currentGoal) async {
    final controller = TextEditingController(text: currentGoal.toInt().toString());
    final formKey = GlobalKey<FormState>();
    final user = ref.read(currentUserProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Daily Goal',
          style: NeumorphicStyle.neumorphicText(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: NeumorphicStyle.backgroundBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: NeumorphicStyle.neumorphicInput(
              labelText: 'Daily Goal (ml)',
              hintText: 'Enter your daily water goal',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a goal';
              }
              final goal = double.tryParse(value);
              if (goal == null || goal <= 0) {
                return 'Please enter a valid goal';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: NeumorphicStyle.neumorphicText(
                color: NeumorphicStyle.lightText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newGoal = double.parse(controller.text);
                if (user != null) {
                  await ref.read(currentUserProvider.notifier).updateUser(
                    user.copyWith(customGoal: newGoal),
                  );
                  Navigator.of(context).pop();
                }
              }
            },
            style: NeumorphicStyle.neumorphicButton(),
            child: Text(
              'Save',
              style: NeumorphicStyle.neumorphicText(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMilestoneAnimation() {
    setState(() {
      _showMilestoneEffect = true;
    });
    
    _effectController.reset();
    _effectController.forward().then((_) {
      _effectController.reverse().then((_) {
        setState(() {
          _showMilestoneEffect = false;
        });
      });
    });
  }
  
  @override
  void dispose() {
    _effectController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentIntake = widget.hydrationState.currentIntake;
    final goal = widget.hydrationState.goal;
    final progress = goal > 0 ? _displayedProgress : 0.0;
    final lap = _displayedLap;
    final currentColor = lap < lapColors.length ? lapColors[lap] : lapColors.last;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.neumorphicCard(),
      child: Column(
        children: [
          // Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              // Background circle with neumorphic effect
              Container(
                width: 160,
                height: 160,
                decoration: NeumorphicStyle.neumorphicContainer(
                  borderRadius: 80,
                ),
                child: Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NeumorphicStyle.surfaceBlue,
                      border: Border.all(
                        color: NeumorphicStyle.softBorder,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Animated Progress indicator with enhanced water wave effect
              AnimatedBuilder(
                animation: _effectController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Drop shadow for depth effect
                      Container(
                        width: 144,
                        height: 144,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      // Scale animation
                      Transform.scale(
                        scale: _showMilestoneEffect ? _scaleAnimation.value : 1.0,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: NeumorphicStyle.backgroundBlue.withOpacity(0.5),
                            border: Border.all(
                              color: NeumorphicStyle.softBorder,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: WaterWaveProgress(
                              value: progress,
                              color: currentColor,
                              backgroundColor: NeumorphicStyle.surfaceBlue,
                              strokeWidth: 8,
                            ),
                          ),
                        ),
                      ),
                      // Shine effect on top
                      Positioned(
                        top: 25,
                        left: 25,
                        child: Container(
                          width: 30,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Colors.white.withOpacity(0.4), Colors.transparent],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${currentIntake.round()}',
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: currentColor,
                    ),
                  ),
                  Text(
                    'ml',
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 14,
                      color: NeumorphicStyle.lightText,
                    ),
                  ),
                  if (lap > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: currentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${lap}x Goal!',
                        style: NeumorphicStyle.neumorphicText(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: currentColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Goal and Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Goal',
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 14,
                      color: NeumorphicStyle.lightText,
                    ),
                  ),
                  Text(
                    '${goal.toInt()} ml',
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              NeumorphicStyle.neumorphicIconButton(
                icon: Icons.edit,
                onPressed: () => _showEditGoalDialog(
                  context,
                  goal,
                ),
                size: 40,
                borderRadius: 10,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Motivational Text
          Text(
            _getMotivationalText(currentIntake, goal, lap),
            style: NeumorphicStyle.neumorphicText(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: currentColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMotivationalText(double currentIntake, double goal, int lap) {
    if (goal == 0) return 'Set your daily goal to get started!';
    
    final percentage = (currentIntake / goal) * 100;
    
    if (lap > 0) {
      return 'Amazing! You\'ve exceeded your goal ${lap} time${lap > 1 ? 's' : ''}!';
    } else if (percentage >= 90) {
      return 'Almost there! You\'re so close to your goal!';
    } else if (percentage >= 75) {
      return 'Great progress! You\'re doing fantastic!';
    } else if (percentage >= 50) {
      return 'Halfway there! Keep up the great work!';
    } else if (percentage >= 25) {
      return 'Good start! Every drop counts!';
    } else {
      return 'Let\'s start your hydration journey!';
    }
  }
} 