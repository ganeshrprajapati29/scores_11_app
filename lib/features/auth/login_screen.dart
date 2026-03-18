import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController(text: 'user@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isPhoneLogin = false;
  
  // Separate hover states for different elements
  bool _isLoginHovered = false;
  bool _isToggleHovered = false;
  bool _isGoogleHovered = false;
  bool _isFacebookHovered = false;
  bool _isAppleHovered = false;

  @override
  void initState() {
    super.initState();
    // Removed animation controller to avoid lateinit error
    // Using Flutter Animate package animations instead
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        _isPhoneLogin ? _phoneController.text.trim() : _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        if (_rememberMe) {
          // TODO: Implement secure storage for remember me
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.errorMessage ?? 'Login failed',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _toggleLoginType() {
    setState(() {
      _isPhoneLogin = !_isPhoneLogin;
      // Clear controllers when switching
      if (_isPhoneLogin) {
        _phoneController.clear();
      } else {
        _emailController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 900;
    final isDesktop = size.width >= 900;
    
    // Responsive padding and sizing
    final horizontalPadding = isSmallScreen ? 16.0 : (isTablet ? 32.0 : 48.0);
    final logoSize = isSmallScreen ? 70.0 : (isTablet ? 90.0 : 110.0);
    final formWidth = isDesktop ? 420.0 : (isTablet ? 380.0 : double.infinity);
    final formMaxWidth = isDesktop ? 450.0 : double.infinity;
    
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
              const Color(0xFF1a237e),
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
                          width: formWidth,
                          constraints: BoxConstraints(
                            maxWidth: formMaxWidth,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo with premium animation
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
                                    shape: BoxShape.circle,
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
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: 'https://your-logo-url.com/logo.png',
                                      placeholder: (context, url) => Container(
                                        color: AppColors.primary.withOpacity(0.1),
                                        child: Icon(
                                          Icons.sports_cricket,
                                          size: logoSize * 0.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: AppColors.primary.withOpacity(0.1),
                                        child: Icon(
                                          Icons.sports_cricket,
                                          size: logoSize * 0.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ).animate()
                                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                                  .scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // Welcome text with gradient
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.white, Colors.white.withOpacity(0.9)],
                                ).createShader(bounds),
                                child: Text(
                                  'Welcome Back!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 22 : (isTablet ? 26 : 30),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    height: 1.2,
                                  ),
                                ),
                              ).animate()
                                .fadeIn(delay: 300.ms, duration: 500.ms)
                                .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut),
                              
                              SizedBox(height: 4),
                              
                              Text(
                                _isPhoneLogin 
                                    ? 'Enter your phone number to continue' 
                                    : 'Sign in to access your account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.3,
                                  height: 1.4,
                                ),
                              ).animate()
                                .fadeIn(delay: 400.ms, duration: 500.ms),
                              
                              SizedBox(height: isSmallScreen ? 20 : 28),
                              
                              // Premium Form Card
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
                                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          children: [
                                            // Animated toggle switch
                                            MouseRegion(
                                              onEnter: (_) => setState(() => _isToggleHovered = true),
                                              onExit: (_) => setState(() => _isToggleHovered = false),
                                              child: GestureDetector(
                                                onTap: _toggleLoginType,
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 300),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    gradient: _isPhoneLogin
                                                        ? LinearGradient(
                                                            colors: [
                                                              AppColors.primary.withOpacity(0.1),
                                                              AppColors.primaryLight.withOpacity(0.05),
                                                            ],
                                                          )
                                                        : null,
                                                    borderRadius: BorderRadius.circular(14),
                                                    border: Border.all(
                                                      color: _isPhoneLogin 
                                                          ? AppColors.primary 
                                                          : Colors.grey.shade300,
                                                      width: _isPhoneLogin ? 2 : 1,
                                                    ),
                                                    boxShadow: _isToggleHovered
                                                        ? [
                                                            BoxShadow(
                                                              color: AppColors.primary.withOpacity(0.1),
                                                              blurRadius: 6,
                                                              spreadRadius: 1,
                                                            )
                                                          ]
                                                        : null,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(5),
                                                        decoration: BoxDecoration(
                                                          color: _isPhoneLogin 
                                                              ? AppColors.primary.withOpacity(0.15)
                                                              : Colors.grey.shade100,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Icon(
                                                          _isPhoneLogin ? Icons.phone_android : Icons.email,
                                                          color: _isPhoneLogin ? AppColors.primary : Colors.grey.shade600,
                                                          size: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Login with',
                                                              style: TextStyle(
                                                                fontSize: 9,
                                                                color: Colors.grey.shade500,
                                                              ),
                                                            ),
                                                            Text(
                                                              _isPhoneLogin ? 'Phone Number' : 'Email Address',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w600,
                                                                color: _isPhoneLogin ? AppColors.primary : Colors.black87,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.arrow_forward_ios,
                                                        size: 12,
                                                        color: _isPhoneLogin ? AppColors.primary : Colors.grey.shade400,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            const SizedBox(height: 20),
                                            
                                            // Username/Phone field
                                            CustomTextField(
                                              controller: _isPhoneLogin ? _phoneController : _emailController,
                                              label: _isPhoneLogin ? 'Phone Number' : 'Email Address',
                                              hintText: _isPhoneLogin ? '+1 234 567 8900' : 'john@example.com',
                                              keyboardType: _isPhoneLogin ? TextInputType.phone : TextInputType.emailAddress,
                                              prefixIcon: _isPhoneLogin ? Icons.phone_android : Icons.email_outlined,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter ${_isPhoneLogin ? 'phone number' : 'email'}';
                                                }
                                                if (!_isPhoneLogin && !value.contains('@')) {
                                                  return 'Please enter a valid email';
                                                }
                                                if (_isPhoneLogin && value.length < 10) {
                                                  return 'Please enter a valid phone number';
                                                }
                                                return null;
                                              },
                                            ),
                                            
                                            const SizedBox(height: 14),
                                            
                                            // Password field with strength indicator
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CustomTextField(
                                                  controller: _passwordController,
                                                  label: 'Password',
                                                  hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                                                  obscureText: _obscurePassword,
                                                  prefixIcon: Icons.lock_outlined,
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                                      color: Colors.grey.shade600,
                                                      size: 18,
                                                    ),
                                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                                    splashRadius: 18,
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Please enter your password';
                                                    }
                                                    if (value.length < 6) {
                                                      return 'Password must be at least 6 characters';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                if (_passwordController.text.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4, left: 6),
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
                                              ],
                                            ),
                                            
                                            SizedBox(height: isSmallScreen ? 10 : 14),
                                            
                                            // Remember me and forgot password
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.75,
                                                      child: Checkbox(
                                                        value: _rememberMe,
                                                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                                        activeColor: AppColors.primary,
                                                        checkColor: Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        'Remember',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade700,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: Text(
                                                    'Forgot?',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 20),
                                            
                                            // Login button with premium animation
                                            Consumer<AuthProvider>(
                                              builder: (context, auth, child) {
                                                return MouseRegion(
                                                  onEnter: (_) => setState(() => _isLoginHovered = true),
                                                  onExit: (_) => setState(() => _isLoginHovered = false),
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
                                                      boxShadow: _isLoginHovered && auth.status != AuthStatus.loading
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
                                                      onPressed: auth.status == AuthStatus.loading ? null : _login,
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
                                                                Icon(Icons.login, size: 16),
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                  'Sign In',
                                                                  style: TextStyle(
                                                                    fontSize: isSmallScreen ? 15 : 16,
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
                                            
                                            SizedBox(height: isSmallScreen ? 16 : 20),
                                            
                                            // Social login or divider
                                            if (!_isPhoneLogin)
                                              Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                        child: Text(
                                                          'Or continue with',
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
                                            
                                            if (_isPhoneLogin) ...[
                                              Row(
                                                children: [
                                                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    child: Text(
                                                      'or',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 44,
                                                child: OutlinedButton.icon(
                                                  onPressed: _toggleLoginType,
                                                  icon: Icon(Icons.email_outlined, size: 16),
                                                  label: Text(
                                                    'Continue with Email',
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    side: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            
                                            const SizedBox(height: 12),
                                            
                                            // Sign up link
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "New user? ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pushNamed(context, '/register'),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: Text(
                                                    'Sign Up',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primary,
                                                      decoration: TextDecoration.underline,
                                                      decorationColor: AppColors.primary.withOpacity(0.5),
                                                    ),
                                                  ),
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
                                .fadeIn(delay: 500.ms, duration: 800.ms)
                                .slideY(begin: 0.1, duration: 600.ms, curve: Curves.easeOut),
                              
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


