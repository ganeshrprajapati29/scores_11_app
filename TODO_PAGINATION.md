# Pagination Implementation TODO

## Task
Implement pagination algorithm for all list screens in the Flutter app (cric11_app)

## Algorithm (as per requirement)
```dart
int page = 1;

loadMore(){
  page++;
  fetchMatches(page);
}
```

## Files to Update

### 1. Services - Add Pagination Support

- [x] 1.1 `lib/data/services/match_service.dart` - Return pagination metadata ✅
- [x] 1.2 `lib/data/services/tournament_service.dart` - Return pagination metadata ✅
- [x] 1.3 `lib/data/services/team_service.dart` - Return pagination metadata ✅
- [x] 1.4 `lib/data/services/player_service.dart` - Return pagination metadata ✅
- [x] 1.5 `lib/data/services/club_service.dart` - Return pagination metadata ✅
- [x] 1.6 `lib/data/services/community_service.dart` - Return pagination metadata ✅
- [x] 1.7 `lib/data/services/store_service.dart` - Return pagination metadata ✅
- [x] 1.8 `lib/data/services/leaderboard_service.dart` - Return pagination metadata ✅

### 2. Screens - Implement loadMore()

- [x] 2.1 `lib/features/matches/match_list_screen.dart` - Add pagination ✅
- [x] 2.2 `lib/features/teams/team_list_screen.dart` - Add pagination ✅
- [x] 2.3 `lib/features/tournaments/tournament_list_screen.dart` - Add pagination ✅
- [x] 2.4 `lib/features/players/player_search_screen.dart` - Add pagination ✅
- [x] 2.5 `lib/features/community/community_feed_screen.dart` - Add pagination ✅
- [x] 2.6 `lib/features/leaderboard/top_batsman_screen.dart` - Add pagination ✅
- [x] 2.7 `lib/features/store/store_home_screen.dart` - Add pagination ✅

## Implementation Pattern

Each service should return:
```dart
class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;
}
```

Each screen should have:
```dart
int _currentPage = 1;
bool _hasMore = true;
bool _isLoadingMore = false;

Future<void> loadMore() async {
  if (_isLoadingMore || !_hasMore) return;
  
  setState(() => _isLoadingMore = true);
  _currentPage++;
  
  try {
    final response = await _service.getItems(page: _currentPage);
    setState(() {
      _items.addAll(response.data);
      _hasMore = response.hasMore;
      _isLoadingMore = false;
    });
  } catch (e) {
    setState(() => _isLoadingMore = false);
  }
}
```

## Progress - ALL COMPLETE ✅

### Step 1: Update Services (8 files) - COMPLETE ✅
- [x] match_service.dart - PaginatedMatches class
- [x] tournament_service.dart - PaginatedTournaments class
- [x] team_service.dart - PaginatedTeams class
- [x] player_service.dart - PaginatedPlayers class
- [x] club_service.dart - PaginatedClubs class
- [x] community_service.dart - PaginatedPosts class
- [x] store_service.dart - PaginatedProducts class
- [x] leaderboard_service.dart - PaginatedLeaderboard class

### Step 2: Update Screens (7 files) - COMPLETE ✅
- [x] match_list_screen.dart - Full pagination with tabs
- [x] team_list_screen.dart - Full pagination
- [x] tournament_list_screen.dart - Full pagination with tabs
- [x] player_search_screen.dart - Full pagination with search
- [x] community_feed_screen.dart - Full pagination with tabs
- [x] top_batsman_screen.dart - Full pagination
- [x] store_home_screen.dart - Full pagination with categories

## Summary

All pagination implementations are complete! Each screen now supports:
- Page 1 → 20 items
- Page 2 → 20 items
- Auto-loading when scrolling near bottom
- Loading indicator during fetch
- Error handling with page rollback
- hasMore flag to prevent unnecessary requests
- isLoadingMore flag to prevent duplicate requests
