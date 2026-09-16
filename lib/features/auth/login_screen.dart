import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/connectivity_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'auth_design.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();

  bool _otpSent = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final connectivity = ConnectivityService();
    final isOnline = await connectivity.isConnected();
    if (!isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      setState(() => _isSubmitting = false);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success =
        await authProvider.requestEmailOtp(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      setState(() {
        _otpSent = true;
        _otpController.clear();
      });
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _otpFocusNode.requestFocus());
    } else {
      final isNewAccount = authProvider.authActionCode == 'PROFILE_REQUIRED';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNewAccount
              ? 'No account found for this email. Please create an account.'
              : authProvider.errorMessage ?? 'Failed to send OTP'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_isSubmitting) return;
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the 6-digit OTP'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final success =
        await authProvider.verifyEmailOtp(_emailController.text.trim(), otp);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Invalid OTP'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _continueAsGuest() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();
    await authProvider.continueAsGuest();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/dashboard', (route) => false);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AuthShell(
      title: 'Welcome back',
      subtitle: _otpSent
          ? 'Enter the OTP sent to your email.\nNo password needed.'
          : 'Login with your email using a one-time code.\nNo password needed.',
      heroIcon: Icons.sports_cricket_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_otpSent) ...[
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: AuthDesign.input(
                  label: 'Email address',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter email';
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Enter valid email';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _sendOtp(),
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                onPressed: _sendOtp,
                label: 'Send OTP',
                loading: _isSubmitting || auth.status == AuthStatus.loading,
                icon: Icons.send_rounded,
                trailingArrow: true,
              ),
            ] else ...[
              AuthSuccessBanner(
                title: 'Enter the OTP sent to',
                description: _emailController.text.trim(),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: AuthDesign.input(
                  label: 'OTP code',
                  hint: 'Enter 6-digit code',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(counterText: ''),
                onFieldSubmitted: (_) => _verifyOtp(),
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                onPressed: _verifyOtp,
                label: 'Verify and sign in',
                loading: _isSubmitting || auth.status == AuthStatus.loading,
                icon: Icons.shield_rounded,
                trailingArrow: true,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _isSubmitting ? null : _sendOtp,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text(
                      'Resend OTP',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Container(width: 1, height: 16, color: AuthDesign.line),
                  TextButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                              _otpSent = false;
                              _otpController.clear();
                            }),
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: const Text('Change email'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const AuthDivider(),
            const SizedBox(height: 18),
            AuthOutlineButton(
              onPressed: () => Navigator.pushNamed(context, '/phone-login'),
              label: 'Login or register with mobile OTP',
              icon: Icons.chat_bubble_outline_rounded,
            ),
            const SizedBox(height: 12),
            AuthOutlineButton(
              onPressed: (auth.status == AuthStatus.loading || _isSubmitting)
                  ? null
                  : _continueAsGuest,
              label: 'Continue as guest',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 22),
            const Center(
              child: AuthSecurityNote(text: 'Secure, fast and password-free'),
            ),
          ],
        ),
      ),
      belowCard: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'New to Scores11? ',
                style: TextStyle(
                  color: AuthDesign.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text(
                  'Create account',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const AuthFeatureStrip(items: [
            AuthFeatureItem(Icons.verified_user_rounded, 'Secure\nLogin'),
            AuthFeatureItem(Icons.bolt_rounded, 'Quick\nAccess'),
            AuthFeatureItem(Icons.mark_email_read_rounded, 'OTP on\nEmail'),
            AuthFeatureItem(Icons.emoji_events_rounded, 'For True\nCricket Fans'),
          ]),
        ],
      ),
    );
  }
}
