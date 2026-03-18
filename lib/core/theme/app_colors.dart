import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primarySoft = Color(0xFFE3F2FD);
  static const Color secondary = Color(0xFF43A047);
  
  // Status Colors
  static const Color success = Color(0xFF43A047);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF2196F3);
  static const Color live = Color(0xFFF44336);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
  static const Color textHintDark = Color(0xFF616161);
  
  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardBackground = Colors.white;
  static const Color cardBackgroundDark = Color(0xFF2C2C2C);
  
  // Divider Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);
  
  // Gradients
  static const List<Color> primaryGradient = [primary, primaryDark];
  static const List<Color> secondaryGradient = [secondary, Color(0xFF2E7D32)];
  static const List<Color> successGradient = [success, Color(0xFF2E7D32)];
  static const List<Color> errorGradient = [error, Color(0xFFC62828)];
  static const List<Color> liveGradient = [live, Color(0xFFD32F2F)];
  static const List<Color> cardGradient = [Color(0xFFFFFFFF), Color(0xFFF5F5F5)];
  static const List<Color> cardGradientDark = [Color(0xFF2C2C2C), Color(0xFF1E1E1E)];
  
  // Cricket Specific Colors
  static const Color pitch = Color(0xFF8B5A2B);
  static const Color boundary = Color(0xFFFFD700);
  static const Color wicket = Color(0xFF8B4513);
  
  // Match Status Colors
  static const Color scheduled = Color(0xFF2196F3);
  static const Color cancelled = Color(0xFF9E9E9E);
  
  // Team Colors
  static const Color teamIndia = Color(0xFFFF9933);
  static const Color teamAustralia = Color(0xFFFFD700);
  static const Color teamEngland = Color(0xFFCE1124);
  static const Color teamSouthAfrica = Color(0xFF007A4D);
  static const Color teamNewZealand = Color(0xFF000000);
  static const Color teamPakistan = Color(0xFF006B47);
  static const Color teamSriLanka = Color(0xFF8D153A);
  static const Color teamWestIndies = Color(0xFF990000);
  static const Color teamBangladesh = Color(0xFF006A4D);
  static const Color teamAfghanistan = Color(0xFF0000FF);
  
  // Error Light
  static const Color errorLight = Color(0xFFFFEBEE);
}
