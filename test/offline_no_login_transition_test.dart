import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydration_tracker/main.dart';
import 'package:hydration_tracker/screens/introduction_screen.dart';
import 'package:hydration_tracker/screens/login_screen.dart';
import 'package:hydration_tracker/screens/onboarding_screen.dart';
import 'package:hydration_tracker/screens/social_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Offline first start routing', () {
    test('returns introduction when intro was not seen', () {
      final destination = determineAppStartDestination(
        introductionSeen: false,
        hasLocalUser: false,
      );

      expect(destination, AppStartDestination.introduction);
    });

    test('returns onboarding when intro seen and no local user', () {
      final destination = determineAppStartDestination(
        introductionSeen: true,
        hasLocalUser: false,
      );

      expect(destination, AppStartDestination.onboarding);
    });

    test('returns dashboard when intro seen and local user exists', () {
      final destination = determineAppStartDestination(
        introductionSeen: true,
        hasLocalUser: true,
      );

      expect(destination, AppStartDestination.dashboard);
    });
  });

  testWidgets('social screen shows account-disabled notice in offline mode',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SocialScreen(),
        ),
      ),
    );

    expect(find.text('Account features are temporarily disabled.'),
        findsOneWidget);
    expect(
      find.text(
          'Friends, challenges, and leaderboards will return when cloud mode is enabled.'),
      findsOneWidget,
    );
  });

  testWidgets('introduction skip enters onboarding instead of login',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: IntroductionScreen(),
        ),
      ),
    );

    final skipButton =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Skip'));
    skipButton.onPressed?.call();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
