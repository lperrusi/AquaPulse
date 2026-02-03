/// Forgot Password Screen
///
/// Allows users to request password reset emails by entering their email address.
/// Provides form validation and success/error feedback.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../utils/neumorphic_style.dart';
import 'login_screen.dart';

/// The main ForgotPasswordScreen widget for password reset requests
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Success state - matches Figma
    if (_isSuccess) {
      return Scaffold(
        backgroundColor: NeumorphicStyle.backgroundBlue,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon - matches Figma: w-20 h-20 rounded-full
                  Container(
                    width: 80, // w-20 = 80px
                    height: 80,
                    decoration: BoxDecoration(
                      color: NeumorphicStyle.lightBlue, // #E8F4FD
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: NeumorphicStyle.primaryBlue,
                      size: 48, // w-12 h-12 = 48px
                    ),
                  ),
                  const SizedBox(height: 24), // mb-6 = 24px
                  
                  // Success Title - matches Figma: text-2xl font-bold
                  Text(
                    'Email Sent!',
                    style: TextStyle(
                      fontSize: 24, // text-2xl = 24px
                      fontWeight: FontWeight.bold,
                      color: NeumorphicStyle.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12), // mb-3 = 12px
                  
                  // Success Message - matches Figma
                  Text(
                    'We\'ve sent password reset instructions to ${_emailController.text}. Please check your inbox and follow the link to reset your password.',
                    style: TextStyle(
                      fontSize: 16,
                      color: NeumorphicStyle.lightText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32), // mb-8 = 32px
                  
                  // Back to Login Button - matches Figma
                  Container(
                    decoration: BoxDecoration(
                      gradient: NeumorphicStyle.primaryGradient(),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _navigateToLogin(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back to Login',
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
            ),
          ),
        ),
      );
    }

    // Form state - matches Figma
    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button - matches Figma
            Padding(
              padding: const EdgeInsets.all(24), // p-6 = 24px
              child: Align(
                alignment: Alignment.topLeft,
                child: TextButton.icon(
                  onPressed: () => _navigateToLogin(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: NeumorphicStyle.primaryBlue,
                    size: 20, // w-5 h-5 = 20px
                  ),
                  label: Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: NeumorphicStyle.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
            
            // Form content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // px-6 pb-12
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon - matches Figma: w-20 h-20 rounded-full
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: NeumorphicStyle.lightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline,
                            color: NeumorphicStyle.primaryBlue,
                            size: 40, // w-10 h-10 = 40px
                          ),
                        ),
                        const SizedBox(height: 24), // mb-6 = 24px
                        
                        // Title - matches Figma: text-2xl font-bold
                        Text(
                          'Reset Your Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: NeumorphicStyle.darkText,
                          ),
                        ),
                        const SizedBox(height: 12), // mb-3 = 12px
                        
                        // Description - matches Figma
                        Text(
                          'Enter your email address and we\'ll send you instructions to reset your password.',
                          style: TextStyle(
                            fontSize: 16,
                            color: NeumorphicStyle.lightText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32), // mb-8 = 32px
                        
                        // Email form
                        _buildEmailForm(),
                        
                        const SizedBox(height: 16), // space-y-4 = 16px
                        
                        // Submit button
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              borderSide: BorderSide(color: NeumorphicStyle.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: NeumorphicStyle.surfaceBlue,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: NeumorphicStyle.primaryGradient(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                'Send Reset Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref.read(authProvider.notifier).forgotPassword(
        _emailController.text.trim(),
      );

      if (result.success) {
        setState(() {
          _isSuccess = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Password reset email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Failed to send reset email';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while sending the reset email';
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