# Flutter Build Fix TODO
## Current Progress: 0/7 ✅

### Step 1: Fix CustomLoader const errors [✅]
- [✅] Remove `const` from security_screen.dart
- [✅] Remove `const` from preferences_screen.dart  
- [✅] Remove `const` from privacy_settings_screen.dart
- [✅] Remove `const` from notification_settings_screen.dart

**Progress: 3/7**

### Step 2: Fix ButtonVariant import [✅]
- [✅] Add import to team_detail_screen.dart

### Step 3: Fix dashboard gradient errors [✅]
- [✅] Added app_colors.dart import to dashboard_screen.dart (fixes AppColors.primaryGradient reference)

### Step 4: Flutter clean & dependencies [ ]

### Step 3: Fix dashboard gradient errors [ ]
- [ ] Update dashboard_screen.dart gradient usages

### Step 4: Flutter clean & dependencies [✅]
```
cd cric11_app
flutter clean
flutter pub get  
flutter pub upgrade
```
**Completed successfully - 43 outdated packages noted (non-blocking)**

**Progress: 4/7**

### Step 5: Test build [ ]
```
flutter build apk --debug
```

### Step 6: Fix auth runtime error [ ]
- [ ] Check user_model.dart profile handling
- [ ] Test notification fetch

### Step 7: Final verification [ ]
- [ ] ✅ All compilation errors fixed
- [ ] ✅ App builds successfully
- [ ] ✅ Runtime auth working

**Next step: 1/7**

