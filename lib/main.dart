import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/introduction_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/app_providers.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wrap initialization in error handling with timeout
  try {
    // Initialize Firebase with timeout
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    debugPrint('Firebase initialized successfully');

    // Initialize Firebase service with timeout
    try {
      final firebaseService = FirebaseService();
      await firebaseService.initialize().timeout(const Duration(seconds: 5));
      debugPrint('Firebase service initialized successfully');
    } catch (e) {
      debugPrint('Firebase service initialization failed: $e');
      // Continue anyway
    }

    // Initialize notification service with timeout
    try {
      final notificationService = NotificationService();
      await notificationService
          .initialize()
          .timeout(const Duration(seconds: 5));
      await notificationService
          .requestPermissions()
          .timeout(const Duration(seconds: 5));
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Notification service initialization failed: $e');
      // Continue even if notification service fails
    }

    // Initialize ad service (with error handling)
    try {
      final adService = AdService.instance;
      await adService.initialize().timeout(const Duration(seconds: 5));
      debugPrint('Ad service initialized successfully');
    } catch (e) {
      debugPrint('Ad service initialization failed: $e');
      // Continue even if ad service fails
    }
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue anyway - app should still work without some services
  }

  runApp(const ProviderScope(child: HydrationTrackerApp()));
}

/// Builds text theme with Inter when available; falls back to platform font if
/// AssetManifest isn't ready (e.g. avoids google_fonts crash on first run / hot reload).
TextTheme _buildTextTheme() {
  const color = Color(0xFF2C3E50);
  const colorSecondary = Color(0xFF7F8C8D);
  try {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w600, color: color),
      displayMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w600, color: color),
      displaySmall: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w600, color: color),
      headlineLarge: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w600, color: color),
      headlineMedium: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, color: color),
      headlineSmall: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, color: color),
      titleSmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, color: color),
      bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: colorSecondary),
    );
  } catch (_) {
    final base = ThemeData.light().textTheme;
    return base.copyWith(
      displayLarge: base.displayLarge
          ?.copyWith(fontSize: 32, fontWeight: FontWeight.w600, color: color),
      displayMedium: base.displayMedium
          ?.copyWith(fontSize: 28, fontWeight: FontWeight.w600, color: color),
      displaySmall: base.displaySmall
          ?.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: color),
      headlineLarge: base.headlineLarge
          ?.copyWith(fontSize: 22, fontWeight: FontWeight.w600, color: color),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: color),
      headlineSmall: base.headlineSmall
          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleLarge: base.titleLarge
          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleMedium: base.titleMedium
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      titleSmall: base.titleSmall
          ?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      bodyLarge: base.bodyLarge
          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: base.bodyMedium
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: base.bodySmall?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w400, color: colorSecondary),
    );
  }
}

class HydrationTrackerApp extends ConsumerWidget {
  const HydrationTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'AquaPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              const Color(0xFF2196F3), // Blue matching dashboard gradient
          brightness: Brightness.light,
        ).copyWith(
          // Customize colors to match the neumorphic style
          primary: const Color(0xFF2196F3), // Main blue from dashboard gradient
          primaryContainer:
              const Color(0xFFE8F4FD), // Very light blue background
          secondary:
              const Color(0xFF4FC3F7), // Lighter blue from dashboard gradient
          secondaryContainer: const Color(0xFFF0F8FF), // Very light blue
          surface: const Color(0xFFFAFCFF), // Almost white with blue tint
          surfaceContainerHighest: const Color(0xFFF5F9FF), // Main background
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF2C3E50), // Dark blue-gray text
          outline: const Color(0xFFB8D4F0), // Soft blue border
          outlineVariant: const Color(0xFFE1EFF9), // Very light blue border
        ),
        textTheme: _buildTextTheme(),
        cardTheme: CardThemeData(
          elevation: 0, // No elevation for neumorphic style
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: const Color(0xFFFAFCFF),
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0, // No elevation for neumorphic style
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xFFFAFCFF),
            foregroundColor: const Color(0xFF2196F3),
            shadowColor: Colors.transparent,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: CircleBorder(),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFFFAFCFF),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Color(0xFFE1EFF9),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAFCFF),
          foregroundColor: Color(0xFF2C3E50),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Color(0xFFE1EFF9),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFCFF),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE1EFF9),
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F9FF),
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
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      themeMode: ThemeMode.light,
      home: const AppRouter(),
    );
  }
}

/// App Router that handles navigation based on introduction status and user profile
class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Wait a moment for providers to initialize
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers with error handling
    try {
      final introductionSeen = ref.watch(introductionSeenProvider);
      final currentUser = ref.watch(currentUserProvider);
      final authState = ref.watch(authProvider);

      debugPrint(
          'AppRouter: _isInitialized=$_isInitialized, introductionSeen=$introductionSeen, currentUser=${currentUser?.name}, authState=$authState');

      // Show splash screen while determining next screen
      return SplashScreen(
        nextScreen: _isInitialized
            ? _determineNextScreen(
                ref, introductionSeen, currentUser, authState)
            : const Scaffold(
                backgroundColor: Color(0xFFFAFCFF),
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error in AppRouter build: $e');
      debugPrint('Stack trace: $stackTrace');
      return Scaffold(
        backgroundColor: const Color(0xFFFAFCFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }
  }

  // Helper method to determine which screen to show next
  Widget _determineNextScreen(WidgetRef ref, bool introductionSeen,
      dynamic currentUser, AuthState authState) {
    try {
      debugPrint(
          '_determineNextScreen: introductionSeen=$introductionSeen, currentUser=${currentUser?.name}, authState=$authState');

      // If auth is still loading, show loading screen
      if (authState == AuthState.loading) {
        debugPrint('Showing loading screen (auth loading)');
        return const Scaffold(
          backgroundColor: Color(0xFFFAFCFF),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2196F3),
            ),
          ),
        );
      }

      // Show introduction screen if user hasn't seen it
      if (!introductionSeen) {
        debugPrint('Showing IntroductionScreen');
        return const IntroductionScreen();
      }

      // Show dashboard if user has a profile (check this first, even for local users)
      if (currentUser != null) {
        debugPrint('Showing DashboardScreen');
        return const DashboardScreen();
      }

      // If authenticated but no profile exists, show onboarding (first time login/signup)
      if (authState == AuthState.authenticated) {
        debugPrint('Showing OnboardingScreen (authenticated but no profile)');
        return const OnboardingScreen();
      }

      // If unauthenticated, show login screen
      debugPrint('Showing LoginScreen (unauthenticated)');
      return const LoginScreen();
    } catch (e, stackTrace) {
      debugPrint('Error in _determineNextScreen: $e');
      debugPrint('Stack trace: $stackTrace');
      return Scaffold(
        backgroundColor: const Color(0xFFFAFCFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Navigation Error: $e',
                  style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }
  }
}
