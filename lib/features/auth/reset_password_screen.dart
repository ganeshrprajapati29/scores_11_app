import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'auth_design.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _otpVerified = false;
  String? _passedEmail;

  // Focus nodes for keyboard management
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['email'] != null) {
        setState(() {
          _passedEmail = args['email'];
          _emailController.text = _passedEmail!;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _otpFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.resetPassword(
        _emailController.text.trim(),
        _otpController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to reset password'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      title: 'Reset password',
      subtitle: 'Enter the OTP sent to your email and create a new secure password.',
      heroImage: 'score 11/Login, Register, OTP 1080 x 720 PNG.png',
      heroIcon: Icons.password_rounded,
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthStepProgress(currentStep: 1, labels: ['Verify OTP', 'Create Password', 'Complete']),
            const SizedBox(height: 24),
            _fieldSection(
              label: 'Email Address',
              icon: Icons.email_outlined,
              trailing: _passedEmail != null
                  ? const Icon(Icons.check_circle_rounded, color: AuthDesign.cricketGreen, size: 18)
                  : null,
              field: TextFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _plainFieldDecoration('Registered email'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter email';
                  if (!value.contains('@') || !value.contains('.')) return 'Enter valid email';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            _fieldSection(
              label: 'OTP Code',
              icon: Icons.pin_rounded,
              field: TextFormField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                maxLength: 6,
                decoration: _plainFieldDecoration('6-digit code').copyWith(counterText: ''),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter OTP';
                  if (value.trim().length != 6) return 'OTP must be 6 digits';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            _fieldSection(
              label: 'New Password',
              icon: Icons.lock_outline_rounded,
              field: TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: _plainFieldDecoration('Create new password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter password';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            _fieldSection(
              label: 'Confirm Password',
              icon: Icons.verified_user_outlined,
              field: TextFormField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                decoration: _plainFieldDecoration('Re-enter password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildRequirementsCard(),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              onPressed: _verifyOTP,
              label: 'Reset Password',
              loading: _isLoading,
              icon: Icons.lock_reset_rounded,
              trailingArrow: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Pure presentation helper: a light bordered "step card" row made of an
  /// icon chip + label header with the actual field underneath.
  Widget _fieldSection({
    required String label,
    required IconData icon,
    required Widget field,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthDesign.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: AuthDesign.chipBg, borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: Icon(icon, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AuthDesign.ink)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          field,
        ],
      ),
    );
  }

  InputDecoration _plainFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AuthDesign.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AuthDesign.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.7)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.7)),
    );
  }

  Widget _buildRequirementsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuthDesign.chipBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Password must contain:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AuthDesign.ink)),
          SizedBox(height: 6),
          _RequirementRow('At least 6 characters'),
          SizedBox(height: 4),
          _RequirementRow('Mix of letters and numbers'),
          SizedBox(height: 4),
          _RequirementRow('Strong & unique password'),
        ],
      ),
    );
  }
}

/// Small "✓ requirement" row used inside the password requirements card.
/// Purely presentational.
class _RequirementRow extends StatelessWidget {
  final String text;

  const _RequirementRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 14, color: AuthDesign.cricketGreen),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AuthDesign.muted)),
      ],
    );
  }
}
