# Flutter Build Errors Fix Plan

## Issue 1: CustomAppBar missing showBackButton parameter

### Error:
```
lib/features/wallet/wallet_screen.dart:55:9: Error: No named parameter with the name 'showBackButton'.
        showBackButton: true,
lib/features/subscription/subscription_screen.dart:80:9: Error: No named parameter with the name 'showBackButton'.
        showBackButton: true,
lib/features/notifications/notifications_screen.dart:74:15: Error: The method 'CustomAppbar' isn't defined
```

### Fix Required:
1. Add `showBackButton` parameter to `CustomAppBar` in `custom_appbar.dart`
2. Fix typo: `CustomAppbar` → `CustomAppBar` in `notifications_screen.dart`
3. Add back button logic in CustomAppBar based on showBackButton value

---

## Issue 2: GoogleMap onMarkerTap parameter

### Error:
```
lib/features/discovery/discovery_screen.dart:849:7: Error: No named parameter with the name 'onMarkerTap'.
```

### Fix Required:
- Remove `onMarkerTap` from GoogleMap widget - markers already have onTap defined in the Marker definition

---

## Issue 3: SubscriptionService Response handling

### Error:
```
lib/data/services/subscription_service.dart:8:40: Error: The operator '[]' isn't defined for the type 'Response<dynamic>'.
lib/data/services/subscription_service.dart:14:20: Error: The operator '[]' isn't defined for the type 'Response<dynamic>'.
lib/data/services/subscription_service.dart:19:20: Error: The operator '[]' isn't defined for the type 'Response<dynamic>'.
lib/data/services/subscription_service.dart:23:43: Error: Too many positional arguments: 1 allowed, but 2 found.
lib/data/services/subscription_service.dart:39:73: Error: No named parameter with the name 'queryParams'.
```

### Fix Required:
- Use `response.data['data']` instead of `response['data']` since Response objects have `.data` property
- Fix API calls to use correct parameter names (`queryParameters` not `queryParams`)
- Remove extra positional argument from post call

---

## Files to Modify:

1. `cric11_app/lib/core/widgets/custom_appbar.dart` - Add showBackButton parameter
2. `cric11_app/lib/features/wallet/wallet_screen.dart` - Already uses correct API (will work after CustomAppBar fix)
3. `cric11_app/lib/features/subscription/subscription_screen.dart` - Already uses correct API (will work after CustomAppBar fix)
4. `cric11_app/lib/features/notifications/notifications_screen.dart` - Fix CustomAppbar typo
5. `cric11_app/lib/features/discovery/discovery_screen.dart` - Remove onMarkerTap from GoogleMap
6. `cric11_app/lib/data/services/subscription_service.dart` - Fix Response handling

