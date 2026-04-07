# Player Navigation &amp; Name Fix TODO

Status: In Progress ✅ Step 1 Complete

## Steps:

1. ✅ Update `lib/data/models/player_model.dart` - Fixed name mapping (playerName → name, team names)
2. ✅ Update `lib/main.dart` - Added onGenerateRoute for dynamic player-profile/:id routes
3. ☐ Test: 
   - cd cric11_app &amp;&amp; flutter pub get
   - flutter run
   - Navigate to Players → check names display properly
   - Tap any player → profile opens without navigation error
4. ✅ Complete

**Next:** Edit main.dart
