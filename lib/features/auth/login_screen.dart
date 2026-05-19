import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/connectivity_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isPhoneLogin = true;
  
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoggingIn) return;
    
    if (!_formKey.currentState!.validate()) return;
    
    _isLoggingIn = true;
    FocusScope.of(context).unfocus();
    
    if (!mounted) {
      _isLoggingIn = false;
      return;
    }
    
    try {
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
        _isLoggingIn = false;
        return;
      }

      final authProvider = context.read<AuthProvider>();
      
      final identifier = _isPhoneLogin 
          ? _phoneController.text.trim() 
          : _emailController.text.trim();
      final password = _passwordController.text;
      
      final success = await authProvider.login(identifier, password);

      if (!mounted) {
        _isLoggingIn = false;
        return;
      }
      
      if (success) {
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Login failed'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isLoggingIn = false;
    }
  }

  void _toggleLoginType() {
    setState(() {
      _isPhoneLogin = !_isPhoneLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      // ✅ FIX: Prevent pop when keyboard is visible
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // If keyboard is showing, don't pop - just unfocus
        if (MediaQuery.of(context).viewInsets.bottom > 0) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                Color(0xFF1a237e),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.sports_cricket,
                          size: 45,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: const Text(
                      'SCORES11',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 600 ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPhoneLogin
                        ? 'Manage teams, live scoring and scorecards securely'
                        : 'Continue with your registered email account',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
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
                                child: const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Secure Sign In', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                    SizedBox(height: 2),
                                    Text('Access your cricket workspace', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          GestureDetector(
                            onTap: _toggleLoginType,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isPhoneLogin ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: !_isPhoneLogin ? AppColors.primary : Colors.grey.shade300,
                                  width: !_isPhoneLogin ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isPhoneLogin ? Icons.phone_android : Icons.email,
                                    color: !_isPhoneLogin ? AppColors.primary : Colors.grey.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _isPhoneLogin ? 'Use Phone Number' : 'Use Email Address',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: !_isPhoneLogin ? AppColors.primary : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: !_isPhoneLogin ? AppColors.primary : Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_isPhoneLogin)
                            TextFormField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter 10-digit number',
                                prefixIcon: const Icon(Icons.phone_android, size: 22),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(14)),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone number';
                                }
                                if (value.length < 10) {
                                  return 'Enter valid 10-digit number';
                                }
                                return null;
                              },
                              onEditingComplete: () {
                                FocusScope.of(context).requestFocus(_passwordFocusNode);
                              },
                            )
                          else
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(Icons.email_outlined, size: 22),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(14)),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              onEditingComplete: () {
                                FocusScope.of(context).requestFocus(_passwordFocusNode);
                              },
                            ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 22),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (!mounted) return;
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            // ✅ FIX: Unfocus keyboard before login to prevent crash
                            onFieldSubmitted: (value) {
                              FocusScope.of(context).unfocus();
                              if (!mounted) return;
                              _login();
                            },
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/forgot-password');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?', 
                                  style: TextStyle(color: AppColors.primary, fontSize: 13)
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Consumer<AuthProvider>(
                            builder: (context, auth, child) => SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: (auth.status == AuthStatus.loading || _isLoggingIn) ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: (auth.status == AuthStatus.loading || _isLoggingIn)
                                    ? const SizedBox(
                                        width: 24, 
                                        height: 24, 
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5, 
                                          color: Colors.white
                                        )
                                      )
                                    : const Text(
                                        'Sign In', 
                                        style: TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          if (_isPhoneLogin)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _toggleLoginType,
                                icon: const Icon(Icons.email_outlined, size: 18),
                                label: const Text('Continue with Email'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)
                                  ),
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ", 
                                style: TextStyle(fontSize: 13, color: Colors.grey)
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Sign Up', 
                                  style: TextStyle(
                                    fontSize: 13, 
                                    fontWeight: FontWeight.bold, 
                                    color: AppColors.primary
                                  )
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
