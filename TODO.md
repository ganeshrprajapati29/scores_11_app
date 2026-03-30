# Crick11 Flutter App Fix TODO
## Status: Plan Approved ✅ - Fixing Build & Notification Errors

### Current Task: Fix Flutter Build Errors (Blogs Type + User ID in Notifications)

**Steps:**
- [x] 1. Create TODO.md ✅
- [x] 2. Edit core/services/user_service.dart - Add userId fallback ✅
- [x] 3. Edit providers/auth_provider.dart - Save user data to shared prefs after login ✅
- [x] 4. Edit data/services/notification_service.dart - Safe unread count with ID check
- [ ] 5. Run `flutter clean && flutter pub get`
- [ ] 6. Test `flutter run --debug`
- [ ] 7. Update TODOs & complete

**Plan Details:**
- Blogs_screen.dart already fixed (safe parsing)
- Fix notification user ID missing post-login

