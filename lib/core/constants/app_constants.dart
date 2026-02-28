class AppConstants {
  // App Info
  static const String appName = 'Cric11';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  static const String themeKey = 'theme';
  static const String onboardingKey = 'onboarding';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int defaultPage = 1;
  
  // Match Formats
  static const String formatT20 = 'T20';
  static const String formatODI = 'ODI';
  static const String formatTest = 'TEST';
  static const String formatT10 = 'T10';
  
  // Match Types
  static const String typeLeague = 'LEAGUE';
  static const String typeKnockout = 'KNOCKOUT';
  static const String typeFinal = 'FINAL';
  static const String typeSemiFinal = 'SEMI_FINAL';
  static const String typeQuarterFinal = 'QUARTER_FINAL';
  
  // Match Status
  static const String statusScheduled = 'SCHEDULED';
  static const String statusLive = 'LIVE';
  static const String statusCompleted = 'COMPLETED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusAbandoned = 'ABANDONED';
  static const String statusNoResult = 'NO_RESULT';
  
  // Roles
  static const String roleAdmin = 'ADMIN';
  static const String roleUser = 'USER';
  static const String roleOrganizer = 'ORGANIZER';
  static const String roleCaptain = 'CAPTAIN';
  static const String rolePlayer = 'PLAYER';
  static const String roleUmpire = 'UMPIRE';
  static const String roleScorer = 'SCORER';
  
  // Player Roles
  static const String playerRoleBatsman = 'BATSMAN';
  static const String playerRoleBowler = 'BOWLER';
  static const String playerRoleAllRounder = 'ALL_ROUNDER';
  static const String playerRoleWicketKeeper = 'WICKET_KEEPER';
  
  // Tournament Status
  static const String tournamentUpcoming = 'UPCOMING';
  static const String tournamentLive = 'LIVE';
  static const String tournamentCompleted = 'COMPLETED';
  static const String tournamentCancelled = 'CANCELLED';
  
  // Socket Events
  static const String socketConnect = 'connect';
  static const String socketDisconnect = 'disconnect';
  static const String socketMatchUpdate = 'match_update';
  static const String socketScoreUpdate = 'score_update';
  static const String socketNotification = 'notification';
}
