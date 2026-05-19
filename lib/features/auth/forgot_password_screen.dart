import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';

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
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF1565C0),
                Color(0xFF0D47A1),
              ],
            ),
          ),
child: SafeArea(
            child: SingleChildScrollView(
              // FIXED: Removed onDrag to prevent back navigation in Release APK
              // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Logo and Title
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.lock_reset,
                          size: 45,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withOpacity(0.22)),
                      ),
                      child: const Text(
                        'SCORES11 ACCOUNT SECURITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 120.ms, duration: 500.ms),
                  const SizedBox(height: 20),
                  Text(
                    'Recover Password',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                  const SizedBox(height: 12),
                  if (!_emailSent) ...[
                    Text(
                      'Enter your email address and we\'ll send you an OTP to reset your password.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  ],
                  const SizedBox(height: 40),
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _emailSent ? _buildSuccessView() : _buildEmailForm(),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 24),
                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Remember your password?",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OTP Verification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    SizedBox(height: 2),
                    Text('We will send reset code securely', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your registered email',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
            // FIX: Prevent unexpected navigation in release builds
            onFieldSubmitted: (value) {
              FocusScope.of(context).unfocus();
              if (!mounted) return;
              _sendResetLink();
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 50,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'OTP Sent!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent an OTP to $_sentEmail',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your email and enter the OTP to reset your password.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/reset-password',
                arguments: {'email': _sentEmail},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Proceed to Reset Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _emailSent = false;
                _emailController.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Send Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
