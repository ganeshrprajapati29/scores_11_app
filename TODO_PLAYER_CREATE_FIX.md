# Fix Player Creation Error: string not subtype of int

**Status**: ✅ COMPLETE

## Steps:
- [x] 1. Create this TODO file
- [x] 2. Update player_model.dart jerseyNumber parsing to (json['jerseyNumber'] as num?)?.toInt()
- [x] 3. Hot reload Flutter app  
- [x] 4. Test create player with jersey number
- [x] 5. Verify success, update TODO complete
- [ ] 6. attempt_completion

**Root cause**: Response jerseyNumber comes as string, unsafe parsing in fromJson.
