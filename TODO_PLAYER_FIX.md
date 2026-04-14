# Fix Player Creation: "string is not subtype of type int"

**Status**: ⏳ In Progress

## Steps from Approved Plan:

- [x] 1. Update player_model.dart: Safe parse ALL numeric fields in Player.fromJson (jerseyNumber already safe, ensure team safe).
- [x] 2. Update PlayerStats.fromJson: ALL int fields use (json['field'] as num?)?.toInt() ?? 0 instead of json['field'] ?? 0 to handle potential string numbers from backend response.
- [ ] 3. Hot reload Flutter app (r in terminal or flutter run).
- [ ] 4. Test player creation with jersey number input.
- [ ] 5. Verify no type error, success snackbar shows.
- [ ] 6. Update this TODO with [x] marks.
- [ ] 7. attempt_completion

**Root Cause**: Backend response numeric fields (stats.matches etc.) arrive as strings; unsafe assignment to int params causes runtime subtype error.

**Files**: player_model.dart

**Next**: Step 1-2 edits.

