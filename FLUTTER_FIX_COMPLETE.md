# Flutter Build Errors Fix Plan

## Priority 1 - Critical Errors (Blocking Build)

### 1. theme_config.dart - TabBarTheme
- Change `TabBarTheme(` to `TabBarThemeData(` at lines 892 and 1176

### 2. tournament_model.dart - Missing fields and List<String> casting
- Add bannerUrl, registeredTeams, maxTeams to constructor
- Fix List<String> casting for teams and matches

### 3. team_model.dart - Missing fields
- Add teamType, matchesPlayed, wins, losses, ties, captainName, viceCaptainName

### 4. custom_button.dart - Add icon parameter
- Add IconData? icon parameter

### 5. user_model.dart - Add cricketProfile
- Add Map<String, dynamic>? cricketProfile field

### 6. match_model.dart - toJson and List<String> casting
- Add toJson method to Match class
- Fix List<String> casting

### 7. player_model.dart - Missing fields
- Add profileImage and teamName fields

### 8. go_live_screen.dart - Missing parenthesis
- Fix line 867 syntax error

## Priority 2 - Service Layer Errors

### 9. user_service.dart - getToken method
- Fix AuthService.getToken() calls

### 10. auth_service.dart - User class reference
- Fix User.fromJson to UserModel.fromJson

### 11. store_service.dart - API method signatures
- Fix get, post, put method calls

### 12. community_service.dart - API method signatures
- Fix get, post method calls

### 13. team_service.dart - uploadFile arguments
- Fix uploadFile method signature

## Priority 3 - Screen Errors

### 14. team_detail_screen.dart
- Fix CustomAppbar usage
- Add missing Team fields

### 15. tournament_detail_screen.dart
- Fix city parameter issue
- Fix type casting

### 16. fixtures_screen.dart, points_table_screen.dart
- Fix type casting

### 17. player_search_screen.dart
- Fix type casting and null safety

### 18. cricket_profile_screen.dart
- Fix cricketProfile access

### 19. match_detail_screen.dart
- Fix type casting

### 20. score_entry_screen.dart
- Fix onChanged callback type

### 21. cart_screen.dart, checkout_screen.dart
- Fix field initializer errors

### 22. Multiple screens - CustomAppbar
- store_home_screen.dart
- orders_screen.dart
- community_feed_screen.dart
- post_detail_screen.dart
- app_settings_screen.dart

