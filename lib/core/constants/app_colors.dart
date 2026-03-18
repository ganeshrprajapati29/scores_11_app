import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF6AB7FF);
  static const Color primaryDark = Color(0xFF005CB2);
  static const LinearGradient primaryGradientObject = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // NEW: List<Color> gradients for theme_config
  static const List<Color> primaryGradient = [
    Color(0xFF1E88E5),
    Color(0xFF1565C0),
  ];
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFF6F00);
  static const Color secondaryLight = Color(0xFFFFA040);
  static const Color secondaryDark = Color(0xFFC43E00);
  static const List<Color> secondaryGradient = [
    Color(0xFFFF6F00),
    Color(0xFFE65100),
  ];
  
  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF2C2C2C);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFFE0E0E0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textHintDark = Color(0xFF6B6B6B);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF2E7D32),
  ];
  static const List<Color> errorGradient = [
    Color(0xFFF44336),
    Color(0xFFC62828),
  ];
  
  // Match Status Colors
  static const Color live = Color(0xFFE53935);
  static const List<Color> liveGradient = [
    Color(0xFFE53935),
    Color(0xFFB71C1C),
  ];
  static const Color scheduled = Color(0xFF9E9E9E);
  static const Color cancelled = Color(0xFFFF9800);
  static const Color completed = Color(0xFF43A047);
  static const List<Color> cardGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
  ];
  static const List<Color> cardGradientDark = [
    Color(0xFF2C2C2C),
    Color(0xFF1E1E1E),
  ];
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Cricket Specific - NEW
  static const Color pitch = Color(0xFF8D6E63);
  static const Color boundary = Color(0xFF4CAF50);
  static const Color wicket = Color(0xFF795548);
  
  // Team Colors - NEW
  static const Color teamIndia = Color(0xFF0066B3);
  static const Color teamAustralia = Color(0xFFFFD700);
  static const Color teamEngland = Color(0xFFCE1124);
  static const Color teamSouthAfrica = Color(0xFF007A4D);
  static const Color teamNewZealand = Color(0xFF000000);
  static const Color teamPakistan = Color(0xFF01411C);
  static const Color teamSriLanka = Color(0xFF0000FF);
  static const Color teamWestIndies = Color(0xFF8A1538);
  static const Color teamBangladesh = Color(0xFF006A4D);
  static const Color teamAfghanistan = Color(0xFFD52027);
  
  // Misc
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
  static const Color cricketPitch = Color(0xFF8D6E63);
  static const Color cricketBall = Color(0xFFD32F2F);
  static const Color cricketBat = Color(0xFF5D4037);
}
