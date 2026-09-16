import '../../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

// ==================== COLOR CONSTANTS ====================
class ThemeColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primarySoft = Color(0xFFE3F2FD);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFF6F00);
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondarySoft = Color(0xFFFFF3E0);
  
  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF2C2C2C);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFFE0E0E0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF000000);
  
  // Dark Text Colors
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textHintDark = Color(0xFF6B6B6B);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF9C4);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFBBDEFB);
  
  // Match Status Colors
  static const Color live = Color(0xFFE53935);
  static const Color liveLight = Color(0xFFFFEBEE);
  static const Color scheduled = Color(0xFF9E9E9E);
  static const Color scheduledLight = Color(0xFFF5F5F5);
  static const Color completed = Color(0xFF4CAF50);
  static const Color completedLight = Color(0xFFE8F5E9);
  static const Color cancelled = Color(0xFFFF9800);
  static const Color cancelledLight = Color(0xFFFFF3E0);
  
  // Cricket Specific
  static const Color pitch = Color(0xFF8D6E63);
  static const Color pitchLight = Color(0xFFD7CCC8);
  static const Color boundary = Color(0xFF4CAF50);
  static const Color boundaryLight = Color(0xFFC8E6C9);
  static const Color wicket = Color(0xFF795548);
  static const Color wicketLight = Color(0xFFD7CCC8);
  
  // Team Colors (Common team colors)
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
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF1E88E5),
    Color(0xFF1565C0),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFFFF6F00),
    Color(0xFFE65100),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF2E7D32),
  ];
  
  static const List<Color> errorGradient = [
    Color(0xFFF44336),
    Color(0xFFC62828),
  ];
  
  static const List<Color> liveGradient = [
    Color(0xFFE53935),
    Color(0xFFB71C1C),
  ];
  
  static const List<Color> cardGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
  ];
  
  static const List<Color> cardGradientDark = [
    Color(0xFF2C2C2C),
    Color(0xFF1E1E1E),
  ];
}

// ==================== TEXT STYLES ====================
class ThemeTextStyles {
  // Display Styles
  static TextStyle displayLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle displayMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.25,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle displaySmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: color ?? AppColors.textPrimary,
  );
  
  // Headline Styles
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle headlineMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle headlineSmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color ?? AppColors.textPrimary,
  );
  
  // Title Styles
  static TextStyle titleLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle titleMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle titleSmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: color ?? AppColors.textPrimary,
  );
  
  // Body Styles
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: color ?? AppColors.textSecondary,
  );
  
  static TextStyle bodySmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: color ?? AppColors.textSecondary,
  );
  
  // Label Styles
  static TextStyle labelLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.1,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle labelMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.1,
    color: color ?? AppColors.textSecondary,
  );
  
  static TextStyle labelSmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.1,
    color: color ?? AppColors.textHint,
  );
  
  // Cricket Specific Styles
  static TextStyle scoreLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle scoreMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle scoreSmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle teamName({Color? color}) => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle matchStatus({Color? color}) => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: color,
  );
  
  static TextStyle liveStatus() => matchStatus(color: AppColors.live);
  
  static TextStyle overNumber({Color? color}) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle runRate({Color? color}) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: color ?? AppColors.textSecondary,
  );
  
  static TextStyle playerName({Color? color}) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: color ?? AppColors.textPrimary,
  );
  
  static TextStyle playerStats({Color? color}) => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: color ?? AppColors.textSecondary,
  );
}

