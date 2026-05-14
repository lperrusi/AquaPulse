library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../providers/app_providers.dart';
import '../utils/neumorphic_style.dart';

class ResetPasswordUpdateScreen extends ConsumerStatefulWidget {
  final String email;
  final String resetSessionToken;

  const ResetPasswordUpdateScreen({
    super.key,
    required this.email,
    required this.resetSessionToken,
  });

  @override
  ConsumerState<ResetPasswordUpdateScreen> createState() =>
      _ResetPasswordUpdateScreenState();
}

class _ResetPasswordUpdateScreenState
    extends ConsumerState<ResetPasswordUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: NeumorphicStyle.primaryBlue,
        title: const Text('Create New Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set your new password for ${widget.email}',
                  style: TextStyle(color: NeumorphicStyle.lightText),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (value) {
                    if ((value ?? '').length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitPasswordUpdate,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitPasswordUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final resetResult = await authNotifier.confirmPasswordResetWithCode(
        email: widget.email,
        resetSessionToken: widget.resetSessionToken,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      if (!resetResult.success) {
        setState(() {
          _errorMessage = resetResult.message ?? 'Unable to update password.';
        });
        return;
      }

      final loginResult = await authNotifier.login(
        widget.email,
        _newPasswordController.text,
      );

      if (!mounted) return;

      if (!loginResult.success) {
        setState(() {
          _errorMessage =
              'Password updated, but auto-login failed. Please log in.';
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppRouter()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
}
