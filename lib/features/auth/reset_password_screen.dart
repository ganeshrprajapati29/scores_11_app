import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // Get email from route arguments
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
    super.dispose();
  }

  Future<void> _verifyOTP() async {
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
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to reset password'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 60,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 24),
                  Text(
                    'Reset Your Password',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the OTP sent to your email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 40),
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // Email Field
                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          enabled: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // OTP Field
                        CustomTextField(
                          controller: _otpController,
                          labelText: 'OTP Code',
                          hintText: 'Enter the OTP from your email',
                          prefixIcon: Icons.pin,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the OTP';
                            }
                            if (value.length != 6) {
                              return 'OTP must be 6 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // New Password Field
                        CustomTextField(
                          controller: _passwordController,
                          labelText: 'New Password',
                          hintText: 'Enter new password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password Field
                        CustomTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Reset Password',
                          onPressed: _verifyOTP,
                          isLoading: _isLoading,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