// ==================== GRADIENTS ====================
class AppGradients {
  static LinearGradient get primary => const LinearGradient(
          colors: ThemeColors.primaryGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get secondary => const LinearGradient(
          colors: ThemeColors.secondaryGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get success => const LinearGradient(
          colors: ThemeColors.successGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get error => const LinearGradient(
          colors: ThemeColors.errorGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get live => const LinearGradient(
          colors: ThemeColors.liveGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get card => LinearGradient(
    colors: AppColors.cardGradient.colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get cardDark => LinearGradient(
    colors: AppColors.cardGradientDark.colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get shimmer => LinearGradient(
    colors: [
      Colors.grey[300]!,
      Colors.grey[100]!,
      Colors.grey[300]!,
    ],
    stops: const [0.1, 0.3, 0.5],
    begin: const Alignment(-1.0, -0.5),
    end: const Alignment(1.0, 0.5),
    transform: const GradientRotation(0.5),
  );
  
  static LinearGradient get matchCard => LinearGradient(
    colors: [
      AppColors.surface,
      AppColors.surface.withOpacity(0.95),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ==================== CUSTOM THEME EXTENSION ====================
class CricketThemeData extends ThemeExtension<CricketThemeData> {
  final Color pitchColor;
  final Color boundaryColor;
  final Color wicketColor;
  final Color liveMatchColor;
  final Color scheduledMatchColor;
  final Color completedMatchColor;
  final Color cancelledMatchColor;
  final Color teamIndiaColor;
  final Color teamAustraliaColor;
  final Color teamEnglandColor;
  final Color teamSouthAfricaColor;
  final Color teamNewZealandColor;
  final Color teamPakistanColor;
  final Color teamSriLankaColor;
  final Color teamWestIndiesColor;
  final Color teamBangladeshColor;
  final Color teamAfghanistanColor;
  
  const CricketThemeData({
    required this.pitchColor,
    required this.boundaryColor,
    required this.wicketColor,
    required this.liveMatchColor,
    required this.scheduledMatchColor,
    required this.completedMatchColor,
    required this.cancelledMatchColor,
    required this.teamIndiaColor,
    required this.teamAustraliaColor,
    required this.teamEnglandColor,
    required this.teamSouthAfricaColor,
    required this.teamNewZealandColor,
    required this.teamPakistanColor,
    required this.teamSriLankaColor,
    required this.teamWestIndiesColor,
    required this.teamBangladeshColor,
    required this.teamAfghanistanColor,
  });
  
  @override
  ThemeExtension<CricketThemeData> copyWith({
    Color? pitchColor,
    Color? boundaryColor,
    Color? wicketColor,
    Color? liveMatchColor,
    Color? scheduledMatchColor,
    Color? completedMatchColor,
    Color? cancelledMatchColor,
    Color? teamIndiaColor,
    Color? teamAustraliaColor,
    Color? teamEnglandColor,
    Color? teamSouthAfricaColor,
    Color? teamNewZealandColor,
    Color? teamPakistanColor,
    Color? teamSriLankaColor,
    Color? teamWestIndiesColor,
    Color? teamBangladeshColor,
    Color? teamAfghanistanColor,
  }) {
    return CricketThemeData(
      pitchColor: pitchColor ?? this.pitchColor,
      boundaryColor: boundaryColor ?? this.boundaryColor,
      wicketColor: wicketColor ?? this.wicketColor,
      liveMatchColor: liveMatchColor ?? this.liveMatchColor,
      scheduledMatchColor: scheduledMatchColor ?? this.scheduledMatchColor,
      completedMatchColor: completedMatchColor ?? this.completedMatchColor,
      cancelledMatchColor: cancelledMatchColor ?? this.cancelledMatchColor,
      teamIndiaColor: teamIndiaColor ?? this.teamIndiaColor,
      teamAustraliaColor: teamAustraliaColor ?? this.teamAustraliaColor,
      teamEnglandColor: teamEnglandColor ?? this.teamEnglandColor,
      teamSouthAfricaColor: teamSouthAfricaColor ?? this.teamSouthAfricaColor,
      teamNewZealandColor: teamNewZealandColor ?? this.teamNewZealandColor,
      teamPakistanColor: teamPakistanColor ?? this.teamPakistanColor,
      teamSriLankaColor: teamSriLankaColor ?? this.teamSriLankaColor,
      teamWestIndiesColor: teamWestIndiesColor ?? this.teamWestIndiesColor,
      teamBangladeshColor: teamBangladeshColor ?? this.teamBangladeshColor,
      teamAfghanistanColor: teamAfghanistanColor ?? this.teamAfghanistanColor,
    );
  }
  
  @override
  ThemeExtension<CricketThemeData> lerp(
    covariant ThemeExtension<CricketThemeData>? other,
    double t,
  ) {
    if (other is! CricketThemeData) {
      return this;
    }
    
    return CricketThemeData(
      pitchColor: Color.lerp(pitchColor, other.pitchColor, t)!,
      boundaryColor: Color.lerp(boundaryColor, other.boundaryColor, t)!,
      wicketColor: Color.lerp(wicketColor, other.wicketColor, t)!,
      liveMatchColor: Color.lerp(liveMatchColor, other.liveMatchColor, t)!,
      scheduledMatchColor: Color.lerp(scheduledMatchColor, other.scheduledMatchColor, t)!,
      completedMatchColor: Color.lerp(completedMatchColor, other.completedMatchColor, t)!,
      cancelledMatchColor: Color.lerp(cancelledMatchColor, other.cancelledMatchColor, t)!,
      teamIndiaColor: Color.lerp(teamIndiaColor, other.teamIndiaColor, t)!,
      teamAustraliaColor: Color.lerp(teamAustraliaColor, other.teamAustraliaColor, t)!,
      teamEnglandColor: Color.lerp(teamEnglandColor, other.teamEnglandColor, t)!,
      teamSouthAfricaColor: Color.lerp(teamSouthAfricaColor, other.teamSouthAfricaColor, t)!,
      teamNewZealandColor: Color.lerp(teamNewZealandColor, other.teamNewZealandColor, t)!,
      teamPakistanColor: Color.lerp(teamPakistanColor, other.teamPakistanColor, t)!,
      teamSriLankaColor: Color.lerp(teamSriLankaColor, other.teamSriLankaColor, t)!,
      teamWestIndiesColor: Color.lerp(teamWestIndiesColor, other.teamWestIndiesColor, t)!,
      teamBangladeshColor: Color.lerp(teamBangladeshColor, other.teamBangladeshColor, t)!,
      teamAfghanistanColor: Color.lerp(teamAfghanistanColor, other.teamAfghanistanColor, t)!,
    );
  }
  
  // Light theme instance
  static const light = CricketThemeData(
    pitchColor: ThemeColors.pitch,
    boundaryColor: ThemeColors.boundary,
    wicketColor: ThemeColors.wicket,
    liveMatchColor: AppColors.live,
    scheduledMatchColor: AppColors.scheduled,
    completedMatchColor: AppColors.completed,
    cancelledMatchColor: AppColors.cancelled,
    teamIndiaColor: AppColors.teamIndia,
    teamAustraliaColor: AppColors.teamAustralia,
    teamEnglandColor: AppColors.teamEngland,
    teamSouthAfricaColor: AppColors.teamSouthAfrica,
    teamNewZealandColor: AppColors.teamNewZealand,
    teamPakistanColor: AppColors.teamPakistan,
    teamSriLankaColor: AppColors.teamSriLanka,
    teamWestIndiesColor: AppColors.teamWestIndies,
    teamBangladeshColor: AppColors.teamBangladesh,
    teamAfghanistanColor: AppColors.teamAfghanistan,
  );
  
  // Dark theme instance
  static const dark = CricketThemeData(
    pitchColor: Color(0xFFA1887F),
    boundaryColor: Color(0xFF81C784),
    wicketColor: Color(0xFFBCAAA4),
    liveMatchColor: Color(0xFFEF5350),
    scheduledMatchColor: Color(0xFF757575),
    completedMatchColor: Color(0xFF66BB6A),
    cancelledMatchColor: Color(0xFFFFA726),
    teamIndiaColor: Color(0xFF42A5F5),
    teamAustraliaColor: Color(0xFFFFD54F),
    teamEnglandColor: Color(0xFFEF5350),
    teamSouthAfricaColor: Color(0xFF66BB6A),
    teamNewZealandColor: Color(0xFF9E9E9E),
    teamPakistanColor: Color(0xFF2E7D32),
    teamSriLankaColor: Color(0xFF42A5F5),
    teamWestIndiesColor: Color(0xFF8D6E63),
    teamBangladeshColor: Color(0xFF2E7D32),
    teamAfghanistanColor: Color(0xFFEF5350),
  );
}

// ==================== RESPONSIVE UTILITIES ====================
class ResponsiveUtils {
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return baseSize * 1.2;
    } else if (screenWidth < 600) {
      return baseSize * 0.9;
    }
    return baseSize;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else if (screenWidth < 600) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }
  
  static double getResponsiveRadius(BuildContext context, double baseRadius) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return baseRadius * 1.2;
    } else if (screenWidth < 600) {
      return baseRadius * 0.8;
    }
    return baseRadius;
  }
  
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 600;
      
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1200;
      
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= 1200;
}

// ==================== SHADOWS ====================
class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.07),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get cardDark => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

// ==================== DECORATIONS ====================
class AppDecorations {
  static BoxDecoration card({
    Color? color,
    double radius = 12,
    List<BoxShadow>? shadows,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardBackground,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows ?? AppShadows.card,
    );
  }
  
  static BoxDecoration cardDark({
    Color? color,
    double radius = 12,
    List<BoxShadow>? shadows,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardBackgroundDark,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows ?? AppShadows.cardDark,
    );
  }
  
  static BoxDecoration matchStatus({
    required Color color,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    );
  }
  
  static BoxDecoration circular({
    Color? color,
    double size = 40,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.primary.withOpacity(0.1),
      shape: BoxShape.circle,
    );
  }
}

// ==================== MAIN THEME ====================
class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.standard,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: AppColors.secondaryLight,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.success,
        onTertiary: AppColors.textOnPrimary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.cardBackground,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.divider,
        outlineVariant: AppColors.divider,
        shadow: Colors.black,
        scrim: Colors.black54,
        inverseSurface: AppColors.surfaceDark,
        onInverseSurface: AppColors.textOnPrimary,
        inversePrimary: AppColors.primaryLight,
        surfaceTint: AppColors.primary,
      ),
      
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(),
        displayMedium: AppTextStyles.displayMedium(),
        displaySmall: AppTextStyles.displaySmall(),
        headlineLarge: AppTextStyles.headlineLarge(),
        headlineMedium: AppTextStyles.headlineMedium(),
        headlineSmall: AppTextStyles.headlineSmall(),
        titleLarge: AppTextStyles.titleLarge(),
        titleMedium: AppTextStyles.titleMedium(),
        titleSmall: AppTextStyles.titleSmall(),
        bodyLarge: AppTextStyles.bodyLarge(),
        bodyMedium: AppTextStyles.bodyMedium(),
        bodySmall: AppTextStyles.bodySmall(),
        labelLarge: AppTextStyles.labelLarge(),
        labelMedium: AppTextStyles.labelMedium(),
        labelSmall: AppTextStyles.labelSmall(),
      ),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.surface,
        shadowColor: Colors.black.withOpacity(0.06),
        titleTextStyle: AppTextStyles.titleLarge(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
      
     cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBackground,
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        clipBehavior: Clip.antiAlias,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.textDisabled,
          disabledForegroundColor: AppColors.textHint,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.labelLarge(color: AppColors.textOnPrimary),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          disabledForegroundColor: AppColors.textDisabled,
          // disabledSide: const BorderSide(color: AppColors.textDisabled),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.labelLarge(color: AppColors.primary),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: AppTextStyles.labelLarge(),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.textDisabled),
        ),
        labelStyle: AppTextStyles.bodyMedium(),
        hintStyle: AppTextStyles.bodyMedium(color: AppColors.textHint),
        errorStyle: AppTextStyles.bodySmall(color: AppColors.error),
        helperStyle: AppTextStyles.bodySmall(),
        counterStyle: AppTextStyles.bodySmall(),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedIconTheme: IconThemeData(size: 22),
        unselectedIconTheme: IconThemeData(size: 22),
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.15),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.15),
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),

      listTileTheme: const ListTileThemeData(
        minLeadingWidth: 32,
        horizontalTitleGap: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.textDisabled,
        labelStyle: AppTextStyles.labelMedium(),
        secondaryLabelStyle: AppTextStyles.labelMedium(),
        brightness: Brightness.light,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium(color: AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: AppTextStyles.headlineMedium(),
        contentTextStyle: AppTextStyles.bodyMedium(),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 6,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.labelLarge(),
        unselectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.textSecondary),
      ),
      
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.bodyMedium(),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textHint;
        }),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surface;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.textHint;
        }),
      ),
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.textDisabled,
        linearTrackColor: AppColors.textDisabled,
      ),
      
      extensions: const [
        CricketThemeData.light,
      ],
    );
  }
  
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.primary.withOpacity(0.9),
      visualDensity: VisualDensity.standard,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: Color(0xFF1E3A5F),
        onPrimaryContainer: AppColors.textPrimaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: Color(0xFF663C00),
        onSecondaryContainer: AppColors.textPrimaryDark,
        tertiary: AppColors.success,
        onTertiary: AppColors.textOnPrimary,
        error: Color(0xFFEF5350),
        onError: AppColors.textOnPrimary,
        errorContainer: Color(0xFF621B1B),
        onErrorContainer: Color(0xFFEF5350),
        surface: Color(0xFF1E1E1E),
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: Color(0xFF2C2C2C),
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: Color(0xFF6B6B6B),
        outlineVariant: Color(0xFF424242),
        shadow: Colors.black,
        scrim: Colors.black87,
        inverseSurface: AppColors.surface,
        onInverseSurface: AppColors.textPrimary,
        inversePrimary: AppColors.primaryLight,
        surfaceTint: AppColors.primary,
      ),
      
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(color: AppColors.textPrimaryDark),
        displayMedium: AppTextStyles.displayMedium(color: AppColors.textPrimaryDark),
        displaySmall: AppTextStyles.displaySmall(color: AppColors.textPrimaryDark),
        headlineLarge: AppTextStyles.headlineLarge(color: AppColors.textPrimaryDark),
        headlineMedium: AppTextStyles.headlineMedium(color: AppColors.textPrimaryDark),
        headlineSmall: AppTextStyles.headlineSmall(color: AppColors.textPrimaryDark),
        titleLarge: AppTextStyles.titleLarge(color: AppColors.textPrimaryDark),
        titleMedium: AppTextStyles.titleMedium(color: AppColors.textPrimaryDark),
        titleSmall: AppTextStyles.titleSmall(color: AppColors.textPrimaryDark),
        bodyLarge: AppTextStyles.bodyLarge(color: AppColors.textPrimaryDark),
        bodyMedium: AppTextStyles.bodyMedium(color: AppColors.textSecondaryDark),
        bodySmall: AppTextStyles.bodySmall(color: AppColors.textSecondaryDark),
        labelLarge: AppTextStyles.labelLarge(color: AppColors.textPrimaryDark),
        labelMedium: AppTextStyles.labelMedium(color: AppColors.textSecondaryDark),
        labelSmall: AppTextStyles.labelSmall(color: AppColors.textHintDark),
      ),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        titleTextStyle: AppTextStyles.titleLarge(color: Colors.white),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 2,
        color: AppColors.cardBackgroundDark,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: const Color(0xFF424242),
          disabledForegroundColor: AppColors.textHintDark,
          elevation: 2,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.labelLarge(color: AppColors.textOnPrimary),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          disabledForegroundColor: AppColors.textHintDark,
          // disabledSide: const BorderSide(color: Color(0xFF424242)),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.labelLarge(color: AppColors.primary),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textHintDark,
          textStyle: AppTextStyles.labelLarge(),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6B6B6B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6B6B6B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        labelStyle: AppTextStyles.bodyMedium(color: AppColors.textSecondaryDark),
        hintStyle: AppTextStyles.bodyMedium(color: AppColors.textHintDark),
        errorStyle: AppTextStyles.bodySmall(color: const Color(0xFFEF5350)),
        helperStyle: AppTextStyles.bodySmall(color: AppColors.textSecondaryDark),
        counterStyle: AppTextStyles.bodySmall(color: AppColors.textSecondaryDark),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF6B6B6B),
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 24),
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.15),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.15),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      listTileTheme: const ListTileThemeData(
        minLeadingWidth: 32,
        horizontalTitleGap: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedColor: AppColors.primary,
        disabledColor: const Color(0xFF424242),
        labelStyle: AppTextStyles.labelMedium(color: AppColors.textPrimaryDark),
        secondaryLabelStyle: AppTextStyles.labelMedium(color: AppColors.textSecondaryDark),
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        contentTextStyle: AppTextStyles.bodyMedium(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        titleTextStyle: AppTextStyles.headlineMedium(color: Colors.white),
        contentTextStyle: AppTextStyles.bodyMedium(color: AppColors.textSecondaryDark),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 8,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondaryDark,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.labelLarge(color: Colors.white),
        unselectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.textSecondaryDark),
      ),
      
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF2C2C2C),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.bodyMedium(color: Colors.white),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textHintDark;
        }),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return const Color(0xFF6B6B6B);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryLight.withOpacity(0.5);
          }
          return const Color(0xFF424242);
        }),
      ),
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: Color(0xFF424242),
        linearTrackColor: Color(0xFF424242),
      ),
      
      extensions: const [
        CricketThemeData.dark,
      ],
    );
  }
}

// ==================== THEME HELPER ====================
class ThemeHelper {
  static CricketThemeData cricketTheme(BuildContext context) {
    return Theme.of(context).extension<CricketThemeData>() ?? CricketThemeData.light;
  }
  
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  static Color adaptiveColor({
    required BuildContext context,
    required Color light,
    required Color dark,
  }) {
    return isDarkMode(context) ? dark : light;
  }
  
  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }
  
  static TextTheme textTheme(BuildContext context) {
    return Theme.of(context).textTheme;
  }
  
  static EdgeInsets get screenPadding => const EdgeInsets.all(16);
  
  static EdgeInsets get cardPadding => const EdgeInsets.all(12);
  
  static EdgeInsets get itemPadding => const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  
  static double get cardElevation => 2;
  
  static double get buttonHeight => 48;
  
  static double get inputHeight => 56;
  
  static double get iconSizeSmall => 16;
  
  static double get iconSizeMedium => 20;
  
  static double get iconSizeLarge => 24;
}


