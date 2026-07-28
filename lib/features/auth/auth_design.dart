import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AuthDesign {
  static const bg = Color(0xFFF6F8FC);
  static const ink = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const line = Color(0xFFE4E7EC);
  static const cricketGreen = Color(0xFF12B76A);
  static const sky = Color(0xFF1570EF);

  static InputDecoration input({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 21, color: muted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.7)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error, width: 1.7)),
    );
  }
}

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final String kicker;
  final IconData heroIcon;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
    this.kicker = 'SCORES11',
    this.heroIcon = Icons.sports_cricket_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthDesign.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthPitchBackdrop()),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showBack)
                            IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                              style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AuthDesign.ink),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                height: 58,
                                width: 58,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AuthDesign.line),
                                  boxShadow: [
                                    BoxShadow(color: AppColors.primary.withOpacity(0.10), blurRadius: 22, offset: const Offset(0, 8)),
                                  ],
                                ),
                                child: Icon(heroIcon, color: AppColors.primary, size: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(kicker, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 3),
                                    Text(title, style: const TextStyle(color: AuthDesign.ink, fontSize: 28, fontWeight: FontWeight.w900, height: 1.05)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(subtitle, style: const TextStyle(color: AuthDesign.muted, fontSize: 14, fontWeight: FontWeight.w600, height: 1.35)),
                          const SizedBox(height: 20),
                          AuthPanel(child: child),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPanel extends StatelessWidget {
  final Widget child;

  const AuthPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(color: const Color(0xFF101828).withOpacity(0.10), blurRadius: 30, offset: const Offset(0, 14)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool loading;
  final IconData icon;

  const AuthPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 19),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }
}

class _AuthPitchBackdrop extends StatelessWidget {
  const _AuthPitchBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuthPitchPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF1F6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

class _AuthPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()..color = AppColors.primary.withOpacity(0.08);
    final green = Paint()..color = AuthDesign.cricketGreen.withOpacity(0.08);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.10), size.width * 0.34, blue);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.86), size.width * 0.42, green);

    final line = Paint()
      ..color = AppColors.primary.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final pitch = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.52, size.height * 0.40), width: size.width * 0.32, height: size.height * 0.45),
      const Radius.circular(80),
    );
    canvas.drawRRect(pitch, line);
    canvas.drawLine(Offset(size.width * 0.38, size.height * 0.28), Offset(size.width * 0.66, size.height * 0.28), line);
    canvas.drawLine(Offset(size.width * 0.38, size.height * 0.52), Offset(size.width * 0.66, size.height * 0.52), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
