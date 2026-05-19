import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/introduction_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/app_providers.dart';
import 'services/notification_service.dart';
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
    if (kDebugMode) debugPrint('Firebase initialized successfully');

    // Initialize Firebase service with timeout
    try {
      final firebaseService = FirebaseService();
      await firebaseService.initialize().timeout(const Duration(seconds: 5));
      if (kDebugMode) debugPrint('Firebase service initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase service initialization failed: $e');
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
      if (kDebugMode) {
        debugPrint('Notification service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification service initialization failed: $e');
      }
      // Continue even if notification service fails
    }

  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('Error during initialization: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    // Continue anyway - app should still work without some services
  }

  runApp(const ProviderScope(child: HydrationTrackerApp()));
}

/// Builds app text theme from platform fonts.
TextTheme _buildTextTheme() {
  final base = ThemeData.light().textTheme;
  const color = Color(0xFF2C3E50);
  const colorSecondary = Color(0xFF7F8C8D);
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

enum AppStartDestination {
  introduction,
  onboarding,
  dashboard,
}

AppStartDestination determineAppStartDestination({
  required bool introductionSeen,
  required bool hasLocalUser,
}) {
  if (!introductionSeen) {
    return AppStartDestination.introduction;
  }
  if (hasLocalUser) {
    return AppStartDestination.dashboard;
  }
  return AppStartDestination.onboarding;
}

/// App Router that handles navigation based on introduction status and user profile
class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {
  final Completer<Widget> _nextScreenCompleter = Completer<Widget>();

  @override
  void initState() {
    super.initState();
    _waitForProviders();
  }

  Future<void> _waitForProviders() async {
    // Start AdMob init in the background — runs during the splash delay.
    // AdService handles its own errors; not awaited so it never blocks routing.
    unawaited(AdService.instance.initialize());

    try {
      await Future.wait([
        Future.delayed(const Duration(seconds: 3)),
        ref.read(introductionSeenProvider.notifier).initialLoadDone,
        ref.read(currentUserProvider.notifier).initialLoadDone,
      ]);
      final introductionSeen = ref.read(introductionSeenProvider);
      final currentUser = ref.read(currentUserProvider);
      _nextScreenCompleter.complete(
        _determineNextScreen(ref, introductionSeen, currentUser),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error waiting for startup providers: $e');
      _nextScreenCompleter.complete(const OnboardingScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(nextScreenFuture: _nextScreenCompleter.future);
  }

  // Helper method to determine which screen to show next
  Widget _determineNextScreen(
      WidgetRef ref, bool introductionSeen, dynamic currentUser) {
    try {
      if (kDebugMode) {
        debugPrint(
            '_determineNextScreen: introductionSeen=$introductionSeen, hasCurrentUser=${currentUser != null}');
      }

      final destination = determineAppStartDestination(
        introductionSeen: introductionSeen,
        hasLocalUser: currentUser != null,
      );

      switch (destination) {
        case AppStartDestination.introduction:
          if (kDebugMode) debugPrint('Showing IntroductionScreen');
          return const IntroductionScreen();
        case AppStartDestination.dashboard:
          if (kDebugMode) debugPrint('Showing DashboardScreen');
          return const DashboardScreen();
        case AppStartDestination.onboarding:
          if (kDebugMode) debugPrint('Showing OnboardingScreen');
          return const OnboardingScreen();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error in _determineNextScreen: $e');
        debugPrint('Stack trace: $stackTrace');
      }
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
