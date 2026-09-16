import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();
  
  // ==================== PRIMARY COLORS ====================
  static const Color primary = Color(0xFF1657CC);
  static const Color primaryLight = Color(0xFFE8F0FE);
  static const Color primaryDark = Color(0xFF0D2B5E);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1657CC), Color(0xFF0D2B5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ==================== SECONDARY COLORS ====================
  static const Color secondary = Color(0xFF16A34A);
  static const Color secondaryLight = Color(0xFFEAF8EF);
  static const Color secondaryDark = Color(0xFF0F7A36);
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF0F7A36)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ==================== BACKGROUND COLORS ====================
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF2C2C2C);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // ==================== TEXT COLORS ====================
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textHint = Color(0xFF98A2B3);
  static const Color textDisabled = Color(0xFFD0D5DD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textHintDark = Color(0xFF6B6B6B);

  // ==================== STATUS COLORS ====================
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF1657CC);
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ==================== MATCH STATUS COLORS ====================
  static const Color live = Color(0xFFE31E3C);
  static const Color scheduled = Color(0xFF64748B);
  static const Color cancelled = Color(0xFFF59E0B);
  static const Color completed = Color(0xFF16A34A);

  static const LinearGradient liveGradient = LinearGradient(
    colors: [Color(0xFFE31E3C), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ==================== CRICKET SPECIFIC COLORS ====================
  static const Color pitch = Color(0xFF8D6E63);
  static const Color boundary = Color(0xFF4CAF50);
  static const Color wicket = Color(0xFF795548);
  static const Color cricketPitch = Color(0xFF8D6E63);
  static const Color cricketBall = Color(0xFFD32F2F);
  static const Color cricketBat = Color(0xFF5D4037);
  
  // ==================== TEAM COLORS ====================
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
  
  // ==================== IPL TEAM COLORS ====================
  static const Color csk = Color(0xFFFFC107);  // Chennai Super Kings - Yellow
  static const Color mi = Color(0xFF0066B3);   // Mumbai Indians - Blue
  static const Color rcb = Color(0xFFE53935);  // Royal Challengers Bangalore - Red
  static const Color kkr = Color(0xFF3F51B5);  // Kolkata Knight Riders - Purple
  static const Color dc = Color(0xFF1A237E);   // Delhi Capitals - Blue
  static const Color pbks = Color(0xFFE91E63); // Punjab Kings - Red/Pink
  static const Color rr = Color(0xFF0277BD);   // Rajasthan Royals - Blue
  static const Color srh = Color(0xFFFF6F00);  // Sunrisers Hyderabad - Orange
  static const Color lsg = Color(0xFF00BCD4);  // Lucknow Super Giants - Cyan
  static const Color gt = Color(0xFFF57C00);   // Gujarat Titans - Orange
  
  // ==================== MISC COLORS ====================
  static const Color divider = Color(0xFFE4E7EC);
  static const Color shadow = Color(0x0F000000);
  static const Color overlay = Color(0x80000000);
  
  // ==================== HELPER METHODS ====================
  
  /// Get team color by team name
  static Color getTeamColor(String teamName) {
    final name = teamName.toLowerCase();
    
    // IPL Teams
    if (name.contains('mumbai') || name.contains('mi')) return mi;
    if (name.contains('chennai') || name.contains('csk')) return csk;
    if (name.contains('bangalore') || name.contains('rcb')) return rcb;
    if (name.contains('kolkata') || name.contains('kkr')) return kkr;
    if (name.contains('delhi') || name.contains('dc')) return dc;
    if (name.contains('punjab') || name.contains('kings') || name.contains('pbks')) return pbks;
    if (name.contains('rajasthan') || name.contains('rr')) return rr;
    if (name.contains('hyderabad') || name.contains('srh')) return srh;
    if (name.contains('lucknow') || name.contains('lsg')) return lsg;
    if (name.contains('gujarat') || name.contains('gt')) return gt;
    
    // International Teams
    if (name.contains('india')) return teamIndia;
    if (name.contains('australia')) return teamAustralia;
    if (name.contains('england')) return teamEngland;
    if (name.contains('south africa')) return teamSouthAfrica;
    if (name.contains('new zealand')) return teamNewZealand;
    if (name.contains('pakistan')) return teamPakistan;
    if (name.contains('sri lanka')) return teamSriLanka;
    if (name.contains('west indies')) return teamWestIndies;
    if (name.contains('bangladesh')) return teamBangladesh;
    if (name.contains('afghanistan')) return teamAfghanistan;
    
    return primary;
  }
  
  /// Get status color based on match status
  static Color getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('LIVE')) return live;
    if (s.contains('COMPLETED')) return completed;
    if (s.contains('SCHEDULED')) return scheduled;
    if (s.contains('CANCELLED')) return cancelled;
    if (s.contains('IN PROGRESS')) return live;
    if (s.contains('FINISHED')) return completed;
    return textSecondary;
  }
  
  /// Get gradient for status
  static LinearGradient getStatusGradient(String status) {
    final s = status.toUpperCase();
    if (s.contains('LIVE')) return liveGradient;
    if (s.contains('COMPLETED')) return successGradient;
    if (s.contains('SCHEDULED')) return LinearGradient(
      colors: [scheduled, scheduled.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return primaryGradient;
  }
  
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity.clamp(0.0, 1.0));
  }
  
  /// Check if color is dark
  static bool isDark(Color color) {
    final brightness = color.computeLuminance();
    return brightness < 0.5;
  }
  
  /// Get contrast color (black or white) based on background
  static Color getContrastColor(Color backgroundColor) {
    return isDark(backgroundColor) ? Colors.white : Colors.black;
  }
  
  /// Get random color for placeholder
  static Color getRandomColor(int index) {
    final colors = [
      primary, secondary, success, error, warning, info,
      teamIndia, teamAustralia, teamEngland, csk, mi, rcb
    ];
    return colors[index % colors.length];
  }
  
  /// Get lighter version of color
  static Color lighten(Color color, [double amount = 0.2]) {
    final r = color.red + (255 - color.red) * amount;
    final g = color.green + (255 - color.green) * amount;
    final b = color.blue + (255 - color.blue) * amount;
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), 1);
  }
  
  /// Get darker version of color
  static Color darken(Color color, [double amount = 0.2]) {
    final r = color.red * (1 - amount);
    final g = color.green * (1 - amount);
    final b = color.blue * (1 - amount);
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), 1);
  }
}

