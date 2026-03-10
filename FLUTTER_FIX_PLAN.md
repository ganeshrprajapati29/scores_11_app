# Flutter App Fix Plan

## Summary of Errors

The Flutter build has multiple errors that need to be fixed. Here's the comprehensive plan:

### 1. Missing Packages (pubspec.yaml)
- Add `equatable: ^2.0.5`
- Add `qr_flutter: ^4.1.0`
- Add `share_plus: ^7.2.1`

### 2. app_colors.dart - Fix primaryGradient type
- Change `primaryGradient` from `List<Color>` to proper gradient type or use `LinearGradient`

### 3. match_model.dart - Duplicate MatchScore class
- Remove duplicate MatchScore factory constructor (lines 301 and 310)

### 4. custom_textfield.dart - Add missing parameters
- Add `labelText` parameter
- Add `hintText` parameter

### 5. custom_appbar.dart - Add missing parameters
- Add `bottom` parameter for TabBar support

### 6. custom_button.dart - Add missing parameters
- Add `label` parameter

### 7. auth_service.dart - Add getToken static method
- Add static method `getToken()` to work with user_service.dart

### 8. api_client.dart - Fix uploadFile signature
- Fix method signature to match team_service.dart calls

### 9. tournament_model.dart - Add missing fields
- Add `city` field
- Add `bannerUrl` getter
- Add `registeredTeams` field
- Add `maxTeams` field

### 10. team_model.dart - Add missing fields
- Add `teamType` field
- Add `matchesPlayed`, `wins`, `losses`, `ties` to TeamStats
- Add `captainName`, `viceCaptainName` getters

### 11. player_model.dart - Add missing fields
- Add `profileImage` field
- Add `teamName` field
- Add `role` field (already exists, check)

### 12. theme_config.dart - Fix deprecated parameters
- Replace `disabledSide` with proper parameter
- Replace `CardTheme` with `CardThemeData`
- Replace `DialogTheme` with `DialogThemeData`
- Replace `TabBarTheme` with `TabBarThemeData`

### 13. profile_screen.dart - Fix imports
- Remove qr_flutter import or keep it (package needs to be added)
- Fix AppColors conflicts

### 14. home_screen.dart - Fix Icons.club
- Replace with proper icon

### 15. Various screens - Fix type casts
- Fix Object? to String casts
- Fix dynamic map accesses

---

## Implementation Order

1. Fix pubspec.yaml - Add missing packages
2. Fix app_colors.dart - Gradient type
3. Fix match_model.dart - Remove duplicate
4. Fix custom_textfield.dart - Add parameters
5. Fix custom_appbar.dart - Add parameters
6. Fix custom_button.dart - Add parameters
7. Fix auth_service.dart - Add static method
8. Fix api_client.dart - Fix method signature
9. Fix tournament_model.dart - Add fields
10. Fix team_model.dart - Add fields
11. Fix player_model.dart - Add fields
12. Fix theme_config.dart - Fix deprecated
13. Fix profile_screen.dart - Fix imports
14. Fix home_screen.dart - Fix icon
15. Fix team_detail_screen.dart - Add fields to Team
16. Fix player_search_screen.dart - Add fields to Player
17. Fix other screens with type casts

