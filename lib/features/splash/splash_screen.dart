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

    final route =
        auth.status == AuthStatus.authenticated ? '/dashboard' : '/phone-login';

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
    final compact = size.width < 380;

    return Scaffold(
      backgroundColor: const Color(0xFF061B45),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthFallbackSplash(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 24 : 32),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _rotateController,
                      builder: (context, child) => Transform.rotate(
                        angle: _rotateController.value * 6.28318,
                        child: Container(
                          width: compact ? 176 : 210,
                          height: compact ? 176 : 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.18),
                              width: 2,
                            ),
                          ),
                          child: CustomPaint(
                            painter: _SplashOrbitPainter(
                              color: AppColors.primary.withOpacity(0.34),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, compact ? -142 : -168),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: compact ? 130 : 152,
                          height: compact ? 130 : 152,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE31E3C),
                              width: 2.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.22),
                                blurRadius: 42,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.sports_cricket_rounded,
                              color: AppColors.primary,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, compact ? -118 : -144),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          Text(
                            'Welcome to Scores11',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF07173B),
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Score matches, manage teams and follow cricket live.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 26),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.72)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.12),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                            backgroundColor:
                                AppColors.primary.withOpacity(0.10),
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Text(
                          'Loading Scores11...',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFallbackSplash extends StatelessWidget {
  const _AuthFallbackSplash();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PitchLinesPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF3FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

class _SplashOrbitPainter extends CustomPainter {
  final Color color;

  const _SplashOrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 16;
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final dotPaint = Paint()..color = AppColors.primary;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - radius), 5, dotPaint);
    canvas.drawCircle(
      Offset(center.dx + radius * 0.86, center.dy + radius * 0.5),
      3.5,
      dotPaint..color = const Color(0xFFE31E3C),
    );
    canvas.drawCircle(
      Offset(center.dx - radius * 0.86, center.dy + radius * 0.5),
      3.5,
      dotPaint..color = const Color(0xFF06B6D4),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashOrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SplashStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SplashStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashDivider extends StatelessWidget {
  const _SplashDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: const Color(0xFFE8EEFF),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({
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
            color.withOpacity(0.13),
            color.withOpacity(0.04),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.045)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final linePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 8, size.width, size.height - 16),
      const Radius.circular(34),
    );
    canvas.drawRRect(rect, fieldPaint);
    canvas.drawRRect(rect, borderPaint);

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 58, linePaint);
    canvas.drawLine(Offset(size.width / 2, 26), Offset(size.width / 2, size.height - 26), linePaint);

    final pitch = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 54, height: 118),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      pitch,
      Paint()
        ..color = const Color(0xFF43A047).withOpacity(0.07)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(pitch, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
