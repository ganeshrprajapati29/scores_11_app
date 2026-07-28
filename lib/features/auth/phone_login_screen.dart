import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'auth_design.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  String? _verificationId;
  String? _verifiedIdToken;
  int? _resendToken;
  bool _codeSent = false;
  bool _needsProfile = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _firebasePhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    return '+91$digits';
  }

  Future<void> _requestOTP() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (Firebase.apps.isEmpty) {
      setState(() {
        _errorMessage =
            'Mobile sign-in is not ready. Please update the app and try again.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _needsProfile = false;
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
        forceResendingToken: _codeSent ? _resendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: _completeFirebaseLogin,
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = _mobileAuthMessage(error);
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken ?? _resendToken;
            _codeSent = true;
            _needsProfile = false;
            _verifiedIdToken = null;
            _otpController.clear();
            _isLoading = false;
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
        _isLoading = false;
        _errorMessage = _mobileAuthMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to send OTP right now. Please try again.';
      });
    }
  }

  Future<void> _verifyOTP() async {
    final verificationId = _verificationId;
    final otp = _otpController.text.trim();
    if (verificationId == null) {
      setState(() => _errorMessage = 'Request a new OTP and try again');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final credential = firebase_auth.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    await _completeFirebaseLogin(credential);
  }

  Future<void> _completeFirebaseLogin(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    try {
      final result = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      final idToken = await result.user?.getIdToken(true);
      if (idToken == null) {
        throw firebase_auth.FirebaseAuthException(code: 'missing-token');
      }
      if (!mounted) return;

      await _finishMobileLogin(idToken: idToken);
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _mobileAuthMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to complete mobile sign-in. Please try again.';
      });
    }
  }

  Future<void> _finishMobileLogin({
    required String idToken,
    String? name,
    String? email,
    String? role,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  }) async {
    try {
      final success = await context.read<AuthProvider>().loginWithFirebasePhone(
            idToken: idToken,
            name: name,
            email: email,
            role: role,
            playerRole: playerRole,
            battingStyle: battingStyle,
            bowlingStyle: bowlingStyle,
          );
      if (!mounted) return;
      if (!success) {
        final auth = context.read<AuthProvider>();
        if (auth.authActionCode == 'PROFILE_REQUIRED') {
          setState(() {
            _isLoading = false;
            _needsProfile = true;
            _verifiedIdToken = idToken;
            _errorMessage =
                'This mobile number is verified. Add your name to create your Scores11 account.';
          });
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = auth.errorMessage ?? 'Mobile sign-in failed';
        });
        return;
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Mobile login failed. Please try again.';
      });
    }
  }

  Future<void> _createMobileAccount() async {
    final idToken = _verifiedIdToken;
    final name = _nameController.text.trim();
    if (idToken == null) {
      setState(() => _errorMessage = 'Please verify your OTP again.');
      return;
    }
    if (name.length < 2) {
      setState(() => _errorMessage = 'Enter your full name to continue.');
      return;
    }
    final email = _emailController.text.trim();
    if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
      setState(() => _errorMessage = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _finishMobileLogin(
      idToken: idToken,
      name: name,
      email: email,
      role: 'user',
    );
  }

  String _mobileAuthMessage(firebase_auth.FirebaseAuthException error) {
    final rawMessage = '${error.code} ${error.message ?? ''}'.toLowerCase();
    switch (error.code) {
      case 'invalid-verification-code':
      case 'session-expired':
        return 'Invalid or expired OTP. Please request a new code.';
      case 'too-many-requests':
        return 'OTP sending is temporarily blocked by Firebase for this mobile/device. '
            'Try again after some time or use another number.';
      case 'network-request-failed':
        return 'Network issue. Please check your connection.';
      default:
        if (rawMessage.contains('17093') ||
            rawMessage.contains('app-not-authorized') ||
            rawMessage.contains('app not authorized') ||
            rawMessage.contains('not authorized')) {
          return 'This app build is not authorized for mobile OTP. Please uninstall the old app, install the latest build, and try again.';
        }
        return 'Unable to send OTP right now. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      title: _needsProfile
          ? 'Create account'
          : _codeSent
              ? 'Verify mobile'
              : 'Mobile OTP',
      subtitle: _needsProfile
          ? 'Your mobile number is verified. Add your name to finish your Scores11 account.'
          : _codeSent
              ? 'Enter the OTP sent to ${_phoneController.text.trim()}.'
              : 'Login or create your Scores11 account using your mobile number.',
      heroIcon: Icons.phone_iphone_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.18),
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
            if (!_codeSent)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
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
              )
            else if (_needsProfile) ...[
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: AuthDesign.input(
                  label: 'Full name',
                  hint: 'Enter your name',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: AuthDesign.input(
                  label: 'Email address',
                  hint: 'Optional email',
                  icon: Icons.email_outlined,
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: AuthDesign.input(
                  label: 'OTP code',
                  hint: 'Enter 6-digit code',
                  icon: Icons.pin_outlined,
                ).copyWith(counterText: ''),
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 18),
            AuthPrimaryButton(
              onPressed: _needsProfile
                  ? _createMobileAccount
                  : _codeSent
                      ? _verifyOTP
                      : _requestOTP,
              label: _needsProfile
                  ? 'Create account'
                  : _codeSent
                      ? 'Verify and continue'
                      : 'Send OTP',
              loading: _isLoading,
              icon: _needsProfile
                  ? Icons.person_add_alt_1_rounded
                  : _codeSent
                      ? Icons.verified_rounded
                      : Icons.send_rounded,
            ),
            if (_codeSent && !_needsProfile) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading ? null : _requestOTP,
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() {
                          _codeSent = false;
                          _needsProfile = false;
                          _otpController.clear();
                          _nameController.clear();
                          _emailController.clear();
                          _verificationId = null;
                          _verifiedIdToken = null;
                          _errorMessage = null;
                        }),
                child: const Text('Change mobile number'),
              ),
            ],
            if (_needsProfile) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() {
                          _codeSent = false;
                          _needsProfile = false;
                          _otpController.clear();
                          _nameController.clear();
                          _emailController.clear();
                          _verificationId = null;
                          _verifiedIdToken = null;
                          _errorMessage = null;
                        }),
                child: const Text('Use a different mobile number'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
