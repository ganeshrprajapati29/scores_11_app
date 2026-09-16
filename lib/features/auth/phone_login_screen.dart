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

  Future<void> _continueAsGuest() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();
    await authProvider.continueAsGuest();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  String get _stepTitle => _needsProfile
      ? 'Create account'
      : _codeSent
          ? 'Verify mobile'
          : 'Welcome back';

  String get _stepSubtitle => _needsProfile
      ? 'Your mobile number is verified. Add your name to finish your Scores11 account.'
      : _codeSent
          ? 'Enter the OTP sent to your mobile.\nNo password needed.'
          : 'Login with your mobile using a one-time code.\nNo password needed.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthDesign.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const Positioned.fill(child: _StadiumNightBackdrop()),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _DarkRoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.maybePop(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.45),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.phone_iphone_rounded,
                                color: AppColors.primary,
                                size: 44),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.80),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.34),
                            blurRadius: 28,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _stepTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AuthDesign.ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _stepSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.97),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.72), width: 1.2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x24101828), blurRadius: 36, offset: Offset(0, 18)),
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
                            if (_codeSent && !_needsProfile) ...[
                              AuthSuccessBanner(
                                title: 'Code sent successfully',
                                description:
                                    "We've sent a 6-digit OTP to +91 ${_phoneController.text.trim()}",
                              ),
                              const SizedBox(height: 18),
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
                              const Center(
                                child: Text(
                                  'Enter 6-digit code',
                                  style: TextStyle(
                                      color: AuthDesign.ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 8,
                                    color: AuthDesign.ink),
                                decoration: AuthDesign.input(
                                  label: 'OTP code',
                                  hint: 'Enter 6-digit code',
                                  icon: Icons.pin_outlined,
                                ).copyWith(counterText: ''),
                              ),
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
                                      ? 'Verify and sign in'
                                      : 'Send OTP',
                              loading: _isLoading,
                              icon: _needsProfile
                                  ? Icons.person_add_alt_1_rounded
                                  : _codeSent
                                      ? Icons.shield_rounded
                                      : Icons.send_rounded,
                              trailingArrow: true,
                            ),
                            if (!_codeSent) ...[
                              const SizedBox(height: 24),
                              const AuthDivider(),
                              const SizedBox(height: 18),
                              AuthOutlineButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.pushReplacementNamed(
                                          context,
                                          '/email-login',
                                        ),
                                label: 'Login with email OTP',
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 12),
                              AuthOutlineButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.pushNamed(
                                          context,
                                          '/register',
                                        ),
                                label: 'Create account',
                                icon: Icons.person_add_alt_1_rounded,
                              ),
                              const SizedBox(height: 12),
                              AuthOutlineButton(
                                onPressed:
                                    _isLoading ? null : _continueAsGuest,
                                label: 'Continue as guest',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 18),
                              const Center(
                                child: AuthSecurityNote(
                                  text: 'Secure, fast and password-free',
                                ),
                              ),
                            ],
                            if (_codeSent && !_needsProfile) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: _isLoading ? null : _requestOTP,
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text(
                                      'Resend OTP',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  Container(width: 1, height: 16, color: AuthDesign.line),
                                  TextButton.icon(
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
                                    icon: const Icon(Icons.edit_rounded, size: 16),
                                    label: const Text('Change mobile'),
                                  ),
                                ],
                              ),
                            ],
                            if (_needsProfile) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
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
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stadium backdrop aligned with the shared auth shell.
class _StadiumNightBackdrop extends StatelessWidget {
  const _StadiumNightBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AuthDesign.stadiumImage,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => CustomPaint(
            painter: _StadiumGlowPainter(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF1F6FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.02),
                Colors.white.withOpacity(0.28),
                AuthDesign.bg.withOpacity(0.98),
              ],
              stops: const [0.0, 0.56, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

class _StadiumGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow1 = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    final glow2 = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.06), 70, glow1);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.10), 90, glow2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular back button styled for the auth backdrop.
class _DarkRoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DarkRoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, color: AuthDesign.ink, size: 20),
        ),
      ),
    );
  }
}
