import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Bat swing controller
  late AnimationController _batController;
  late Animation<double> _batSwingAnim;

  // Ball trajectory controller
  late AnimationController _ballController;
  late Animation<double> _ballXAnim;
  late Animation<double> _ballYAnim;
  late Animation<double> _ballScaleAnim;
  late Animation<double> _ballOpacityAnim;

  // Ball spin
  late AnimationController _ballSpinController;

  // Impact flash
  late AnimationController _impactController;
  late Animation<double> _impactAnim;

  // Stars / sparks
  late AnimationController _sparkController;

  // Logo + text reveal
  late AnimationController _revealController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _textSlideAnim;
  late Animation<double> _textFadeAnim;
  late Animation<double> _taglineFadeAnim;
  late Animation<double> _loaderFadeAnim;

  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // --- Bat ---
    _batController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _batSwingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _batController, curve: Curves.easeInOutBack),
    );

    // --- Ball ---
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ballXAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ballController, curve: Curves.easeIn),
    );
    // Parabolic arc: goes up then off screen
    _ballYAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -1, end: 0.5), weight: 60),
    ]).animate(CurvedAnimation(parent: _ballController, curve: Curves.linear));
    _ballScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.2), weight: 70),
    ]).animate(_ballController);
    _ballOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_ballController);

    // --- Ball spin ---
    _ballSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // --- Impact flash ---
    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _impactAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 70),
    ]).animate(_impactController);

    // --- Sparks ---
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // --- Reveal ---
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScaleAnim = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );
    _textSlideAnim = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );
    _textFadeAnim = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
    );
    _taglineFadeAnim = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.5, 0.85, curve: Curves.easeIn),
    );
    _loaderFadeAnim = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    // Sequence: wait 600ms → bat swing → impact + ball + sparks → wait → logo reveal
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _animationStarted = true);
      _batController.forward().then((_) {
        _impactController.forward();
        _ballController.forward();
        _ballSpinController.repeat();
        _sparkController.forward();
        Future.delayed(const Duration(milliseconds: 950), () {
          _ballSpinController.stop();
          if (!mounted) return;
          _revealController.forward();
        });
      });
    });
  }

  Future<void> _initializeApp() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.checkAuth();
      }
    });
  }

  @override
  void dispose() {
    _batController.dispose();
    _ballController.dispose();
    _ballSpinController.dispose();
    _impactController.dispose();
    _sparkController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Navigate after auth check
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final status = authProvider.status;
          if (status != AuthStatus.initial && status != AuthStatus.loading) {
            final route = status == AuthStatus.authenticated
                ? AppRoutes.dashboard
                : AppRoutes.login;
            Navigator.pushReplacementNamed(context, route);
          }
        });

        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: Stack(
            children: [
              // ── Deep dark gradient background ──
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.2,
                    colors: [
                      Color(0xFF1A3A6B),
                      Color(0xFF0D1F3C),
                      Color(0xFF060E1E),
                    ],
                  ),
                ),
              ),

              // ── Stadium arc lines ──
              CustomPaint(
                size: Size(size.width, size.height),
                painter: _StadiumLinePainter(),
              ),

              // ── Glow orbs ──
              Positioned(
                top: -60,
                left: -60,
                child: _GlowOrb(size: 220, color: const Color(0xFF1565C0), opacity: 0.18),
              ),
              Positioned(
                bottom: -80,
                right: -80,
                child: _GlowOrb(size: 260, color: const Color(0xFF0D47A1), opacity: 0.12),
              ),
              Positioned(
                top: size.height * 0.35,
                right: -40,
                child: _GlowOrb(size: 140, color: const Color(0xFF42A5F5), opacity: 0.1),
              ),

              // ── MAIN CONTENT ──
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.06),

                    // ── Cricket animation area ──
                    SizedBox(
                      width: size.width,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Impact flash ring
                          AnimatedBuilder(
                            animation: _impactAnim,
                            builder: (_, __) {
                              return Opacity(
                                opacity: _impactAnim.value,
                                child: Container(
                                  width: 90 + 80 * _impactAnim.value,
                                  height: 90 + 80 * _impactAnim.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFFD54F),
                                      width: 3 * (1 - _impactAnim.value) + 0.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Sparks
                          AnimatedBuilder(
                            animation: _sparkController,
                            builder: (_, __) {
                              if (_sparkController.value == 0) {
                                return const SizedBox.shrink();
                              }
                              return CustomPaint(
                                size: const Size(200, 200),
                                painter: _SparkPainter(_sparkController.value),
                              );
                            },
                          ),

                          // Flying ball
                          AnimatedBuilder(
                            animation: _ballController,
                            builder: (_, __) {
                              if (!_animationStarted) return const SizedBox.shrink();
                              final xOffset = _ballXAnim.value * size.width * 0.55;
                              final yOffset = _ballYAnim.value * 120;
                              return Transform.translate(
                                offset: Offset(xOffset, yOffset),
                                child: AnimatedBuilder(
                                  animation: _ballSpinController,
                                  builder: (_, __) {
                                    return Transform.rotate(
                                      angle: _ballSpinController.value * 2 * math.pi * 4,
                                      child: Opacity(
                                        opacity: _ballOpacityAnim.value,
                                        child: Transform.scale(
                                          scale: _ballScaleAnim.value,
                                          child: const _CricketBall(radius: 18),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),

                          // Cricket bat
                          AnimatedBuilder(
                            animation: _batSwingAnim,
                            builder: (_, __) {
                              // Swing from ~45° backswing to ~-60° follow-through
                              final angle = _batSwingAnim.value == 0
                                  ? 0.7 // resting
                                  : 0.7 - (_batSwingAnim.value * 2.2);
                              return Transform.rotate(
                                angle: angle,
                                alignment: Alignment.bottomCenter,
                                child: const _CricketBat(),
                              );
                            },
                          ),

                          // SIX! text popup
                          AnimatedBuilder(
                            animation: _impactAnim,
                            builder: (_, __) {
                              if (_impactAnim.value < 0.05) return const SizedBox.shrink();
                              return Transform.translate(
                                offset: Offset(-40, -60 - 30 * _impactAnim.value),
                                child: Opacity(
                                  opacity: math.min(_impactAnim.value * 2, 1.0),
                                  child: Text(
                                    'SIX!',
                                    style: TextStyle(
                                      color: const Color(0xFFFFD54F),
                                      fontSize: 28 + 10 * _impactAnim.value,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFF8F00).withOpacity(0.8),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Logo card ──
                    AnimatedBuilder(
                      animation: _logoScaleAnim,
                      builder: (_, child) => Transform.scale(
                        scale: _logoScaleAnim.value,
                        child: child,
                      ),
                      child: Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withOpacity(0.5),
                              blurRadius: 35,
                              offset: const Offset(0, 14),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF42A5F5).withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.sports_cricket,
                              size: 60,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── App name ──
                    AnimatedBuilder(
                      animation: _textSlideAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, 30 * (1 - _textSlideAnim.value)),
                        child: Opacity(
                          opacity: _textFadeAnim.value,
                          child: child,
                        ),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFF90CAF9)],
                        ).createShader(bounds),
                        child: const Text(
                          'Scores11',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Tagline ──
                    AnimatedBuilder(
                      animation: _taglineFadeAnim,
                      builder: (_, child) => Opacity(
                        opacity: _taglineFadeAnim.value,
                        child: child,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TaglineDot(),
                          const SizedBox(width: 8),
                          Text(
                            'Play',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 14,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TaglineDot(),
                          const SizedBox(width: 8),
                          Text(
                            'Compete',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 14,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TaglineDot(),
                          const SizedBox(width: 8),
                          Text(
                            'Win',
                            style: TextStyle(
                              color: const Color(0xFFFFD54F).withOpacity(0.95),
                              fontSize: 14,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 56),

                    // ── Loader / check ──
                    AnimatedBuilder(
                      animation: _loaderFadeAnim,
                      builder: (_, __) {
                        return Opacity(
                          opacity: _loaderFadeAnim.value,
                          child: authProvider.status == AuthStatus.authenticated
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF66BB6A),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF66BB6A),
                                    size: 22,
                                  ),
                                )
                              : SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Bottom credit ──
              Positioned(
                bottom: 36,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _loaderFadeAnim,
                  builder: (_, child) => Opacity(
                    opacity: _loaderFadeAnim.value,
                    child: child,
                  ),
                  child: Center(
                    child: Text(
                      'Powered by Scores11',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
// Custom Widgets
// ══════════════════════════════════════════════

class _TaglineDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF42A5F5).withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity * 0.5),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _CricketBall extends StatelessWidget {
  final double radius;

  const _CricketBall({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF5350).withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _BallSeamPainter(),
      ),
    );
  }
}

class _BallSeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Curved seam lines
    final path1 = Path()
      ..moveTo(cx * 0.4, cy * 0.2)
      ..quadraticBezierTo(cx * 0.1, cy, cx * 0.4, cy * 1.8);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(cx * 1.6, cy * 0.2)
      ..quadraticBezierTo(cx * 1.9, cy, cx * 1.6, cy * 1.8);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CricketBat extends StatelessWidget {
  const _CricketBat();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 130,
      child: CustomPaint(
        painter: _BatPainter(),
      ),
    );
  }
}

class _BatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Blade
    final bladePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFF5DEB3),
          const Color(0xFFDEB887),
          const Color(0xFFD2A679),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.72));

    final bladePath = Path()
      ..moveTo(w * 0.15, 0)
      ..lineTo(w * 0.85, 0)
      ..quadraticBezierTo(w, h * 0.06, w * 0.95, h * 0.6)
      ..lineTo(w * 0.55, h * 0.72)
      ..lineTo(w * 0.45, h * 0.72)
      ..lineTo(w * 0.05, h * 0.6)
      ..quadraticBezierTo(0, h * 0.06, w * 0.15, 0)
      ..close();

    canvas.drawPath(bladePath, bladePaint);

    // Blade edge highlight
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bladePath, edgePaint);

    // Toe curve
    final toePaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFDEB887), const Color(0xFFC8965A)],
      ).createShader(Rect.fromLTWH(0, h * 0.68, w, h * 0.1));

    final toePath = Path()
      ..moveTo(w * 0.45, h * 0.72)
      ..quadraticBezierTo(w * 0.5, h * 0.8, w * 0.55, h * 0.72);
    final toeFill = Paint()..color = const Color(0xFFC19A6B);
    canvas.drawPath(toePath, toeFill);

    // Handle
    final handleGradient = LinearGradient(
      colors: [const Color(0xFF5D4037), const Color(0xFF3E2723)],
    ).createShader(Rect.fromLTWH(w * 0.37, h * 0.72, w * 0.26, h * 0.28));

    final handlePaint = Paint()..shader = handleGradient;
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.37, h * 0.72, w * 0.26, h * 0.26),
      const Radius.circular(4),
    );
    canvas.drawRRect(handleRect, handlePaint);

    // Handle grip lines
    final gripPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      final y = h * 0.74 + i * (h * 0.26 / 5);
      canvas.drawLine(Offset(w * 0.37, y), Offset(w * 0.63, y), gripPaint);
    }

    // Grip end cap
    final capPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.96, w * 0.3, h * 0.04),
        const Radius.circular(3),
      ),
      capPaint,
    );

    // Bat brand line
    final brandPaint = Paint()
      ..color = const Color(0xFFB8860B).withOpacity(0.6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(w * 0.3, h * 0.2),
      Offset(w * 0.7, h * 0.2),
      brandPaint,
    );
    canvas.drawLine(
      Offset(w * 0.28, h * 0.27),
      Offset(w * 0.72, h * 0.27),
      brandPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparkPainter extends CustomPainter {
  final double progress;

  _SparkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rng = math.Random(42);

    final sparkColors = [
      const Color(0xFFFFD54F),
      const Color(0xFFFFAB40),
      const Color(0xFFFFF176),
      Colors.white,
    ];

    for (int i = 0; i < 14; i++) {
      final angle = (i / 14) * 2 * math.pi + rng.nextDouble() * 0.4;
      final maxDist = 55 + rng.nextDouble() * 35;
      final dist = maxDist * progress;
      final x = cx + math.cos(angle) * dist;
      final y = cy + math.sin(angle) * dist;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final length = (8 + rng.nextDouble() * 12) * (1 - progress * 0.5);

      final paint = Paint()
        ..color = sparkColors[i % sparkColors.length].withOpacity(opacity)
        ..strokeWidth = 1.5 + rng.nextDouble()
        ..strokeCap = StrokeCap.round;

      final endX = x + math.cos(angle) * length * 0.5;
      final endY = y + math.sin(angle) * length * 0.5;
      canvas.drawLine(Offset(x, y), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StadiumLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Concentric ellipses suggesting stadium perspective
    for (int i = 1; i <= 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.85),
          width: size.width * 0.3 * i,
          height: size.height * 0.08 * i,
        ),
        paint,
      );
    }

    // Vertical light rays from top
    final rayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1;

    for (int i = 0; i < 6; i++) {
      final x = size.width * 0.1 + i * (size.width * 0.16);
      canvas.drawLine(Offset(x, 0), Offset(size.width / 2, size.height * 0.8), rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}