import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'auth_design.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _agreeToTerms = false;
  bool _otpSent = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Seconds until "Resend OTP" is allowed again (server enforces the same).
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _phoneDigits {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) return digits.substring(2);
    return digits;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return isValid ? null : 'Enter a valid email address';
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendIn = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      if (_resendIn == 0) timer.cancel();
    });
  }

  /// Ask the backend to send an OTP to the number (delivered by APITxT).
  Future<void> _sendOtp() async {
    if (_isSubmitting || _resendIn > 0) return;
    if (_formKey.currentState?.validate() != true) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms & conditions'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final sent = await auth.sendPhoneOtp(_phoneDigits);
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (sent) {
        _otpSent = true;
        _otpController.clear();
        _errorMessage = null;
      } else {
        _errorMessage = auth.errorMessage ?? 'Could not send the OTP. Please try again.';
      }
    });
    if (sent || auth.authActionCode == 'OTP_RESEND_WAIT') {
      _startResendCountdown(auth.otpResendSeconds);
    }
  }

  /// Verify the OTP; the account is created in the same step.
  Future<void> _verifyOtp() async {
    if (_isSubmitting) return;
    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Enter the complete 6-digit OTP.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final success = await auth.loginWithPhoneOtp(
      phone: _phoneDigits,
      otp: otp,
      name: _nameController.text.trim(),
      email: email.isEmpty ? null : email,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Scores11!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (route) => false,
      );
      return;
    }
    final expired = auth.authActionCode == 'OTP_EXPIRED' ||
        auth.authActionCode == 'OTP_ATTEMPTS';
    setState(() {
      _errorMessage = auth.errorMessage ?? 'Account creation failed.';
      if (expired) {
        _otpController.clear();
        _resendIn = 0;
      }
    });
  }

  void _editDetails() {
    _resendTimer?.cancel();
    setState(() {
      _otpSent = false;
      _resendIn = 0;
      _otpController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phoneText = _phoneController.text.trim();
    return AuthShell(
      showBack: true,
      title: 'Create account',
      subtitle: _otpSent
          ? 'Enter the OTP sent to +91 $phoneText.\nEmail is optional.'
          : 'Create your Scores11 account with mobile OTP.\nEmail is optional.',
      heroIcon: Icons.person_add_alt_1_rounded,
      heroImage: 'score 11/Login, Register, OTP 1080 x 720 PNG.png',
      belowCard: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already registered? ',
                style: TextStyle(
                  color: AuthDesign.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/phone-login'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sign in',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AuthFeatureStrip(),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.18),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (!_otpSent) ...[
              const Text(
                'Create Your Account',
                style: TextStyle(
                  color: AuthDesign.ink,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Full name and mobile number are required. Email is optional.',
                style: TextStyle(
                  color: AuthDesign.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: AuthDesign.input(
                  label: 'Full name',
                  hint: 'Enter your name',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: AuthDesign.input(
                  label: 'Mobile number',
                  hint: 'Enter 10-digit mobile number',
                  icon: Icons.phone_android_rounded,
                ).copyWith(prefixText: '+91 '),
                validator: (value) {
                  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                  if (digits.length != 10 || !RegExp(r'^[6-9]').hasMatch(digits)) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: AuthDesign.input(
                  label: 'Email address (optional)',
                  hint: 'Optional email',
                  icon: Icons.email_outlined,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _agreeToTerms,
                onChanged: (value) =>
                    setState(() => _agreeToTerms = value ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text(
                  'I agree to Scores11 terms and fair-play policy',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else ...[
              AuthSuccessBanner(
                title: 'OTP sent successfully',
                description: 'We sent a 6-digit OTP to +91 $phoneText',
              ),
              const SizedBox(height: 18),
              const Text(
                'Verify Mobile Number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuthDesign.ink,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AuthDesign.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
                decoration: AuthDesign.input(
                  label: 'OTP code',
                  hint: 'Enter 6-digit code',
                  icon: Icons.pin_outlined,
                ).copyWith(counterText: ''),
                onFieldSubmitted: (_) => _verifyOtp(),
              ),
            ],
            const SizedBox(height: 18),
            AuthPrimaryButton(
              onPressed: _otpSent ? _verifyOtp : _sendOtp,
              label: _otpSent ? 'Verify and create account' : 'Send mobile OTP',
              loading: _isSubmitting ||
                  context.watch<AuthProvider>().status == AuthStatus.loading,
              icon: _otpSent ? Icons.shield_rounded : Icons.send_rounded,
              trailingArrow: true,
            ),
            if (_otpSent) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _isSubmitting || _resendIn > 0 ? null : _sendOtp,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      _resendIn > 0 ? 'Resend in ${_resendIn}s' : 'Resend OTP',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(width: 1, height: 16, color: AuthDesign.line),
                  TextButton.icon(
                    onPressed: _isSubmitting ? null : _editDetails,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit details'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
