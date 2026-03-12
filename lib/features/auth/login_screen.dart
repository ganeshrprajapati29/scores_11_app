import 'package:flutter/material.dart';
import 'dart:ui'; // Add this for ImageFilter
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
  final _emailController = TextEditingController(text: 'admin@crick11.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isPhoneLogin = false;
  bool _isHovered = false;

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
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(authProvider.errorMessage ?? 'Login failed')),
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

  void _toggleLoginType() {
    setState(() {
      _isPhoneLogin = !_isPhoneLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 900;
    final isDesktop = size.width >= 900;
    
    // Responsive padding and sizing
    final horizontalPadding = isSmallScreen ? 24.0 : (isTablet ? 48.0 : 64.0);
    final logoSize = isSmallScreen ? 100.0 : (isTablet ? 130.0 : 160.0);
    final formWidth = isDesktop ? 500.0 : double.infinity;
    
    return Scaffold(
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
          child: Stack(
            children: [
              // Animated background patterns
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: Container(
                    width: formWidth,
                    child: Column(
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
                                  Colors.white.withOpacity(0.9),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: 'https://your-logo-url.com/logo.png',
                                placeholder: (context, url) => Container(
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.sports_cricket,
                                    size: 50,
                                    color: AppColors.primary,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.sports_cricket,
                                      size: logoSize * 0.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ).animate()
                            .fadeIn(duration: 1000.ms, curve: Curves.easeOut)
                            .scale(delay: 300.ms, duration: 1200.ms, curve: Curves.elasticOut)
                            .shimmer(delay: 800.ms, duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 24 : 32),
                        
                        // Welcome text with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.white, Colors.white.withOpacity(0.9)],
                          ).createShader(bounds),
                          child: Text(
                            'Welcome Back!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 28 : (isTablet ? 32 : 36),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ).animate()
                          .fadeIn(delay: 400.ms, duration: 800.ms)
                          .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOut),
                        
                        SizedBox(height: 8),
                        
                        Text(
                          _isPhoneLogin 
                              ? 'Enter your phone number to continue' 
                              : 'Sign in to access your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ).animate()
                          .fadeIn(delay: 600.ms, duration: 800.ms),
                        
                        SizedBox(height: isSmallScreen ? 32 : 48),
                        
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
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Animated toggle switch
                                      MouseRegion(
                                        onEnter: (_) => setState(() => _isHovered = true),
                                        onExit: (_) => setState(() => _isHovered = false),
                                        child: GestureDetector(
                                          onTap: _toggleLoginType,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              gradient: _isPhoneLogin
                                                  ? LinearGradient(
                                                      colors: [
                                                        AppColors.primary.withOpacity(0.1),
                                                        AppColors.primaryLight.withOpacity(0.05),
                                                      ],
                                                    )
                                                  : null,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _isPhoneLogin 
                                                    ? AppColors.primary 
                                                    : Colors.grey.shade300,
                                                width: _isPhoneLogin ? 2 : 1,
                                              ),
                                              boxShadow: _isHovered
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColors.primary.withOpacity(0.1),
                                                        blurRadius: 10,
                                                        spreadRadius: 2,
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: _isPhoneLogin 
                                                        ? AppColors.primary.withOpacity(0.2)
                                                        : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    _isPhoneLogin ? Icons.phone_android : Icons.email,
                                                    color: _isPhoneLogin ? AppColors.primary : Colors.grey.shade600,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Login with',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade500,
                                                      ),
                                                    ),
                                                    Text(
                                                      _isPhoneLogin ? 'Phone Number' : 'Email Address',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: _isPhoneLogin ? AppColors.primary : Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                  color: _isPhoneLogin ? AppColors.primary : Colors.grey.shade400,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
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
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Password field with strength indicator
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CustomTextField(
                                            controller: _passwordController,
                                            label: 'Password',
                                            hintText: '••••••••',
                                            obscureText: _obscurePassword,
                                            prefixIcon: Icons.lock_outlined,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                                color: Colors.grey.shade600,
                                              ),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                                              padding: const EdgeInsets.only(top: 8, left: 12),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _passwordController.text.length >= 8
                                                        ? Icons.check_circle
                                                        : Icons.info,
                                                    size: 14,
                                                    color: _passwordController.text.length >= 8
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _passwordController.text.length >= 8
                                                        ? 'Strong password'
                                                        : 'Use at least 8 characters for strong password',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: _passwordController.text.length >= 8
                                                          ? Colors.green.shade700
                                                          : Colors.orange.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      
                                      SizedBox(height: isSmallScreen ? 16 : 20),
                                      
                                      // Remember me and forgot password
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 40,
                                                width: 40,
                                                child: Checkbox(
                                                  value: _rememberMe,
                                                  onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                                  activeColor: AppColors.primary,
                                                  checkColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Remember me',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            child: Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Login button with premium animation
                                      Consumer<AuthProvider>(
                                        builder: (context, auth, child) {
                                          return MouseRegion(
                                            onEnter: (_) => setState(() => _isHovered = true),
                                            onExit: (_) => setState(() => _isHovered = false),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              width: double.infinity,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.primary,
                                                    AppColors.primaryLight,
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: _isHovered && auth.status != AuthStatus.loading
                                                    ? [
                                                        BoxShadow(
                                                          color: AppColors.primary.withOpacity(0.4),
                                                          blurRadius: 20,
                                                          spreadRadius: 5,
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
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                ),
                                                child: auth.status == AuthStatus.loading
                                                    ? const SizedBox(
                                                        height: 30,
                                                        width: 30,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 3,
                                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                                        ),
                                                      )
                                                    : Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Icon(Icons.login, size: 22),
                                                          const SizedBox(width: 12),
                                                          Text(
                                                            'Sign In',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      
                                      SizedBox(height: isSmallScreen ? 24 : 32),
                                      
                                      // Social login or divider
                                      if (!_isPhoneLogin)
                                        Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  child: Text(
                                                    'Or continue with',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 24),
                                            
                                            // Social buttons
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                _buildSocialButton(
                                                  icon: Icons.g_mobiledata,
                                                  label: 'Google',
                                                  color: Colors.red,
                                                  onTap: () {},
                                                ),
                                                _buildSocialButton(
                                                  icon: Icons.facebook,
                                                  label: 'Facebook',
                                                  color: Colors.blue.shade800,
                                                  onTap: () {},
                                                ),
                                                _buildSocialButton(
                                                  icon: Icons.apple,
                                                  label: 'Apple',
                                                  color: Colors.black,
                                                  onTap: () {},
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
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text(
                                                'or',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: OutlinedButton.icon(
                                            onPressed: _toggleLoginType,
                                            icon: const Icon(Icons.email_outlined),
                                            label: const Text(
                                              'Continue with Email',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 2),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Sign up link
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Don't have an account? ",
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pushNamed(context, '/register'),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            ),
                                            child: Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                fontSize: 16,
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
                          .fadeIn(delay: 800.ms, duration: 1000.ms)
                          .slideY(begin: 0.2, duration: 800.ms, curve: Curves.easeOut),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
}) {
  return MouseRegion(
    onEnter: (_) => setState(() => _isHovered = true),
    onExit: (_) => setState(() => _isHovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            _isHovered ? Colors.grey.shade100 : Colors.grey.shade50,
          ],
        ),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    ),
  );
}
}