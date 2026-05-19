import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _hasNavigated = false;

  late AnimationController _logoController;
  late AnimationController _rotateController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    _logoController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted || _hasNavigated) return;

    final auth = context.read<AuthProvider>();

    try {
      await auth.checkAuth();
    } catch (e) {
      debugPrint("Splash Auth Error: $e");
    }

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    final route = auth.status == AuthStatus.authenticated
        ? '/dashboard'
        : '/login';

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      body: Stack(
        children: [

          /// TOP GLOW
          Positioned(
            top: -120,
            right: -80,
            child: _GlowCircle(
              size: size.width * 0.7,
              color: Colors.blueAccent,
            ),
          ),

          /// BOTTOM GLOW
          Positioned(
            bottom: -120,
            left: -100,
            child: _GlowCircle(
              size: size.width * 0.8,
              color: AppColors.primary,
            ),
          ),

          /// ROTATING LIGHT
          Center(
            child: RotationTransition(
              turns: _rotateController,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [

                  const Spacer(),

                  /// LOGO ANIMATION
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              Colors.blueAccent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.45),
                              blurRadius: 35,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_cricket_rounded,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// APP NAME
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      "Scores11",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      "Live Cricket Scores & Match Updates",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  /// LOADING
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),

                  const Spacer(),

                  /// FOOTER CARD
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Text(
                          "Loading your cricket experience...",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}