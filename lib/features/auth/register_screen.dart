import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String _selectedRole = 'user';
  
  // Hover states
  bool _isRegisterHovered = false;
  bool _isGoogleHovered = false;
  bool _isFacebookHovered = false;
  bool _isAppleHovered = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Please agree to terms & conditions'),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      final authProvider = context.read<AuthProvider>();
      
      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        role: _selectedRole,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Registration successful! Please login.'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(authProvider.errorMessage ?? 'Registration failed'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 900;
    
    // Responsive values
    final horizontalPadding = isSmallScreen ? 16.0 : (isTablet ? 32.0 : 48.0);
    final logoSize = isSmallScreen ? 60.0 : (isTablet ? 70.0 : 80.0);
    final formPadding = isSmallScreen ? 16.0 : 24.0;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
              const Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isSmallScreen ? 12 : 20,
                      ),
                      child: Center(
                        child: Container(
                          width: isSmallScreen ? double.infinity : (isTablet ? 500 : 550),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Back Button
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(Icons.arrow_back, color: Colors.white),
                                    splashRadius: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                                  ),
                                ),
                              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                              
                              SizedBox(height: isSmallScreen ? 10 : 16),
                              
                              // Logo
                              Center(
                                child: Container(
                                  width: logoSize,
                                  height: logoSize,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.95),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(logoSize * 0.25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.sports_cricket,
                                    size: logoSize * 0.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ).animate()
                                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                                .scale(delay: 200.ms, duration: 700.ms, curve: Curves.elasticOut),
                              
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              
                              // Title
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.white, Colors.white.withOpacity(0.9)],
                                ).createShader(bounds),
                                child: Text(
                                  'Create Account!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 24 : (isTablet ? 28 : 32),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    height: 1.2,
                                  ),
                                ),
                              ).animate()
                                .fadeIn(delay: 200.ms, duration: 500.ms)
                                .slideY(begin: 0.2, duration: 400.ms),
                              
                              SizedBox(height: 4),
                              
                              Text(
                                'Join Cric11 and start playing cricket',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.3,
                                  height: 1.4,
                                ),
                              ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                              
                              SizedBox(height: isSmallScreen ? 20 : 24),
                              
                              // Form Card
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.98),
                                      Colors.white.withOpacity(0.95),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 25,
                                      offset: const Offset(0, 12),
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      padding: EdgeInsets.all(formPadding),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          children: [
                                            // Name Field
                                            TextFormField(
                                              controller: _nameController,
                                              textCapitalization: TextCapitalization.words,
                                              decoration: InputDecoration(
                                                labelText: 'Full Name',
                                                hintText: 'Enter your full name',
                                                prefixIcon: Icon(Icons.person_outlined, size: 20),
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
                                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              ),
                                              style: const TextStyle(fontSize: 14),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your name';
                                                }
                                                if (value.length < 2) {
                                                  return 'Name must be at least 2 characters';
                                                }
                                                return null;
                                              },
                                            ),
                                            
                                            const SizedBox(height: 14),
                                            
                                            // Email Field
                                            TextFormField(
                                              controller: _emailController,
                                              keyboardType: TextInputType.emailAddress,
                                              decoration: InputDecoration(
                                                labelText: 'Email',
                                                hintText: 'Enter your email',
                                                prefixIcon: Icon(Icons.email_outlined, size: 20),
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
                                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              ),
                                              style: const TextStyle(fontSize: 14),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your email';
                                                }
                                                if (!value.contains('@') || !value.contains('.')) {
                                                  return 'Please enter a valid email';
                                                }
                                                return null;
                                              },
                                            ),
                                            
                                            const SizedBox(height: 14),
                                            
                                            // Phone Field
                                            TextFormField(
                                              controller: _phoneController,
                                              keyboardType: TextInputType.phone,
                                              decoration: InputDecoration(
                                                labelText: 'Phone (Optional)',
                                                hintText: 'Enter your phone number',
                                                prefixIcon: Icon(Icons.phone_outlined, size: 20),
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
                                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              ),
                                              style: const TextStyle(fontSize: 14),
                                              validator: (value) {
                                                if (value != null && value.isNotEmpty) {
                                                  if (value.length < 10) {
                                                    return 'Phone number must be at least 10 digits';
                                                  }
                                                }
                                                return null;
                                              },
                                            ),
                                            
                                            const SizedBox(height: 14),
                                            
                                            // Role Dropdown
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: DropdownButtonFormField<String>(
                                                value: _selectedRole,
                                                decoration: InputDecoration(
                                                  labelText: 'Register As',
                                                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                                  border: InputBorder.none,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                ),
                                                items: const [
                                                  DropdownMenuItem(value: 'user', child: Text('User')),
                                                  DropdownMenuItem(value: 'player', child: Text('Player')),
                                                  DropdownMenuItem(value: 'umpire', child: Text('Umpire')),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedRole = value!;
                                                  });
                                                },
                                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                                dropdownColor: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            
                                            const SizedBox(height: 14),
                                            
                                            // Password Field
                                            TextFormField(
                                              controller: _passwordController,
                                              obscureText: _obscurePassword,
                                              decoration: InputDecoration(
                                                labelText: 'Password',
                                                hintText: 'Create a password',
                                                prefixIcon: Icon(Icons.lock_outlined, size: 20),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscurePassword
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                    size: 18,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscurePassword = !_obscurePassword;
                                                    });
                                                  },
                                                  splashRadius: 18,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
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
                                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              ),
                                              style: const TextStyle(fontSize: 14),
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
                                            
                                            if (_passwordController.text.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4, left: 12),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _passwordController.text.length >= 8
                                                          ? Icons.check_circle
                                                          : Icons.info,
                                                      size: 10,
                                                      color: _passwordController.text.length >= 8
                                                          ? Colors.green.shade600
                                                          : Colors.orange.shade600,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Expanded(
                                                      child: Text(
                                                        _passwordController.text.length >= 8
                                                            ? 'Strong password'
                                                            : 'Use at least 8 characters',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          color: _passwordController.text.length >= 8
                                                              ? Colors.green.shade700
                                                              : Colors.orange.shade700,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            
                                            const SizedBox(height: 14),
                                            
                                            // Confirm Password Field
                                            TextFormField(
                                              controller: _confirmPasswordController,
                                              obscureText: _obscureConfirmPassword,
                                              decoration: InputDecoration(
                                                labelText: 'Confirm Password',
                                                hintText: 'Confirm your password',
                                                prefixIcon: Icon(Icons.lock_outlined, size: 20),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscureConfirmPassword
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                    size: 18,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                                    });
                                                  },
                                                  splashRadius: 18,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
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
                                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              ),
                                              style: const TextStyle(fontSize: 14),
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
                                            
                                            const SizedBox(height: 16),
                                            
                                            // Terms & Conditions
                                            Row(
                                              children: [
                                                Transform.scale(
                                                  scale: 0.7,
                                                  child: Checkbox(
                                                    value: _agreeToTerms,
                                                    onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                                                    activeColor: AppColors.primary,
                                                    checkColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Wrap(
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                      Text(
                                                        'I agree to the ',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () {
                                                          // TODO: Show terms & conditions
                                                        },
                                                        child: Text(
                                                          'Terms & Conditions',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.primary,
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 20),
                                            
                                            // Register Button
                                            Consumer<AuthProvider>(
                                              builder: (context, auth, child) {
                                                return MouseRegion(
                                                  onEnter: (_) => setState(() => _isRegisterHovered = true),
                                                  onExit: (_) => setState(() => _isRegisterHovered = false),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    width: double.infinity,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          AppColors.primary,
                                                          AppColors.primaryLight,
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(14),
                                                      boxShadow: _isRegisterHovered && auth.status != AuthStatus.loading
                                                          ? [
                                                              BoxShadow(
                                                                color: AppColors.primary.withOpacity(0.3),
                                                                blurRadius: 10,
                                                                spreadRadius: 1,
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: auth.status == AuthStatus.loading ? null : _register,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.transparent,
                                                        foregroundColor: Colors.white,
                                                        elevation: 0,
                                                        shadowColor: Colors.transparent,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(14),
                                                        ),
                                                        padding: EdgeInsets.zero,
                                                      ),
                                                      child: auth.status == AuthStatus.loading
                                                          ? const SizedBox(
                                                              height: 22,
                                                              width: 22,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor: AlwaysStoppedAnimation(Colors.white),
                                                              ),
                                                            )
                                                          : Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(Icons.person_add, size: 16),
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                  'Create Account',
                                                                  style: TextStyle(
                                                                    fontSize: isSmallScreen ? 14 : 15,
                                                                    fontWeight: FontWeight.bold,
                                                                    letterSpacing: 0.5,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            
                                            const SizedBox(height: 16),
                                            
                                            // Social Registration
                                            Row(
                                              children: [
                                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  child: Text(
                                                    'Or sign up with',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 16),
                                            
                                            // Social buttons
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              alignment: WrapAlignment.center,
                                              children: [
                                                _buildSocialButton(
                                                  icon: Icons.g_mobiledata,
                                                  label: 'Google',
                                                  color: Colors.red,
                                                  onTap: () {},
                                                  isHovered: _isGoogleHovered,
                                                  onHover: (value) => setState(() => _isGoogleHovered = value),
                                                ),
                                                _buildSocialButton(
                                                  icon: Icons.facebook,
                                                  label: 'Facebook',
                                                  color: Colors.blue.shade800,
                                                  onTap: () {},
                                                  isHovered: _isFacebookHovered,
                                                  onHover: (value) => setState(() => _isFacebookHovered = value),
                                                ),
                                                _buildSocialButton(
                                                  icon: Icons.apple,
                                                  label: 'Apple',
                                                  color: Colors.black,
                                                  onTap: () {},
                                                  isHovered: _isAppleHovered,
                                                  onHover: (value) => setState(() => _isAppleHovered = value),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate()
                                .fadeIn(delay: 400.ms, duration: 600.ms)
                                .slideY(begin: 0.1, duration: 500.ms),
                              
                              const SizedBox(height: 16),
                              
                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account?",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
                              
                              SizedBox(height: isSmallScreen ? 8 : 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isHovered,
    required ValueChanged<bool> onHover,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              isHovered ? Colors.grey.shade100 : Colors.grey.shade50,
            ],
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


