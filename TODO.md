# Live Score Carousel - Flutter Dashboard
Status: ✅ Plan approved, proceeding with implementation

## Implementation Steps
1. [x] Create TODO.md ✓
2. [ ] Add LiveScoreCarousel StatefulWidget in dashboard_screen.dart 
3. [ ] Replace _buildLiveMatchesSection ListView with carousel
4. [ ] Add View All button
5. [ ] Test: cd cric11_app &amp;&amp; flutter run
6. [ ] Mark complete ✓

**Files**: lib/features/dashboard/dashboard_screen.dart

**Pattern**: Copy _BannerCarousel structure (PageView + Timer + dots)
**Data**: dashboardProvider.liveMatches
**Features**: Auto-scroll 4s, tap navigation, responsive dots
