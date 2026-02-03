/// Introduction Screen
///
/// Displays an engaging introduction to the app's features for first-time users.
/// Uses a page view with smooth animations and clear feature explanations.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/app_providers.dart';
import '../utils/neumorphic_style.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

/// The main IntroductionScreen widget for showcasing app features to new users
class IntroductionScreen extends ConsumerStatefulWidget {
  const IntroductionScreen({super.key});

  @override
  ConsumerState<IntroductionScreen> createState() => _IntroductionScreenState();
}

/// State class for IntroductionScreen. Handles page navigation and animations.
class _IntroductionScreenState extends ConsumerState<IntroductionScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroductionPage> _pages = [
    IntroductionPage(
      title: 'AquaPulse',
      subtitle: 'Stay Hydrated,\nStay Healthy',
      description: 'Track your daily water intake\nand develop healthy\nhydration habits',
      showLogo: true,
      hasWaveBackground: true,
    ),
    IntroductionPage(
      title: 'Track Your Hydration',
      subtitle: 'Monitor your daily water intake with our intuitive tracking system',
      description: '',
      hasProgressCircle: true,
      hasWaveBackground: false,
    ),
    IntroductionPage(
      title: 'Never Forget\nto Hydrate',
      subtitle: 'Set personalized reminders to stay hydrated throughout your day',
      description: '',
      hasReminders: true,
      hasWaveBackground: true,
    ),
    IntroductionPage(
      title: 'Track Your Progress',
      subtitle: 'View your hydration history and achievements to stay motivated',
      description: '',
      hasStatsPreview: true,
      hasWaveBackground: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _getStarted();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _getStarted() async {
    // Mark introduction as seen
    await ref.read(introductionSeenProvider.notifier).markAsSeen();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _skipToOnboarding() async {
    // Mark introduction as seen even when skipping
    await ref.read(introductionSeenProvider.notifier).markAsSeen();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: NeumorphicStyle.splashGradient(),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Content with SafeArea
            SafeArea(
              child: Column(
                children: [
                  // Skip button (top right)
                  if (_currentPage < _pages.length - 1)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton(
                            onPressed: _skipToOnboarding,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: NeumorphicStyle.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _buildPage(_pages[index], theme);
                      },
                    ),
                  ),
                  
                  // Bottom navigation
                  _buildBottomNavigation(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(IntroductionPage page, ThemeData theme) {
    // Check if this is the last page (no Skip button)
    final isLastPage = _currentPage == _pages.length - 1;
    
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add top padding on last page to match Skip button space
              // Skip button area: Padding(24px top) + button height (~48px) = ~72px
              // Adding slightly more to account for visual spacing
              if (isLastPage)
                const SizedBox(height: 80.0),
                  // Logo - matches Figma exactly
                  if (page.showLogo) ...[  
                    Container(
                      width: 200,
                      height: 200,
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
                        Icons.water_drop,
                        color: Colors.white,
                        size: 128,
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                  
                  // Progress Circle
                  if (page.hasProgressCircle) ...[  
                    _buildDemoInterface(),
                  ],
                  
                  // Reminders
                  if (page.hasReminders) ...[  
                    _buildReminderIllustration(),
                    const SizedBox(height: 50),
                    _buildReminderDemo(),
                  ],
                  
                  // Stats Preview
                  if (page.hasStatsPreview) ...[  
                    _buildStatsPreview(),
                    const SizedBox(height: 40),
                  ],
                  
                  // Title and text content - matches Figma exactly
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Column(
                      children: [
                        // Title - matches Figma: text-[42px] font-black
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: NeumorphicStyle.darkText,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        if (page.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          // Subtitle - matches Figma: text-2xl font-bold
                          Text(
                            page.subtitle,
                            style: const TextStyle(
                              fontSize: 24,
                              color: NeumorphicStyle.darkText,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        
                        if (page.description.isNotEmpty) ...[  
                          const SizedBox(height: 16),
                          // Description - matches Figma: text-lg
                          Text(
                            page.description,
                            style: const TextStyle(
                              fontSize: 18,
                              color: NeumorphicStyle.darkText,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
  
  // Demo Interface for Track Your Hydration page - matches Figma exactly
  Widget _buildDemoInterface() {
    return Container(
      width: 150, // Increased from 120px to 150px
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(16), // p-4 = 16px padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Small progress circle - increased from 80x80px to 100x100px
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: CustomPaint(
                    painter: _ProgressCirclePainter(
                      progress: 0.44, // 44% as shown in Figma
                      backgroundColor: NeumorphicStyle.lightBlue,
                      progressColor: NeumorphicStyle.primaryBlue,
                      strokeWidth: 8,
                    ),
                  ),
                ),
                // Center text
                Text(
                  '44%',
                  style: TextStyle(
                    fontSize: 18, // Increased from 14 to 18 to match larger circle
                    fontWeight: FontWeight.bold,
                    color: NeumorphicStyle.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12), // gap-3 = 12px
          // Buttons - increased size to match larger container (118px available: 150 - 32 padding)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glass button
              Container(
                width: 57, // Adjusted for larger container: (118 - 4) / 2 = 57px per button
                height: 30,
                decoration: BoxDecoration(
                  color: NeumorphicStyle.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: NeumorphicStyle.primaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 4), // Minimal spacing
              // Add button
              Container(
                width: 57, // Adjusted for larger container: (118 - 4) / 2 = 57px per button
                height: 30,
                decoration: BoxDecoration(
                  color: NeumorphicStyle.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NeumorphicStyle.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Reminder Illustration for Never Forget to Hydrate page
  Widget _buildReminderIllustration() {
    return const SizedBox.shrink(); // Removed bell icons from top
  }
  
  // Reminder Demo for Never Forget to Hydrate page - matches Figma exactly
  Widget _buildReminderDemo() {
    return Column(
      children: [
        // Notification demo - increased from 200px to 250px width, rounded-2xl
        Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: NeumorphicStyle.primaryBlue.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: NeumorphicStyle.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time to',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NeumorphicStyle.darkText,
                      ),
                    ),
                    Text(
                      'drink water',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NeumorphicStyle.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Reminder options - matches Figma exactly
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildReminderOption('Morning', '☀️'),
            const SizedBox(width: 8),
            _buildReminderOption('Lunch', '🍽️'),
            const SizedBox(width: 8),
            _buildReminderOption('Evening', '🌙'),
            const SizedBox(width: 8),
            _buildReminderOption('Hourly', '⏰'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildReminderOption(String label, String emoji) {
    return Column(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: NeumorphicStyle.primaryBlue, width: 2),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: NeumorphicStyle.lightText,
          ),
        ),
      ],
    );
  }
  
  // Stats Preview for Track Your Progress page - increased from 120x120px to 150x150px
  Widget _buildStatsPreview() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - matches Figma: rounded-t-lg, px-2 py-1
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: NeumorphicStyle.primaryBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Text(
                'Weekly',
                style: TextStyle(
                  fontSize: 10, // text-[10px]
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8), // mb-2 = 8px
          // Progress text - matches Figma: text-[10px] font-semibold
          Text(
            '1400 / 2000 ml',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: NeumorphicStyle.primaryBlue,
            ),
          ),
          const SizedBox(height: 8), // mb-2 = 8px
          // Bar chart - matches Figma exactly
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('M', 0.6),
                  _buildBar('T', 0.8),
                  _buildBar('W', 0.7),
                  _buildBar('T', 0.9),
                  _buildBar('F', 0.75),
                  _buildBar('S', 0.5),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  Widget _buildBar(String label, double height) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            height: 40 * height,
            decoration: BoxDecoration(
              gradient: NeumorphicStyle.primaryGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: NeumorphicStyle.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 48), // pb-12 = 48px
      child: Column(
        children: [
          // Page indicators - matches Figma exactly
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? NeumorphicStyle.primaryBlue
                      : Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24), // mb-6 = 24px
          
          // Navigation buttons - matches Figma exactly
          Row(
            children: [
              // Back button
              if (_currentPage > 0)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: NeumorphicStyle.primaryBlue,
                        width: 2,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.chevron_left, size: 20),
                      label: const Text('Back'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        foregroundColor: NeumorphicStyle.primaryBlue,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              
              if (_currentPage > 0) const SizedBox(width: 12),
              
              // Next/Get Started button - matches Figma exactly
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: NeumorphicStyle.primaryGradient(),
                    boxShadow: [
                      BoxShadow(
                        color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _nextPage,
                    icon: const Icon(Icons.chevron_right, size: 20),
                    label: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for progress circle in introduction screen
class _ProgressCirclePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;
  
  _ProgressCirclePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Data class for introduction page content
class IntroductionPage {
  final String title;
  final String subtitle;
  final String description;
  final bool showLogo;
  final bool hasProgressCircle;
  final bool hasReminders;
  final bool hasStatsPreview;
  final bool hasWaveBackground;

  IntroductionPage({
    required this.title,
    required this.subtitle,
    required this.description,
    this.showLogo = false,
    this.hasProgressCircle = false,
    this.hasReminders = false,
    this.hasStatsPreview = false,
    this.hasWaveBackground = false,
  });
}



