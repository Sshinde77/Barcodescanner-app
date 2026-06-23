import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../data/api/api_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _controller = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await ApiScope.of(context).forgotPassword(email: _controller.text.trim());
      if (!mounted) return;
      setState(() => _sent = true);
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
            constraints: const BoxConstraints(maxWidth: 460),
            child: AppCard(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _sent
                    ? Column(
                        key: const ValueKey('sent'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 180,
                            child: Lottie.asset(
                              AppAssets.successAnimation,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.mark_email_read_rounded,
                                    size: 96,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ),
                          Text(
                            'Reset link sent',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check your inbox for the password reset instructions.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('form'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forgot password',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enter your email and we will show a success state after the mock submit.',
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            controller: _controller,
                            label: 'Email address',
                            prefixIcon: Icons.email_rounded,
                          ),
                          const SizedBox(height: 18),
                          CustomButton(
                            label: 'Send Reset Link',
                            loading: _loading,
                            onPressed: _send,
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/reset-password'),
                              child: const Text('Have a token? Reset password'),
                            ),
                          ),
                        ],
                      ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
        ),
      ),
    );
  }
}
