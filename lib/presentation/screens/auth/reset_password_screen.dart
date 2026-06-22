import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/api_provider.dart';
import '../../../data/api/api_models.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiScope.of(context).resetPassword(
        PasswordResetRequest(
          token: _tokenController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmController.text,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully')),
      );
      context.go('/login');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset password',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the token from the email reset link to set a new password.',
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      controller: _tokenController,
                      label: 'Reset token',
                      prefixIcon: Icons.vpn_key_rounded,
                      validator: (value) =>
                          (value == null || value.isEmpty)
                          ? 'Enter reset token'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email address',
                      prefixIcon: Icons.email_rounded,
                      validator: (value) =>
                          (value == null || !value.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'New password',
                      prefixIcon: Icons.lock_rounded,
                      obscureText: true,
                      validator: (value) =>
                          (value == null || value.length < 6)
                          ? 'Enter at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _confirmController,
                      label: 'Confirm password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      validator: (value) =>
                          (value == null || value.isEmpty)
                          ? 'Confirm your password'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      label: 'Reset Password',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Back to Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
          ),
        ),
      ),
    );
  }
}
