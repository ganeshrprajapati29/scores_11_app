# Flutter Compilation Error Fix Plan

## Current Status
✅ TournamentService.dart - Fixed (missing params, DioException handling)  
✅ TournamentModel.dart - Has timestamps (createdAt/updatedAt)

## Priority 1: Blocking Compilation Errors (Next)
1. **lib/data/services/player_service.dart** 
   - Line ~92: `_apiClient.parseDioError(e)` - parseDioError not exist
2. **lib/features/auth/login_screen_backup.dart** 
   - Corrupted HTML entities (&nbsp; → space), incomplete
3. **test/widget_test.dart** 
   - Missing imports/class definitions

## Priority 2: Runtime Dio Error Handling (All Services)
Add `String parseDioError(Object e)` to `lib/core/services/api_client.dart`:
```
String parseDioError(Object e) {
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionTimeout) return 'Connection timeout';
    if (e.response?.data['message'] != null) return e.response!.data['message'];
    return e.message ?? 'Network error';
  }
  return e.toString();
}
```

## Priority 3: Lint Warnings (784 total)
- withOpacity → withOpacity()  
- print → logger.log  
- Unused imports

## Plan Execution Order
1. Fix api_client.dart with parseDioError method  
2. Fix player_service.dart error handling  
3. Clean login_screen_backup.dart  
4. Run `flutter analyze` verify 0 errors  
5. `flutter run` test

**Approved to proceed?**
