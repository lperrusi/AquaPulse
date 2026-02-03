/// Login Screen
///
/// Provides user authentication with email/password login, registration option,
/// and forgot password functionality. Handles form validation and error display.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';
import '../main.dart';
import '../utils/neumorphic_style.dart';

/// The main LoginScreen widget for user authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    // Navigate to dashboard if already authenticated
    if (authState == AuthState.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppRouter()),
        );
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App logo and title
                      _buildHeader(theme),

                      const SizedBox(height: 48),

                      // Login form
                      _buildLoginForm(theme),

                      const SizedBox(height: 24),

                      // Login button
                      _buildLoginButton(theme),

                      const SizedBox(height: 20),

                      // Or divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: NeumorphicStyle.lightText
                                      .withOpacity(0.5))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                fontSize: 14,
                                color: NeumorphicStyle.lightText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: NeumorphicStyle.lightText
                                      .withOpacity(0.5))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Sign in with Google
                      _buildGoogleSignInButton(theme),

                      const SizedBox(height: 16),

                      // Forgot password link
                      _buildForgotPasswordLink(theme),

                      const Spacer(),

                      // Register link
                      _buildRegisterLink(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // App icon - matches Figma: w-20 h-20 rounded-[20px]
        Container(
          width: 80, // w-20 = 80px
          height: 80,
          decoration: BoxDecoration(
            gradient: NeumorphicStyle.primaryGradient(),
            borderRadius: BorderRadius.circular(20), // rounded-[20px]
            boxShadow: [
              BoxShadow(
                color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.water_drop,
            color: Colors.white,
            size: 48, // w-12 h-12 = 48px
          ),
        ),

        const SizedBox(height: 16), // mb-4 = 16px

        // App title - matches Figma: text-2xl font-bold
        Text(
          'AquaPulse',
          style: TextStyle(
            fontSize: 24, // text-2xl = 24px
            fontWeight: FontWeight.bold,
            color: NeumorphicStyle.primaryBlue,
          ),
        ),

        const SizedBox(height: 8), // mb-2 = 8px

        // Subtitle - matches Figma: text-base
        Text(
          'Stay hydrated, stay healthy',
          style: TextStyle(
            fontSize: 16, // text-base = 16px
            color: NeumorphicStyle.lightText,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email field - matches Figma exactly
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Email',
            style: TextStyle(
              fontSize: 14, // text-sm = 14px
              fontWeight: FontWeight.w500, // font-medium
              color: NeumorphicStyle.darkText,
            ),
          ),
        ),
        const SizedBox(height: 8), // mb-2 = 8px
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: Icon(
              Icons.mail_outline,
              color: NeumorphicStyle.lightText,
              size: 20, // w-5 h-5 = 20px
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // rounded-xl = 12px
              borderSide: BorderSide(color: NeumorphicStyle.softBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: NeumorphicStyle.softBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: NeumorphicStyle.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: NeumorphicStyle.surfaceBlue, // #F5F9FF
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintStyle: TextStyle(color: NeumorphicStyle.lightText),
          ),
          style: TextStyle(color: NeumorphicStyle.darkText),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!_isValidEmail(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),

        const SizedBox(height: 16), // space-y-4 = 16px

        // Password field - matches Figma exactly
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NeumorphicStyle.darkText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: NeumorphicStyle.lightText,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: NeumorphicStyle.lightText,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
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
              borderSide:
                  BorderSide(color: NeumorphicStyle.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: NeumorphicStyle.surfaceBlue,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintStyle: TextStyle(color: NeumorphicStyle.lightText),
          ),
          style: TextStyle(color: NeumorphicStyle.darkText),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),

        // Error message - matches Figma
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12), // p-3 = 12px
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2), // Error background
              borderRadius: BorderRadius.circular(12), // rounded-xl
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: const Color(0xFFDC2626), // Error color
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoginButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: NeumorphicStyle.primaryGradient(),
        borderRadius: BorderRadius.circular(12), // rounded-xl = 12px
        boxShadow: [
          BoxShadow(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16), // py-4 = 16px
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // font-semibold
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.black87),
      label: const Text('Sign in with Google'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: NeumorphicStyle.softBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: NeumorphicStyle.darkText,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await ref.read(authProvider.notifier).loginWithGoogle();
      if (!result.success) {
        setState(
            () => _errorMessage = result.message ?? 'Google sign-in failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred during sign-in');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildForgotPasswordLink(ThemeData theme) {
    return TextButton(
      onPressed: () => _navigateToForgotPassword(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8), // py-2 = 8px
      ),
      child: Text(
        'Forgot Password?',
        style: TextStyle(
          fontSize: 16, // text-base = 16px
          fontWeight: FontWeight.w500, // font-medium
          color: NeumorphicStyle.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildRegisterLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            fontSize: 16,
            color: NeumorphicStyle.lightText,
          ),
        ),
        TextButton(
          onPressed: () => _navigateToRegister(),
          child: Text(
            'Sign Up',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600, // font-semibold
              color: NeumorphicStyle.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (result.success) {
        // Login successful, navigation will be handled by the build method
        // Success banner removed per user request
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during login';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }
}
