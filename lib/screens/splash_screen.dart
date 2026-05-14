// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

/// Splash Screen
///
/// Modern splash screen matching Figma design exactly.
/// Features animated logo, gradient background, and smooth transitions.
class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textOffsetAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );
    
    // Text animations
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );
    _textOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
      }
    });
    
    // Navigate to next screen after delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    
    try {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating from splash screen: $e');
      // Fallback: just replace with next screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextScreen),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: NeumorphicStyle.splashGradient(),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated Logo (centered)
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo container - matches Figma exactly
                          Container(
                            width: 128, // 32 * 4 = 128px (w-32 in Figma)
                            height: 128,
                            decoration: BoxDecoration(
                              gradient: NeumorphicStyle.primaryGradient(),
                              borderRadius: BorderRadius.circular(24), // rounded-3xl = 24px
                              boxShadow: [
                                BoxShadow(
                                  color: NeumorphicStyle.primaryBlue.withOpacity(0.4),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 80, // w-20 h-20 = 80px
                            ),
                          ),
                          const SizedBox(height: 24), // mb-6 = 24px
                          
                          // App title
                          Text(
                            'AquaPulse',
                            style: TextStyle(
                              fontSize: 36, // text-4xl = 36px
                              fontWeight: FontWeight.w900, // font-black
                              color: NeumorphicStyle.darkText,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Bottom content (tagline and loading indicator)
            Positioned(
              bottom: 80, // bottom-20 = 80px
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _textOffsetAnimation,
                    child: FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tagline - matches Figma exactly
                          Text(
                            'Stay Hydrated, Stay Healthy',
                            style: TextStyle(
                              fontSize: 18, // text-lg = 18px
                              fontWeight: FontWeight.w500, // font-medium
                              color: NeumorphicStyle.primaryBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                          
                          const SizedBox(height: 24), // gap-6 = 24px
                          
                          // Loading indicator - matches Figma exactly
                          SizedBox(
                            width: 40, // w-10 = 40px
                            height: 40, // h-10 = 40px
                            child: CircularProgressIndicator(
                              strokeWidth: 4, // border-4 = 4px
                              valueColor: AlwaysStoppedAnimation<Color>(
                                NeumorphicStyle.primaryBlue,
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
