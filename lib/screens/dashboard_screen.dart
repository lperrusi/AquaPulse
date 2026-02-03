/// Dashboard Screen
///
/// The main home screen of the app. Displays hydration progress, quick add buttons, streaks, recent intakes, and provides navigation to other sections (Reminders, Stats, Profile).
/// Uses Riverpod for state management and updates.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

import '../widgets/hydration_progress_card.dart';
import '../widgets/water_intake_buttons.dart';
import '../widgets/recent_intakes_list.dart';
import '../widgets/streak_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/progress_circle.dart';
import '../utils/neumorphic_style.dart';
import '../main.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'stats_screen.dart';
import 'achievements_screen.dart';
import 'social_screen.dart';
import 'package:uuid/uuid.dart';
import '../models/water_intake.dart';
import '../services/auth_service.dart';
import '../services/weather_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../screens/weather_settings_screen.dart';
// import '../screens/premium_screen.dart';

/// The main DashboardScreen widget, which is a stateful consumer widget for the app's home/dashboard.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

/// State class for DashboardScreen. Handles navigation, tab selection, and hydration data loading.
class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _lastNonFabIndex = 0; // Track last non-FAB index for IndexedStack
  late AnimationController _progressAnimation;
  late AnimationController _celebrationAnimation;
  late AnimationController _waterDropAnimation;
  final double _currentProgress = 0.0;
  bool _showCelebration = false;
  Timer? _dayCheckTimer;

  void _onTabTapped(int index) {
    if (index == 2) {
      // Center FAB: Add Water Intake
      _showCustomIntakeDialog();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _progressAnimation = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _celebrationAnimation = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waterDropAnimation = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _startDayCheckTimer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayCheckTimer?.cancel();
    _progressAnimation.dispose();
    _celebrationAnimation.dispose();
    _waterDropAnimation.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check for day change when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkForDayChange();
    }
  }

  /// Starts a timer that checks for day changes every minute
  void _startDayCheckTimer() {
    _dayCheckTimer?.cancel();
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkForDayChange();
    });
  }

  /// Checks if a new day has started and refreshes data if needed
  Future<void> _checkForDayChange() async {
    final isNewDay =
        await ref.read(waterIntakeProvider.notifier).checkForNewDay();
    if (isNewDay && mounted) {
      // Reset progress animation for new day
      _progressAnimation.value = 0.0;
      // Reload initial data to update UI
      await _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      // Load streak data
      await ref.read(streakProvider.notifier).loadStreak(user.id);

      // Load today's intakes and update the provider state
      await ref.read(waterIntakeProvider.notifier).loadTodaysIntakes();

      // Set initial animation value
      final hydrationState = ref.read(hydrationStateProvider);
      final initialProgress = hydrationState.dailyGoal > 0
          ? (hydrationState.todayIntake / hydrationState.dailyGoal)
              .clamp(0.0, 1.0)
          : 0.0;
      _progressAnimation.value = initialProgress;

      // Check if goal is already met and update streak if needed
      if (hydrationState.isGoalMet) {
        final streak = ref.read(streakProvider);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Check if streak needs to be updated (goal met today but streak not updated yet)
        if (streak == null ||
            DateTime(streak.lastGoalMet.year, streak.lastGoalMet.month,
                    streak.lastGoalMet.day) !=
                today) {
          await ref.read(streakProvider.notifier).updateStreak(user.id, true);
        }
      }
    }
  }

  /// Records water intake and tracks notification response if applicable
  Future<void> _recordWaterIntake(double amount) async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final intake = WaterIntake(
        id: const Uuid().v4(),
        userId: user.id,
        amount: amount,
        timestamp: DateTime.now(),
        note: null,
      );

      // Store current progress for animation
      final hydrationState = ref.read(hydrationStateProvider);
      final goal = hydrationState.dailyGoal;
      final oldIntake = hydrationState.todayIntake;
      final oldProgress =
          goal > 0 ? (oldIntake / goal).clamp(0.0, double.infinity) : 0.0;

      // Add water intake
      await ref.read(waterIntakeProvider.notifier).addWaterIntake(intake);

      // Animate to new progress
      final newHydrationState = ref.read(hydrationStateProvider);
      final newIntake = newHydrationState.todayIntake;
      final newProgress =
          goal > 0 ? (newIntake / goal).clamp(0.0, double.infinity) : 0.0;

      // Animate progress with improved spring-like animation
      // Cap animation at 1.0 (100%) for smooth animation, but actual intake will show beyond goal
      _progressAnimation.value = oldProgress > 1.0 ? 1.0 : oldProgress;
      _progressAnimation.animateTo(
        newProgress > 1.0 ? 1.0 : newProgress,
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutBack,
      );

      // Check if goal was reached
      final wasBelowGoal = oldProgress < 1.0;
      final nowAtOrAboveGoal = newProgress >= 1.0;

      if (wasBelowGoal && nowAtOrAboveGoal) {
        // Goal reached! Show celebration
        setState(() {
          _showCelebration = true;
        });
        _celebrationAnimation.forward(from: 0.0).then((_) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showCelebration = false;
              });
              _celebrationAnimation.reset();
            }
          });
        });

        // Update streak when goal is met
        await ref.read(streakProvider.notifier).updateStreak(user.id, true);
      }

      // Show water drop animation feedback with haptic
      HapticFeedback.lightImpact();
      _waterDropAnimation.forward(from: 0.0).then((_) {
        _waterDropAnimation.reset();
      });

      // Track notification response within a 30-minute window
      // This helps improve smart suggestions by understanding when users respond to notifications
      final notificationService = NotificationService();
      await notificationService.recordNotificationResponse();

      // Show interstitial ad after every 3rd water intake (natural break point)
      final adService = ref.read(adServiceProvider);
      await adService.showInterstitialAdAfterIntake(context);
    }
  }

  /// Calculate the IndexedStack index (skip index 2 which is the center FAB)
  int _getStackIndex() {
    if (_selectedIndex == 2) {
      // FAB clicked - don't change screen, return last valid index
      return _lastNonFabIndex;
    }
    // Map: 0->0, 1->1, 3->2, 4->3, 5->4
    final stackIndex = _selectedIndex > 2 ? _selectedIndex - 1 : _selectedIndex;
    _lastNonFabIndex = stackIndex;
    return stackIndex;
  }

  Widget _buildBody(AdService adService) {
    final hydrationState = ref.watch(hydrationStateProvider);
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);

    // Show loading while authentication is in progress
    if (authState == AuthState.loading) {
      return Container(
        decoration: NeumorphicStyle.neumorphicGradient(),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(NeumorphicStyle.primaryBlue),
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: NeumorphicStyle.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error if authentication failed
    if (authState == AuthState.error) {
      return Container(
        decoration: NeumorphicStyle.neumorphicGradient(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: NeumorphicStyle.primaryBlue,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication error. Please try logging in again.',
                style: NeumorphicStyle.neumorphicText(
                  fontSize: 16,
                  color: NeumorphicStyle.darkText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // If user is null and not authenticated, navigate to login
    if (user == null && authState == AuthState.unauthenticated) {
      // Navigate to AppRouter which will show LoginScreen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AppRouter()),
            (route) => false,
          );
        }
      });
      // Show loading while navigating
      return Container(
        decoration: NeumorphicStyle.neumorphicGradient(),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(NeumorphicStyle.primaryBlue),
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: NeumorphicStyle.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading while user data is being loaded (but still authenticated)
    if (user == null) {
      return Container(
        decoration: NeumorphicStyle.neumorphicGradient(),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(NeumorphicStyle.primaryBlue),
              ),
              SizedBox(height: 16),
              Text(
                'Loading user data...',
                style: TextStyle(
                  color: NeumorphicStyle.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use IndexedStack to preserve state when switching tabs
    return IndexedStack(
      index: _getStackIndex(),
      children: [
        // Index 0: Home screen
        Container(
          color: NeumorphicStyle.backgroundBlue, // #FAFCFF
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                  bottom: 100), // pb-24 = 96px, extra for nav
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Ad at the top
                  adService.createBannerAd(ref),

                  // Header with logo and app name
                  _buildHeader(),

                  // Main Circular Progress Indicator with celebration overlay
                  // Matches Figma: centered with py-8 = 32px
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 32), // py-8 = 32px
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildMainProgressIndicator(hydrationState),
                        if (_showCelebration) _buildCelebrationOverlay(),
                      ],
                    ),
                  ),

                  // Content container - matches Figma: px-6 space-y-6 max-w-2xl mx-auto
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24), // px-6 = 24px
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Weather Recommendation - matches Figma
                        _buildRecommendationSection(context),
                        const SizedBox(height: 24), // space-y-6 = 24px

                        // Today's Intake Section - matches Figma
                        _buildTodaysIntakeSection(hydrationState),
                      ],
                    ),
                  ),

                  // Banner Ad at the bottom
                  const SizedBox(height: 24),
                  adService.createBannerAd(ref, isBottom: true),
                ],
              ),
            ),
          ),
        ),
        // Index 1: Reminders screen
        const RemindersScreen(),
        // Index 2: Stats screen (skipping index 2 which is the center FAB)
        const StatsScreen(),
        // Index 3: Profile screen
        const ProfileScreen(),
        // Index 4: Social screen
        const SocialScreen(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // px-6 py-6
      child: Row(
        children: [
          // Logo with water drop icon - matches Figma: w-12 h-12 rounded-xl
          Container(
            width: 48, // w-12 = 48px
            height: 48,
            decoration: BoxDecoration(
              gradient: NeumorphicStyle.primaryGradient(),
              borderRadius: BorderRadius.circular(12), // rounded-xl = 12px
            ),
            child: const Icon(
              Icons.water_drop,
              color: Colors.white,
              size: 28, // w-7 h-7 = 28px
            ),
          ),
          const SizedBox(width: 12), // gap-3 = 12px
          // App name - matches Figma: text-2xl font-bold
          Text(
            'AquaPulse',
            style: TextStyle(
              fontSize: 24, // text-2xl = 24px
              fontWeight: FontWeight.bold,
              color: NeumorphicStyle.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainProgressIndicator(HydrationState hydrationState) {
    // Use the new ProgressCircle widget that matches Figma exactly
    // The animation is handled internally by ProgressCircle
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        // Always use the actual intake amount - never calculate from goal
        // The animation is only for visual progress, not for the displayed value
        final actualIntake = hydrationState.todayIntake;
        final goal = hydrationState.dailyGoal;

        // Always pass the actual intake to ProgressCircle
        // The animation value is only used internally by ProgressCircle for visual progress
        return ProgressCircle(
          current: actualIntake,
          goal: goal,
          size: 200,
          strokeWidth: 12,
        );
      },
    );
  }

  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        final scale = Tween<double>(begin: 0.0, end: 1.0)
            .animate(
              CurvedAnimation(
                parent: _celebrationAnimation,
                curve: Curves.elasticOut,
              ),
            )
            .value;

        final opacity = Tween<double>(begin: 1.0, end: 0.0)
            .animate(
              CurvedAnimation(
                parent: _celebrationAnimation,
                curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
              ),
            )
            .value;

        // Confetti particles - matches Figma: 12 particles
        final confettiColors = [
          NeumorphicStyle.primaryBlue,
          NeumorphicStyle.secondaryBlue,
          NeumorphicStyle.golden,
          const Color(0xFF10B981), // success-green
          const Color(0xFFEF4444), // error-red
        ];

        return IgnorePointer(
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Confetti/particles effect - matches Figma
                ...List.generate(12, (index) {
                  final angle = (index * 360 / 12) * math.pi / 180;
                  final distance = 150 * _celebrationAnimation.value;
                  return Positioned(
                    left: 150 + distance * math.cos(angle),
                    top: 150 + distance * math.sin(angle),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8, // w-2 = 8px
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                confettiColors[index % confettiColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Celebration card - matches Figma: rounded-3xl, gradient
                Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      padding: const EdgeInsets.all(24), // p-6 = 24px
                      decoration: BoxDecoration(
                        gradient: NeumorphicStyle.primaryGradient(),
                        borderRadius:
                            BorderRadius.circular(24), // rounded-3xl = 24px
                        boxShadow: [
                          BoxShadow(
                            color: NeumorphicStyle.primaryBlue.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.celebration,
                            color: Colors.white,
                            size: 48, // w-12 h-12 = 48px
                          ),
                          const SizedBox(height: 12), // mb-3 = 12px
                          const Text(
                            'Goal Achieved! 🎉',
                            style: TextStyle(
                              fontSize: 24, // text-2xl = 24px
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8), // mb-2 = 8px
                          const Text(
                            'Great job! 🎉',
                            style: TextStyle(
                              fontSize: 18, // text-lg = 18px
                              color: Colors.white,
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
        );
      },
    );
  }

  Widget _buildRecommendationSection(BuildContext context) {
    // Use the WeatherCard widget which now matches Figma
    return const WeatherCard();
  }

  Widget _buildTodaysIntakeSection(HydrationState hydrationState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title - matches Figma: text-lg font-semibold
        Text(
          "Today's Intake",
          style: TextStyle(
            fontSize: 18, // text-lg = 18px
            fontWeight: FontWeight.w600, // font-semibold
            color: NeumorphicStyle.darkText,
          ),
        ),
        const SizedBox(height: 12), // mb-3 = 12px
        // Intake list container - matches Figma
        Container(
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
          padding: const EdgeInsets.all(16), // p-4 = 16px
          child: hydrationState.todayIntakes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No intakes recorded today',
                      style: TextStyle(
                        fontSize: 16,
                        color: NeumorphicStyle.lightText,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: hydrationState.todayIntakes.map((intake) {
                    final time = intake.timestamp;
                    final hour = time.hour;
                    final minute = time.minute;
                    final period = hour >= 12 ? 'PM' : 'AM';
                    final displayHour =
                        hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                    final timeString =
                        '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';

                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 12), // space-y-3 = 12px
                      padding: const EdgeInsets.all(12), // p-3 = 12px
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12), // rounded-xl
                        border: Border(
                          left: BorderSide(
                            color: NeumorphicStyle.primaryBlue,
                            width: 4, // border-l-4
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Amount circle - matches Figma
                          Container(
                            width: 40, // w-10 = 40px
                            height: 40,
                            decoration: BoxDecoration(
                              color: NeumorphicStyle.lightBlue, // #E8F4FD
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${intake.amount.round()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: NeumorphicStyle.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12), // gap-3 = 12px
                          // Intake details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${intake.amount.round()} ml',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: NeumorphicStyle.darkText,
                                  ),
                                ),
                                Text(
                                  timeString,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: NeumorphicStyle.lightText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Edit button
                          GestureDetector(
                            onTap: () => _showEditIntakeDialog(intake),
                            child: Container(
                              padding: const EdgeInsets.all(8), // p-2 = 8px
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                color: NeumorphicStyle.primaryBlue,
                                size: 16, // w-4 h-4 = 16px
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  void _showCustomIntakeDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // rounded-[28px]
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: NeumorphicStyle.backgroundBlue, // #FAFCFF
            borderRadius: BorderRadius.circular(28),
            boxShadow: NeumorphicStyle.dialogShadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon and title - matches Figma exactly
              Padding(
                padding: const EdgeInsets.all(24), // p-6 = 24px
                child: Row(
                  children: [
                    // Icon - matches Figma: w-12 h-12 rounded-full
                    Container(
                      width: 48, // w-12 = 48px
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: NeumorphicStyle.primaryGradient(),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 24, // w-6 h-6 = 24px
                      ),
                    ),
                    const SizedBox(width: 12), // gap-3 = 12px
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Water Intake',
                            style: NeumorphicStyle.neumorphicText(
                              fontSize: 20, // text-xl = 20px
                              fontWeight: FontWeight.w600, // font-semibold
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quick add or custom amount',
                            style: NeumorphicStyle.neumorphicText(
                              fontSize: 14, // text-sm = 14px
                              color: NeumorphicStyle.lightText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Add section - matches Figma
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), // px-6, pb-4
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Add',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12), // mb-3 = 12px
                    // Quick add grid - 3 columns, matches Figma
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12, // gap-3 = 12px
                        mainAxisSpacing: 12,
                        childAspectRatio:
                            0.82, // Further reduced to prevent overflow
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        final amounts = [100, 150, 200, 250, 300, 500];
                        final amount = amounts[index];
                        return GestureDetector(
                          onTap: () {
                            _recordWaterIntake(amount.toDouble());
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6), // Further reduced padding
                            decoration: BoxDecoration(
                              color: NeumorphicStyle.lightBlue, // #E8F4FD
                              borderRadius:
                                  BorderRadius.circular(16), // rounded-2xl
                              border: Border.all(
                                color: NeumorphicStyle.mediumBorder, // #B8D4F0
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38, // Further reduced to 38px
                                  height: 38, // Further reduced to 38px
                                  decoration: BoxDecoration(
                                    gradient: NeumorphicStyle.primaryGradient(),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.water_drop,
                                    color: Colors.white,
                                    size: 19, // Further reduced to 19px
                                  ),
                                ),
                                const SizedBox(height: 1), // Minimal spacing
                                Text(
                                  '$amount',
                                  style: NeumorphicStyle.neumorphicText(
                                    fontSize: 13, // Further reduced to 13px
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'ml',
                                  style: NeumorphicStyle.neumorphicText(
                                    fontSize: 9, // Further reduced to 9px
                                    color: NeumorphicStyle.lightText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Custom Amount Button - matches Figma
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    24, 0, 24, 12), // px-6, mt-4, mb-3
                child: Container(
                  decoration: BoxDecoration(
                    gradient: NeumorphicStyle.primaryGradient(),
                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                    boxShadow: [
                      BoxShadow(
                        color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCustomAmountDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12), // py-3 = 12px
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Custom Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Cancel button - matches Figma
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), // px-6, pb-6
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: NeumorphicStyle.softBorder,
                      width: 2, // border-2 = 2px
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomAmountDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        // Fixed height - doesn't change with keyboard
        final dialogHeight = screenHeight * 0.45;

        return Dialog(
          insetPadding: EdgeInsets.zero,
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width - 40,
            height: dialogHeight, // Fixed height - never changes
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header - matches Figma exactly
                    Padding(
                      padding: const EdgeInsets.all(24), // p-6 = 24px
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: NeumorphicStyle.primaryGradient(),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Title and subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Custom Amount',
                                  style: NeumorphicStyle.neumorphicText(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Enter the amount of water',
                                  style: NeumorphicStyle.neumorphicText(
                                    fontSize: 14,
                                    color: NeumorphicStyle.lightText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Close button
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: NeumorphicStyle.lightText,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Custom Amount Form - matches Figma
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          24, 0, 24, 24), // px-6, mt-4, mb-6
                      child: Container(
                        decoration: BoxDecoration(
                          color: NeumorphicStyle.surfaceBlue, // #F5F9FF
                          borderRadius: BorderRadius.circular(12), // rounded-xl
                          border: Border.all(
                            color: NeumorphicStyle.softBorder,
                            width: 2,
                          ),
                        ),
                        child: Form(
                          key: formKey,
                          child: TextFormField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Enter amount',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: NeumorphicStyle.lightText,
                                fontSize: 16,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12, // py-3 = 12px
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'ml',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: NeumorphicStyle.lightText,
                                  ),
                                ),
                              ),
                            ),
                            style: NeumorphicStyle.neumorphicText(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),

                    // Action buttons - matches Figma
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          24, 0, 24, 24), // px-6, mb-6
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showCustomIntakeDialog();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: NeumorphicStyle.softBorder,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12), // py-3
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
                          const SizedBox(width: 12), // gap-3 = 12px
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: NeumorphicStyle.primaryGradient(),
                                borderRadius: BorderRadius.circular(16),
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
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    final amount =
                                        double.parse(controller.text);
                                    Navigator.of(context).pop();
                                    _recordWaterIntake(amount);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Add Water',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shows a dialog to edit an existing water intake
  void _showEditIntakeDialog(WaterIntake intake) {
    final controller =
        TextEditingController(text: intake.amount.toInt().toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: NeumorphicStyle.backgroundBlue,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Center(
                child: Text(
                  'Edit Water Intake',
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${intake.timestamp.hour.toString().padLeft(2, '0')}:${intake.timestamp.minute.toString().padLeft(2, '0')}',
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 14,
                    color: NeumorphicStyle.lightText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Amount input
              Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (ml)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: NeumorphicStyle.softBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: NeumorphicStyle.softBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: NeumorphicStyle.primaryBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(
                        color: NeumorphicStyle.primaryBlue.withOpacity(0.7)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(Colors.transparent),
                        overlayColor: WidgetStateProperty.all(
                            NeumorphicStyle.surfaceBlue.withOpacity(0.1)),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: NeumorphicStyle.neumorphicText(
                          fontSize: 16,
                          color: NeumorphicStyle.lightText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newAmount = double.parse(controller.text);
                          _updateWaterIntake(intake, newAmount);
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NeumorphicStyle.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Update',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  /// Updates an existing water intake with a new amount
  Future<void> _updateWaterIntake(WaterIntake intake, double newAmount) async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      // Store current progress for animation
      final hydrationState = ref.read(hydrationStateProvider);
      final oldProgress = hydrationState.dailyGoal > 0
          ? (hydrationState.todayIntake / hydrationState.dailyGoal)
              .clamp(0.0, double.infinity)
          : 0.0;

      // Update the water intake
      final updatedIntake = WaterIntake(
        id: intake.id,
        userId: intake.userId,
        amount: newAmount,
        timestamp: intake.timestamp,
        note: intake.note,
      );

      await ref
          .read(waterIntakeProvider.notifier)
          .updateWaterIntake(updatedIntake);

      // Animate to new progress
      final newHydrationState = ref.read(hydrationStateProvider);
      final newProgress = newHydrationState.dailyGoal > 0
          ? (newHydrationState.todayIntake / newHydrationState.dailyGoal)
              .clamp(0.0, double.infinity)
          : 0.0;

      // Animate progress with improved spring-like animation
      _progressAnimation.value = oldProgress;
      _progressAnimation.animateTo(
        newProgress,
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutBack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adService = ref.watch(adServiceProvider);

    return Scaffold(
      body: _buildBody(adService),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), // rounded-t-[20px]
            topRight: Radius.circular(20),
          ),
          boxShadow: NeumorphicStyle.bottomNavShadow(),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0, vertical: 12.0), // px-6 py-3
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, 'Home'),
                _buildNavItem(
                    1, Icons.notifications_none_outlined, 'Reminders'),
                // Center FAB - positioned above with negative margin
                Transform.translate(
                  offset: const Offset(0, -16), // -mt-8 = -32px / 2 = -16px
                  child: _buildCenterButton(),
                ),
                _buildNavItem(3, Icons.bar_chart, 'Stats'),
                _buildNavItem(4, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container - matches Figma: w-10 h-10 = 40px
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isSelected ? NeumorphicStyle.primaryGradient() : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(20), // rounded-full
            ),
            child: Transform.scale(
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : NeumorphicStyle.lightText, // #7F8C8D
                size: 20, // w-5 h-5 = 20px
              ),
            ),
          ),
          const SizedBox(height: 4), // mt-1 = 4px
          // Label - matches Figma: text-xs
          Text(
            label,
            style: TextStyle(
              fontSize: 12, // text-xs = 12px
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? NeumorphicStyle.primaryBlue
                  : NeumorphicStyle.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: _showCustomIntakeDialog,
      child: Container(
        width: 60, // w-[60px] h-[60px]
        height: 60,
        decoration: BoxDecoration(
          gradient: NeumorphicStyle.primaryGradient(),
          shape: BoxShape.circle,
          boxShadow: NeumorphicStyle.centerFabShadow(),
        ),
        child: const Icon(
          Icons.water_drop,
          color: Colors.white,
          size: 24, // w-6 h-6 = 24px
        ),
      ),
    );
  }
}
