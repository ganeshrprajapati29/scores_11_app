import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle displayLarge({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: color, fontFamily: 'Roboto');
  }
  static TextStyle displayMedium({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: color, fontFamily: 'Roboto');
  }
  static TextStyle displaySmall({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: color, fontFamily: 'Roboto');
  }
  static TextStyle headlineLarge({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: color, fontFamily: 'Roboto');
  }
  static TextStyle headlineMedium({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: color, fontFamily: 'Roboto');
  }
  static TextStyle headlineSmall({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: color, fontFamily: 'Roboto');
  }
  static TextStyle titleLarge({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: color, fontFamily: 'Roboto');
  }
  static TextStyle titleMedium({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color, fontFamily: 'Roboto');
  }
  static TextStyle titleSmall({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color, fontFamily: 'Roboto');
  }
  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: color, fontFamily: 'Roboto');
  }
  static TextStyle bodyMedium({Color color = AppColors.textSecondary}) {
    return TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: color, fontFamily: 'Roboto');
  }
  static TextStyle bodySmall({Color color = AppColors.textHint}) {
    return TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: color, fontFamily: 'Roboto');
  }
  static TextStyle labelLarge({Color color = AppColors.textPrimary}) {
    return TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color, fontFamily: 'Roboto');
  }
  static TextStyle labelMedium({Color color = AppColors.textSecondary}) {
    return TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color, fontFamily: 'Roboto');
  }
  static TextStyle labelSmall({Color color = AppColors.textHint}) {
    return TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color, fontFamily: 'Roboto');
  }
}
