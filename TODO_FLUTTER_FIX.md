# Flutter Build Errors Fix Plan

## Priority 1: Critical Errors (Block Build)
- [ ] 1. theme_config.dart - DialogTheme → DialogThemeData, TabBarTheme → TabBarThemeData
- [ ] 2. main.dart - OTPVerificationScreen missing required parameters
- [ ] 3. auth_service.dart - User → UserModel
- [ ] 4. user_service.dart - AuthService.getToken() fix

## Priority 2: Model Errors
- [ ] 5. tournament_model.dart - Missing fields (bannerUrl, registeredTeams, maxTeams)
- [ ] 6. team_model.dart - Add missing fields (teamType, captainName, etc.)
- [ ] 7. player_model.dart - Missing fields (profileImage, teamName)

## Priority 3: Screen Errors
- [ ] 8. team_detail_screen.dart - Missing fields and CustomAppbar usage
- [ ] 9. tournament_detail_screen.dart - Missing 'city' parameter
- [ ] 10. Various screens with type casting issues

## Priority 4: Service Errors
- [ ] 11. match_service.dart - toJson method issues
- [ ] 12. store_service.dart - Dio API call fixes
- [ ] 13. community_service.dart - Dio API call fixes
- [ ] 14. team_service.dart - uploadFile signature fix

