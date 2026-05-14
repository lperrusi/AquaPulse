import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydration_tracker/screens/forgot_password_screen.dart';
import 'package:hydration_tracker/screens/reset_password_update_screen.dart';
import 'package:hydration_tracker/screens/verify_reset_code_screen.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('forgot password validates invalid email', (tester) async {
    await tester.pumpWidget(_buildTestApp(const ForgotPasswordScreen()));

    expect(find.text('Send Verification Code'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.tap(find.text('Send Verification Code'));
    await tester.pump();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('verify code validates six digits', (tester) async {
    await tester.pumpWidget(
        _buildTestApp(const VerifyResetCodeScreen(email: 'user@test.com')));

    await tester.enterText(find.byType(TextFormField).first, '123');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter a valid 6-digit code'), findsOneWidget);
  });

  testWidgets('reset password requires matching confirmation', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const ResetPasswordUpdateScreen(
          email: 'user@test.com',
          resetSessionToken: 'token',
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'newpass123');
    await tester.enterText(find.byType(TextFormField).at(1), 'different123');
    await tester.tap(find.text('Update Password'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
