/// Register Screen
///
/// Provides user registration with comprehensive form validation,
/// profile setup, and navigation to login after successful registration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../utils/neumorphic_style.dart';
import '../main.dart';
import 'login_screen.dart';

/// The main RegisterScreen widget for user registration
class RegisterScreen extends ConsumerStatefulWidget {
  final String? preFilledEmail;
  final String? preFilledName;
  final double? preFilledWeight;
  final ActivityLevel? preFilledActivityLevel;

  const RegisterScreen({
    super.key,
    this.preFilledEmail,
    this.preFilledName,
    this.preFilledWeight,
    this.preFilledActivityLevel,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // Profile fields
  int? _selectedAge;
  double? _selectedWeight;
  String? _selectedGender;
  String? _selectedActivityLevel;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if provided
    if (widget.preFilledEmail != null) {
      _emailController.text = widget.preFilledEmail!;
    }
    if (widget.preFilledName != null) {
      _nameController.text = widget.preFilledName!;
    }
    if (widget.preFilledWeight != null) {
      _selectedWeight = widget.preFilledWeight;
    }
    if (widget.preFilledActivityLevel != null) {
      _selectedActivityLevel = widget.preFilledActivityLevel!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate to AppRouter if already authenticated (will determine if onboarding or dashboard)
    if (authState == AuthState.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppRouter()),
        );
      });
    }

    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue, // #FAFCFF
      body: SafeArea(
        child: Column(
          children: [
            // Back button at top left
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NeumorphicStyle.surfaceBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: NeumorphicStyle.primaryBlue,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16), // px-6 py-4
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header - matches Figma exactly
                      _buildHeader(),

                      const SizedBox(height: 32), // mb-8 = 32px

                      // Registration form - matches Figma
                      _buildRegistrationForm(),

                      const SizedBox(height: 24), // mt-6 = 24px

                      // Register button
                      _buildRegisterButton(),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: NeumorphicStyle.lightText
                                      .withOpacity(0.5))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: NeumorphicStyle.lightText,
                                    fontWeight: FontWeight.w500)),
                          ),
                          Expanded(
                              child: Divider(
                                  color: NeumorphicStyle.lightText
                                      .withOpacity(0.5))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGoogleSignInButton(),
                      const SizedBox(height: 16), // pt-4 = 16px

                      // Login link
                      _buildLoginLink(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App icon - matches Figma: w-[60px] h-[60px] rounded-[15px]
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: NeumorphicStyle.primaryGradient(),
            borderRadius: BorderRadius.circular(15), // rounded-[15px]
            boxShadow: [
              BoxShadow(
                color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.water_drop,
            color: Colors.white,
            size: 32, // w-8 h-8 = 32px
          ),
        ),

        const SizedBox(height: 16), // mb-4 = 16px

        // Title - matches Figma: text-xl font-bold
        Text(
          'Join AquaPulse',
          style: TextStyle(
            fontSize: 20, // text-xl = 20px
            fontWeight: FontWeight.bold,
            color: NeumorphicStyle.darkText,
          ),
        ),

        const SizedBox(height: 8), // mb-2 = 8px

        // Subtitle - matches Figma: text-sm
        Text(
          'Create your account to start tracking your hydration',
          style: TextStyle(
            fontSize: 14, // text-sm = 14px
            color: NeumorphicStyle.lightText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field - matches Figma
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Full Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NeumorphicStyle.darkText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            prefixIcon: Icon(
              Icons.person_outline,
              color: NeumorphicStyle.lightText,
              size: 20,
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
              return 'Please enter your name';
            }
            if (value.length < 2) {
              return 'Name must be at least 2 characters long';
            }
            return null;
          },
        ),

        const SizedBox(height: 16), // space-y-4 = 16px

        // Email field - matches Figma
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NeumorphicStyle.darkText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: Icon(
              Icons.mail_outline,
              color: NeumorphicStyle.lightText,
              size: 20,
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
              return 'Please enter your email';
            }
            if (!_isValidEmail(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Password field - matches Figma
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
            hintText: 'Create a password',
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
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters long';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Confirm password field - matches Figma
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Confirm Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NeumorphicStyle.darkText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Confirm your password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: NeumorphicStyle.lightText,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: NeumorphicStyle.lightText,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
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
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),

        // Error message - matches Figma
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: const Color(0xFFDC2626),
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

  Widget _buildRegisterButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: NeumorphicStyle.primaryGradient(),
        borderRadius: BorderRadius.circular(12), // rounded-xl
        boxShadow: [
          BoxShadow(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16), // py-4
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
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
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
      if (!result.success)
        setState(
            () => _errorMessage = result.message ?? 'Google sign-in failed');
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred during sign-in');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 16,
            color: NeumorphicStyle.lightText,
          ),
        ),
        TextButton(
          onPressed: () => _navigateToLogin(),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            age: null, // Profile setup moved to onboarding
            weight: null,
            gender: null,
            activityLevel: null,
          );

      if (result.success) {
        // Registration successful, navigation will be handled by the build method
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during registration';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}
