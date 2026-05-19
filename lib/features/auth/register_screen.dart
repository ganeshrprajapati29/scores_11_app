import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
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
  
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

// Player-specific fields (shown when role is 'player')
  String _selectedPlayerRole = 'batsman';
  String _selectedBattingStyle = 'right-hand bat';
  String _selectedBowlingStyle = 'none';

  Future<void> _register() async {
    // FIX: Validate form first - no delayed Future.delayed
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Only unfocus AFTER validation passes
    FocusScope.of(context).unfocus();
    
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

    final authProvider = context.read<AuthProvider>();
    
    // Pass additional player-specific fields when registering as player
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      role: _selectedRole,
      playerRole: _selectedRole == 'player' ? _selectedPlayerRole : null,
      battingStyle: _selectedRole == 'player' ? _selectedBattingStyle : null,
      bowlingStyle: _selectedRole == 'player' ? _selectedBowlingStyle : null,
    );

    // FIX: Check mounted BEFORE navigation
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              // FIXED: Removed onDrag to prevent back navigation in Release APK
              // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Logo
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
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
                        Icons.sports_cricket,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms).scale(),
                  
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: const Text(
                      'SCORES11 PROFESSIONAL CRICKET',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ).animate().fadeIn(delay: 120.ms),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Create Your Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Build teams, score matches and track player performance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 30),
                  
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
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
                                child: const Icon(Icons.badge_outlined, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Account Setup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                    SizedBox(height: 2),
                                    Text('Enter verified profile details', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              prefixIcon: const Icon(Icons.person_outline, size: 22),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your name';
                              if (value.length < 2) return 'Name must be at least 2 characters';
                              return null;
                            },
                            onEditingComplete: () {
                              FocusScope.of(context).requestFocus(_emailFocusNode);
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: const Icon(Icons.email_outlined, size: 22),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter email';
                              if (!value.contains('@') || !value.contains('.')) return 'Enter valid email';
                              return null;
                            },
                            onEditingComplete: () {
                              FocusScope.of(context).requestFocus(_phoneFocusNode);
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Phone (Optional)',
                              hintText: 'Enter 10-digit number',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 22),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length < 10) {
                                return 'Enter valid 10-digit number';
                              }
                              return null;
                            },
                            onEditingComplete: () {
                              FocusScope.of(context).requestFocus(_passwordFocusNode);
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
// Role Dropdown
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Register As',
                                prefixIcon: Icon(Icons.person_outline, size: 22),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'user', child: Text('User')),
                                DropdownMenuItem(value: 'player', child: Text('Player')),
                                DropdownMenuItem(value: 'umpire', child: Text('Umpire')),
                                DropdownMenuItem(value: 'scorer', child: Text('Scorer')),
                              ],
                              onChanged: (value) => setState(() => _selectedRole = value!),
                              icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                            ),
                          ),
                          
                          // Player-specific fields (only shown when role is 'player')
                          if (_selectedRole == 'player') ...[
                            const SizedBox(height: 16),
                            // Player Role Dropdown
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedPlayerRole,
                                decoration: const InputDecoration(
                                  labelText: 'Player Role',
                                  prefixIcon: Icon(Icons.sports_cricket, size: 22),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'batsman', child: Text('Batsman')),
                                  DropdownMenuItem(value: 'bowler', child: Text('Bowler')),
                                  DropdownMenuItem(value: 'all-rounder', child: Text('All Rounder')),
                                  DropdownMenuItem(value: 'wicket-keeper', child: Text('Wicket Keeper')),
                                ],
                                onChanged: (value) => setState(() => _selectedPlayerRole = value!),
                                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Batting Style Dropdown
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedBattingStyle,
                                decoration: const InputDecoration(
                                  labelText: 'Batting Style',
                                  prefixIcon: Icon(Icons.sports_baseball, size: 22),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'right-hand bat', child: Text('Right Hand Bat')),
                                  DropdownMenuItem(value: 'left-hand bat', child: Text('Left Hand Bat')),
                                ],
                                onChanged: (value) => setState(() => _selectedBattingStyle = value!),
                                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Bowling Style Dropdown
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedBowlingStyle,
                                decoration: const InputDecoration(
                                  labelText: 'Bowling Style',
                                  prefixIcon: Icon(Icons.sports_baseball, size: 22),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'none', child: Text('None')),
                                  DropdownMenuItem(value: 'right-arm fast', child: Text('Right Arm Fast')),
                                  DropdownMenuItem(value: 'right-arm medium', child: Text('Right Arm Medium')),
                                  DropdownMenuItem(value: 'left-arm fast', child: Text('Left Arm Fast')),
                                  DropdownMenuItem(value: 'left-arm medium', child: Text('Left Arm Medium')),
                                  DropdownMenuItem(value: 'off-spin', child: Text('Off Spin')),
                                  DropdownMenuItem(value: 'leg-spin', child: Text('Leg Spin')),
                                ],
                                onChanged: (value) => setState(() => _selectedBowlingStyle = value!),
                                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Create a password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 22),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                            onEditingComplete: () {
                              FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
// Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocusNode,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Confirm your password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 22),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please confirm password';
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                            // FIX: Prevent unexpected navigation in release builds
                            onFieldSubmitted: (value) {
                              FocusScope.of(context).unfocus();
                              if (!mounted) return;
                              _register();
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Terms & Conditions
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                                  activeColor: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'I agree to the Terms & Conditions',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Register Button
                          Consumer<AuthProvider>(
                            builder: (context, auth, child) => SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: auth.status == AuthStatus.loading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: auth.status == AuthStatus.loading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Already have an account? ", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: Text('Sign In', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
