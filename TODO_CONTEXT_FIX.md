r# Context Error Fix Plan
## Steps:
- [ ] 1. Create TODO file ✅
- [x] 2. Apply edit 1: Wrap first TextButton with Builder ✅
- [x] 3. Apply edit 2: Wrap second TextButton.icon with Builder ✅
- [ ] 4. Run `flutter analyze` to verify
- [ ] 5. Hot reload/test navigation
- [ ] 6. Mark complete & attempt_completion

**File:** cric11_app/lib/features/dashboard/dashboard_screen.dart
**Fix:** Add Builder widgets around Navigator buttons in HomeTab._buildLiveMatchesSection
