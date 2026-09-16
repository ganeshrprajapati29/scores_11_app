import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
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

  String? _verificationId;
  int? _resendToken;
  bool _agreeToTerms = false;
  bool _otpSent = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _firebasePhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    return '+91$digits';
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return isValid ? null : 'Enter a valid email address';
  }

  String _mobileAuthMessage(firebase_auth.FirebaseAuthException error) {
    final rawMessage = '${error.code} ${error.message ?? ''}'.toLowerCase();
    switch (error.code) {
      case 'invalid-verification-code':
      case 'session-expired':
        return 'Invalid or expired OTP. Please request a new code.';
      case 'too-many-requests':
        return 'OTP sending is temporarily blocked for this mobile number. Try again later.';
      case 'network-request-failed':
        return 'Network issue. Please check your connection.';
      default:
        if (rawMessage.contains('17093') ||
            rawMessage.contains('app-not-authorized') ||
            rawMessage.contains('app not authorized') ||
            rawMessage.contains('not authorized')) {
          return 'This app build is not authorized for mobile OTP. Please install the latest build and try again.';
        }
        return 'Unable to send OTP right now. Please try again.';
    }
  }

  Future<void> _sendOtp() async {
    if (_isSubmitting) return;
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

    if (Firebase.apps.isEmpty) {
      setState(() {
        _errorMessage =
            'Mobile sign-up is not ready. Please update the app and try again.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = firebase_auth.FirebaseAuth.instance;
      await auth.setLanguageCode('en');
      await auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: false,
      );
      await auth.verifyPhoneNumber(
        phoneNumber: _firebasePhone,
        forceResendingToken: _otpSent ? _resendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: _completeFirebaseRegistration,
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() {
            _isSubmitting = false;
            _errorMessage = _mobileAuthMessage(error);
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken ?? _resendToken;
            _otpSent = true;
            _otpController.clear();
            _isSubmitting = false;
            _errorMessage = null;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = _mobileAuthMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Unable to send OTP right now. Please try again.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_isSubmitting) return;
    final verificationId = _verificationId;
    final otp = _otpController.text.trim();
    if (verificationId == null) {
      setState(() => _errorMessage = 'Please request a new OTP and try again.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Enter the complete 6-digit OTP.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final credential = firebase_auth.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    await _completeFirebaseRegistration(credential);
  }

  Future<void> _completeFirebaseRegistration(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    try {
      final result = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      final idToken = await result.user?.getIdToken(true);
      if (idToken == null) {
        throw firebase_auth.FirebaseAuthException(code: 'missing-token');
      }

      final email = _emailController.text.trim();
      final success = await context.read<AuthProvider>().loginWithFirebasePhone(
            idToken: idToken,
            name: _nameController.text.trim(),
            email: email.isEmpty ? null : email,
            role: 'user',
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
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

      final auth = context.read<AuthProvider>();
      setState(() {
        _errorMessage = auth.errorMessage ?? 'Account creation failed.';
      });
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = _mobileAuthMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Unable to create account. Please try again.';
      });
    }
  }

  void _editDetails() {
    setState(() {
      _otpSent = false;
      _verificationId = null;
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
                  if (digits.length != 10) {
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
                    onPressed: _isSubmitting ? null : _sendOtp,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Resend OTP',
                      style: TextStyle(fontWeight: FontWeight.w800),
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
