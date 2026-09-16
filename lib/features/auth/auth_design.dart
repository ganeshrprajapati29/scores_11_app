import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AuthDesign {
  static const bg = Color(0xFFF4F7FF);
  static const ink = Color(0xFF081333);
  static const muted = Color(0xFF66708A);
  static const line = Color(0xFFDCE4F2);
  static const cricketGreen = Color(0xFF12B76A);
  static const sky = Color(0xFF008DFB);
  static const royalBlue = Color(0xFF0A28D8);
  static const chipBg = Color(0xFFEAF3FF);
  static const successBg = Color(0xFFEAF8EF);
  static const successBorder = Color(0xFFCBEBD8);
  static const stadiumImage = 'score 11/Login, Register, OTP 1080 x 720 PNG.png';

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF16B7FF), Color(0xFF0A28D8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static InputDecoration input({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelStyle: const TextStyle(
        color: ink,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
      labelStyle: const TextStyle(
        color: ink,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF7B849B),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      hintMaxLines: 2,
      errorMaxLines: 3,
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: sky),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 62, minHeight: 58),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      filled: true,
      fillColor: const Color(0xFFF4F7FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: line, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: line, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: sky, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
    );
  }
}

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final IconData heroIcon;
  final String? heroImage;
  final Widget? belowCard;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
    this.heroIcon = Icons.sports_cricket_rounded,
    this.heroImage,
    this.belowCard,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 380;
    final headerHeight = compact ? 352.0 : 410.0;
    return Scaffold(
      backgroundColor: AuthDesign.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: _AuthStadiumBackdrop(
                image: heroImage ?? AuthDesign.stadiumImage,
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, showBack ? 8 : 18, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showBack)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AuthDesign.ink,
                                  fixedSize: const Size(42, 42),
                                ),
                              ),
                            ),
                          SizedBox(height: showBack ? 4 : 0),
                          Container(
                            width: compact ? 128 : 150,
                            height: compact ? 106 : 124,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE31E3C),
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AuthDesign.sky.withOpacity(0.30),
                                  blurRadius: 34,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => Icon(
                                heroIcon,
                                color: AuthDesign.royalBlue,
                                size: 42,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 380),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.78),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.36),
                                  blurRadius: 28,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AuthDesign.ink,
                                    fontSize: compact ? 30 : 36,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: compact ? 28 : 36),
                        ],
                      ),
                    ),
                    AuthPanel(child: child),
                    if (belowCard != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                        child: belowCard!,
                      )
                    else
                      const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthStadiumBackdrop extends StatelessWidget {
  final String image;

  const _AuthStadiumBackdrop({required this.image});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          image,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const _AuthPitchBackdrop(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.02),
                Colors.white.withOpacity(0.26),
                AuthDesign.bg.withOpacity(0.98),
              ],
              stops: const [0.0, 0.56, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPanel extends StatelessWidget {
  final Widget child;

  const AuthPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.72), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24101828),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool loading;
  final IconData icon;
  final bool trailingArrow;

  const AuthPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
    this.icon = Icons.arrow_forward_rounded,
    this.trailingArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? const LinearGradient(colors: [Color(0xFFB8C4D8), Color(0xFF98A7BE)])
              : AuthDesign.buttonGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: AuthDesign.royalBlue.withOpacity(0.34),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailingArrow) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right_rounded, size: 24),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class AuthOutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final Color color;

  const AuthOutlineButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.color = AuthDesign.royalBlue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.72), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, size: 22),
          ],
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AuthDesign.line)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: CircleAvatar(
            radius: 21,
            backgroundColor: Color(0xFFF0F4FA),
            child: Text(
              'OR',
              style: TextStyle(
                color: AuthDesign.muted,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Expanded(child: Divider(color: AuthDesign.line)),
      ],
    );
  }
}

class AuthOtpBoxRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final bool hasError;

  const AuthOtpBoxRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 330 ? 8.0 : 10.0;
        final boxWidth =
            ((constraints.maxWidth - gap * 5) / 6).clamp(42.0, 58.0).toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(controllers.length, (i) {
            return SizedBox(
              width: boxWidth,
              height: 58,
              child: TextField(
                controller: controllers[i],
                focusNode: focusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AuthDesign.royalBlue,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AuthDesign.line, width: 1.4),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: hasError ? AppColors.error : AuthDesign.line,
                      width: 1.4,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AuthDesign.sky, width: 2),
                  ),
                ),
                onChanged: (v) => onChanged(i, v),
              ),
            );
          }),
        );
      },
    );
  }
}

class AuthSuccessBanner extends StatelessWidget {
  final String title;
  final String description;

  const AuthSuccessBanner({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.verified_user_rounded, color: AuthDesign.sky, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AuthDesign.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: AuthDesign.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSecurityNote extends StatelessWidget {
  final String text;
  final IconData icon;

  const AuthSecurityNote({
    super.key,
    required this.text,
    this.icon = Icons.verified_user_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AuthDesign.sky),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AuthDesign.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthFeatureItem {
  final IconData icon;
  final String label;
  const AuthFeatureItem(this.icon, this.label);
}

class AuthFeatureStrip extends StatelessWidget {
  final List<AuthFeatureItem> items;

  const AuthFeatureStrip({super.key, this.items = defaultItems});

  static const defaultItems = [
    AuthFeatureItem(Icons.verified_user_rounded, 'Secure &\nTrusted'),
    AuthFeatureItem(Icons.bolt_rounded, 'Quick\nVerification'),
    AuthFeatureItem(Icons.mark_email_read_rounded, 'OTP on\nEmail'),
    AuthFeatureItem(Icons.emoji_events_rounded, 'For True\nCricket Fans'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map(
            (item) => Expanded(
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AuthDesign.chipBg, shape: BoxShape.circle),
                    child: Icon(item.icon, color: AuthDesign.royalBlue, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AuthDesign.muted,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class AuthStepProgress extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const AuthStepProgress({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStep = (i ~/ 2) + 1;
          final done = leftStep < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              color: done ? AuthDesign.royalBlue : AuthDesign.line,
            ),
          );
        }
        final step = (i ~/ 2) + 1;
        final active = step == currentStep;
        final done = step < currentStep;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (active || done) ? AuthDesign.royalBlue : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: (active || done) ? AuthDesign.royalBlue : AuthDesign.line,
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: active ? Colors.white : AuthDesign.muted,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                labels[step - 1],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: active ? AuthDesign.royalBlue : AuthDesign.muted,
                ),
              ),
            ),
          ],
        );
      }),
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
    final green = Paint()..color = AuthDesign.cricketGreen.withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), size.width * 0.30, blue);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.30), size.width * 0.22, green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
