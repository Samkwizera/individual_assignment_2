import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _checkTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Poll for verification every 4 seconds
    _checkTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    final verified =
        await context.read<AuthProvider>().checkEmailVerification();
    if (verified && mounted) {
      _checkTimer?.cancel();
      // Navigation handled by auth state listener in main.dart
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    final success =
        await context.read<AuthProvider>().resendVerificationEmail();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Verification email resent! Check your inbox.'
          : context.read<AuthProvider>().errorMessage ??
              'Failed to resend email.'),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));

    if (success) {
      setState(() => _resendCooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) t.cancel();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () async {
            await context.read<AuthProvider>().signOut();
            if (mounted) Navigator.pop(context);
          },
        ),
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.accent,
                  size: 52,
                ),
              ),
              const SizedBox(height: 32),
              const Text('Check Your Email', style: AppTextStyles.heading1),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.email,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Click the link in your email to verify your account. '
                'This page will update automatically once verified.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Auto-checking indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.accent.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Waiting for verification...',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Check Now Button
              OutlinedButton(
                onPressed: authProv.isLoading ? null : _checkVerification,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColors.accent),
                  foregroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('I\'ve Verified My Email'),
              ),
              const SizedBox(height: 16),

              // Resend button
              TextButton(
                onPressed: _resendCooldown > 0 ? null : _resendEmail,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend in ${_resendCooldown}s'
                      : 'Resend Verification Email',
                  style: TextStyle(
                    color: _resendCooldown > 0
                        ? AppColors.textSecondary
                        : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