// Extension for easier color manipulation
extension AppColorsExtension on Color {
  Color get shade100 => withOpacity(0.1);
  Color get shade200 => withOpacity(0.2);
  Color get shade300 => withOpacity(0.3);
  Color get shade400 => withOpacity(0.4);
  Color get shade500 => withOpacity(0.5);
  Color get shade600 => withOpacity(0.6);
  Color get shade700 => withOpacity(0.7);
  Color get shade800 => withOpacity(0.8);
  Color get shade900 => withOpacity(0.9);
  
  Color withOpacity(double opacity) {
    return Color.fromRGBO(red, green, blue, opacity.clamp(0.0, 1.0));
  }
  
  int get red => (this.value >> 16) & 0xFF;
  int get green => (this.value >> 8) & 0xFF;
  int get blue => this.value & 0xFF;
  
  bool get isDark {
    final luminance = computeLuminance();
    return luminance < 0.5;
  }
  
  Color get contrastColor => isDark ? Colors.white : Colors.black;
  
  double computeLuminance() {
    final r = red / 255.0;
    final g = green / 255.0;
    final b = blue / 255.0;
    
    final linearR = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055) * ((r + 0.055) / 1.055);
    final linearG = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055) * ((g + 0.055) / 1.055);
    final linearB = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055) * ((b + 0.055) / 1.055);
    
    return 0.2126 * linearR + 0.7152 * linearG + 0.0722 * linearB;
  }
  
  Color lighten([double amount = 0.2]) {
    final r = red + (255 - red) * amount;
    final g = green + (255 - green) * amount;
    final b = blue + (255 - blue) * amount;
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), 1);
  }
  
  Color darken([double amount = 0.2]) {
    final r = red * (1 - amount);
    final g = green * (1 - amount);
    final b = blue * (1 - amount);
    return Color.fromRGBO(r.toInt(), g.toInt(), b.toInt(), 1);
  }
}
