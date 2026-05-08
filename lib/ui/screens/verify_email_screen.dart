import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Screen shown when user has signed up but not yet verified their email.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isSending = false;
  bool _isChecking = false;

  Future<void> _resendVerification() async {
    setState(() => _isSending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send email. Try again later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      await ref.read(authServiceProvider).reloadUser();
      // Invalidate auth state to trigger router redirect
      ref.invalidate(authStateProvider);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.secondaryYellow,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to your email. Please check your inbox and click the link to verify your account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isChecking ? null : _checkVerification,
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('I VERIFIED MY EMAIL'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSending ? null : _resendVerification,
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                },
                child: const Text('Sign out and use different account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
