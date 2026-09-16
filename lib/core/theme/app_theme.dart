import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF2A2A3E);
  
  // Accent Colors
  static const Color neonCyan = Color(0xFF1657CC);
  static const Color electricPurple = Color(0xFF1657CC);
  static const Color deepNavy = Color(0xFF0D2B5E);
  static const Color neonGreen = Color(0xFF16A34A);
  static const Color neonPink = Color(0xFFE31E3C);
  
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: deepNavy,
    colorScheme: const ColorScheme.light(
      primary: deepNavy,
      secondary: neonCyan,
      tertiary: electricPurple,
      surface: lightSurface,
      background: lightBackground,
    ),
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w800),
      displayMedium: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800),
      titleLarge: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.dmSans(fontSize: 14),
      bodyMedium: GoogleFonts.dmSans(fontSize: 13),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: deepNavy,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.white,
      titleTextStyle: TextStyle(
        color: deepNavy,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: deepNavy, size: 22),
      actionsIconTheme: IconThemeData(color: deepNavy, size: 22),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: lightCard,
      surfaceTintColor: Colors.white,
      shadowColor: const Color(0x1A101828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF4F7FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: neonCyan, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonCyan,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: neonCyan,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: neonCyan),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: electricPurple,
    colorScheme: const ColorScheme.dark(
      primary: electricPurple,
      secondary: neonCyan,
      tertiary: neonPink,
      surface: darkSurface,
      background: darkBackground,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.orbitron(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70),
      bodyMedium: GoogleFonts.dmSans(fontSize: 12, color: Colors.white60),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  
  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? Colors.white : Colors.white).withOpacity(0.1),
            (isDark ? Colors.white : Colors.white).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: (isDark ? AppTheme.neonCyan : AppTheme.deepNavy).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppTheme.electricPurple : AppTheme.deepNavy).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        child: BackdropFilter(
          filter: isDark 
              ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
              : ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: child,
        ),
      ),
    );
  }
}

class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsets? padding;
  
  const GradientBorderContainer({
    super.key,
    required this.child,
    required this.gradient,
    this.borderRadius = 24,
    this.borderWidth = 2,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: child,
        ),
      ),
    );
  }
}
