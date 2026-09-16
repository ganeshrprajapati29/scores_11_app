import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'auth_design.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _sentEmail;

  final FocusNode _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

Future<void> _sendResetLink() async {
    // FIX: Only unfocus keyboard when submit button is pressed
    FocusScope.of(context).unfocus();
    // Small delay to allow keyboard to dismiss before validation
    await Future.delayed(const Duration(milliseconds: 200));

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _sentEmail = _emailController.text.trim();
      });

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.forgotPassword(_emailController.text.trim());

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        setState(() {
          _emailSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent! Check your email.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      } else if (mounted) {
        setState(() {
          _emailSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('If account exists, OTP has been sent.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      title: 'Forgot password?',
      subtitle: "Enter your registered email and we'll send an OTP.\nNo password needed.",
      heroImage: 'score 11/Login, Register, OTP 1080 x 720 PNG.png',
      heroIcon: Icons.lock_reset_rounded,
      belowCard: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Remember your password? ',
                  style: TextStyle(color: AuthDesign.muted, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sign in', style: TextStyle(fontWeight: FontWeight.w900)),
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
      child: _emailSent ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AuthDesign.chipBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure & Easy Recovery',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AuthDesign.ink),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'We will send a 6-digit OTP to your registered email address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AuthDesign.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: AuthDesign.input(label: 'Email Address', hint: 'Enter your registered email', icon: Icons.email_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter email';
              if (!value.contains('@') || !value.contains('.')) return 'Enter valid email';
              return null;
            },
            onFieldSubmitted: (_) => _sendResetLink(),
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            onPressed: _sendResetLink,
            label: 'Send OTP',
            loading: _isLoading,
            icon: Icons.send_rounded,
            trailingArrow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthSuccessBanner(
          title: 'OTP Sent Successfully!',
          description:
              'We have sent a 6-digit OTP to ${_sentEmail ?? 'your email'}. Please check your email and enter the OTP to reset your password.',
        ),
        const SizedBox(height: 16),
        AuthPrimaryButton(
          onPressed: () => Navigator.pushNamed(context, '/reset-password', arguments: {'email': _sentEmail}),
          label: 'Proceed to Reset Password',
          icon: Icons.arrow_forward_rounded,
          trailingArrow: true,
        ),
        const SizedBox(height: 10),
        AuthOutlineButton(
          onPressed: () => setState(() => _emailSent = false),
          label: 'Use a Different Email',
          icon: Icons.edit_rounded,
        ),
      ],
    );
  }
}
