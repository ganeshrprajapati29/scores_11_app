import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/connectivity_service.dart';
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
    final success = await authProvider.verifyEmailOtp(
        _emailController.text.trim(), otp);

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
          ? 'Enter the OTP sent to ${_emailController.text.trim()}.'
          : 'Login with your email using a one-time code. No password needed.',
      heroIcon: Icons.sports_cricket_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_otpSent)
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Enter valid email';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _sendOtp(),
              )
            else
              TextFormField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: AuthDesign.input(
                  label: 'OTP code',
                  hint: 'Enter 6-digit code',
                  icon: Icons.pin_outlined,
                ).copyWith(counterText: ''),
                onFieldSubmitted: (_) => _verifyOtp(),
              ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              onPressed: _otpSent ? _verifyOtp : _sendOtp,
              label: _otpSent ? 'Verify and sign in' : 'Send OTP',
              loading: _isSubmitting || auth.status == AuthStatus.loading,
              icon: _otpSent ? Icons.verified_rounded : Icons.send_rounded,
            ),
            if (_otpSent) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : _sendOtp,
                    child: const Text('Resend OTP',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                              _otpSent = false;
                              _otpController.clear();
                            }),
                    child: const Text('Change email'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/phone-login'),
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Login or register with mobile OTP'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: (auth.status == AuthStatus.loading || _isSubmitting)
                  ? null
                  : _continueAsGuest,
              icon: const Icon(Icons.person_outline_rounded, size: 19),
              label: const Text('Continue as guest'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.28)),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('New to Scores11?',
                    style: TextStyle(
                        color: AuthDesign.muted, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Create account',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
