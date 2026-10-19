import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../data/models/dashboard_model.dart';
import '../data/services/dashboard_service.dart';
import '../data/services/match_service.dart';
import '../data/models/match_model.dart';
import '../core/services/api_client.dart';
import '../core/config/api_config.dart';
import 'dart:developer';
import '../data/services/blog_service.dart';
import '../data/services/community_service.dart';
import '../data/models/blog_model.dart';
import '../data/models/tournament_model.dart'; // Add this line at top

class DashboardProvider extends ChangeNotifier {
  DashboardData? _dashboardData;
  bool _isLoading = false;
  bool _isMockData = false;
  String? _error;

  // Getters
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  bool get isMockData => _isMockData;
  String? get error => _error;

  // Convenience getters for different sections
  List<LiveMatch> get liveMatches => (_dashboardData?.liveMatches ?? [])
      .where((match) => match.isActuallyLive)
      .toList();
  List<UpcomingMatch> get upcomingMatches =>
      _dashboardData?.upcomingMatches ?? [];
  List<TrendingPlayer> get trendingPlayers =>
      _dashboardData?.trendingPlayers ?? [];
  List<Tournament> get latestTournaments =>
      _dashboardData?.latestTournaments ?? [];
  QuickStats get quickStats =>
      _dashboardData?.quickStats ??
      const QuickStats(
        totalMatches: 0,
        totalTournaments: 0,
        totalTeams: 0,
        totalPlayers: 0,
        todayMatches: 0,
        weekMatches: 0,
        activeTournaments: 0,
        liveMatches: 0,
      );

  List<BlogModel> get recentBlogs => _recentBlogs;
  List<Map<String, dynamic>> get recentPosts => _recentPosts;
  bool get hasRecentBlogs => recentBlogs.isNotEmpty;
  bool get hasRecentPosts => recentPosts.isNotEmpty;

  final DashboardService _dashboardService = DashboardService();
  final MatchService _matchService = MatchService();
  final BlogService _blogService = BlogService();
  final CommunityService _communityService = CommunityService();
  List<BlogModel> _recentBlogs = [];
  List<Map<String, dynamic>> _recentPosts = [];
  List<Match> _carouselLiveMatches = [];
  List<Match> _recentCompletedMatches = [];

  List<Match> get carouselLiveMatches => _carouselLiveMatches;
  List<Match> get recentCompletedMatches => _recentCompletedMatches;
  bool get hasDashboardCarouselMatches =>
      _carouselLiveMatches.isNotEmpty || _recentCompletedMatches.isNotEmpty;

  /// Clears cached dashboard data on logout so a different account signing
  /// in on the same app instance doesn't briefly see the previous user's data.
  void reset() {
    _dashboardData = null;
    _isLoading = false;
    _isMockData = false;
    _error = null;
    _recentBlogs = [];
    _recentPosts = [];
    _carouselLiveMatches = [];
    _recentCompletedMatches = [];
    notifyListeners();
  }

  /// Load dashboard data (main method)
  Future<void> loadDashboard() async {
    await fetchDashboardData();
  }

  /// Refresh dashboard data (pull to refresh)
  Future<void> refreshDashboard([BuildContext? context]) async {
    await fetchDashboardData();
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// Fetch dashboard data from API.
  /// [silent] skips the loading-overlay flag - used for background polling
  /// (e.g. catching a match that just completed) where a full-screen
  /// spinner popping up unprompted would be a jarring UX regression.
  Future<void> fetchDashboardData({bool silent = false}) async {
    if (!silent) _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔄 Loading dashboard (with retry + fallback)...');

      // Service now handles retry + returns safe empty data
      _dashboardData = await _dashboardService.getDashboardOverview();

      // Load recent blogs & community posts for dashboard
      await _loadDashboardCarouselMatches();
      _recentBlogs = await _blogService.getBlogs(page: 1, limit: 5);
      _recentPosts = await _communityService.getPostsList(page: 1, limit: 5);
      debugPrint(
          '📚 Recent content: ${_recentBlogs.length} blogs, ${_recentPosts.length} posts');

      // Empty lists are real data (nothing live yet), not "offline".
      _isMockData = false;
      _error = null;

      debugPrint(
          '📊 Final state - Live: ${_dashboardData?.liveMatches.length ?? 0}, '
          'Upcoming: ${_dashboardData?.upcomingMatches.length ?? 0}');
    } on DioException catch (e) {
      debugPrint('⚠️ Dashboard network warning (service handled): ${e.type}');
      _error = null; // Service already provided fallback data
      _isMockData = true;
    } catch (e) {
      debugPrint('❌ Dashboard provider error: $e');
      _error = 'Unable to load dashboard. Showing cached data.';
      _isMockData = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDashboardCarouselMatches() async {
    try {
      final results = await Future.wait<List<Match>>([
        _matchService.getLiveMatches(
          forceRefresh: true,
          limit: 25,
          sort: 'updatedAt',
          order: 'desc',
        ),
        _matchService.getCompletedMatches(
          limit: 100,
          sort: 'updatedAt',
          order: 'desc',
        ),
      ]);

      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      _carouselLiveMatches = _sortLatestMatches(_uniqueMatches(
        results[0].where(_isCarouselLiveMatch).toList(),
      ));
      _recentCompletedMatches = _sortLatestMatches(_uniqueMatches(
        results[1].where((match) {
          final lastActivity = match.updatedAt.isAfter(match.scheduledDate)
              ? match.updatedAt
              : match.scheduledDate;
          return match.isCompleted && lastActivity.isAfter(twoDaysAgo);
        }).toList(),
      ));

      debugPrint(
        '🏏 Dashboard carousel: ${_carouselLiveMatches.length} live, '
        '${_recentCompletedMatches.length} completed in last 2 days',
      );
    } catch (e) {
      debugPrint('⚠️ Dashboard carousel matches not loaded: $e');
      _carouselLiveMatches = [];
      _recentCompletedMatches = [];
    }
  }

  List<Match> _uniqueMatches(List<Match> matches) {
    final seen = <String>{};
    final unique = <Match>[];
    for (final match in matches) {
      if (match.id.isEmpty || !seen.add(match.id)) continue;
      unique.add(match);
    }
    return unique;
  }

  List<Match> _sortLatestMatches(List<Match> matches) {
    return matches
      ..sort((a, b) => _latestMatchTime(b).compareTo(_latestMatchTime(a)));
  }

  DateTime _latestMatchTime(Match match) {
    return match.updatedAt.isAfter(match.scheduledDate)
        ? match.updatedAt
        : match.scheduledDate;
  }

  bool _isCarouselLiveMatch(Match match) {
    const liveStatuses = {
      'live',
      'started',
      'in_progress',
      'ongoing',
      'duckworth_lewis',
      'dls',
    };
    return liveStatuses.contains(match.normalizedStatus);
  }

  /// Get live matches only (refresh from dashboard)
  Future<List<LiveMatch>> getLiveMatches() async {
    if (_dashboardData != null) {
      return _dashboardData!.liveMatches;
    }

    try {
      final data = await _dashboardService.getDashboardOverview();
      _dashboardData = data;
      notifyListeners();
      return data.liveMatches;
    } catch (e) {
      debugPrint('❌ Error getting live matches: $e');
      return [];
    }
  }

  /// Get upcoming matches only
  Future<List<UpcomingMatch>> getUpcomingMatches({int limit = 10}) async {
    if (_dashboardData != null) {
      return limit > 0
          ? _dashboardData!.upcomingMatches.take(limit).toList()
          : _dashboardData!.upcomingMatches;
    }

    try {
      final data = await _dashboardService.getDashboardOverview();
      _dashboardData = data;
      notifyListeners();
      return limit > 0
          ? data.upcomingMatches.take(limit).toList()
          : data.upcomingMatches;
    } catch (e) {
      debugPrint('❌ Error getting upcoming matches: $e');
      return [];
    }
  }

  /// Get trending players only
  Future<List<TrendingPlayer>> getTrendingPlayers({int limit = 10}) async {
    if (_dashboardData != null) {
      return limit > 0
          ? _dashboardData!.trendingPlayers.take(limit).toList()
          : _dashboardData!.trendingPlayers;
    }

    try {
      final data = await _dashboardService.getDashboardOverview();
      _dashboardData = data;
      notifyListeners();
      return limit > 0
          ? data.trendingPlayers.take(limit).toList()
          : data.trendingPlayers;
    } catch (e) {
      debugPrint('❌ Error getting trending players: $e');
      return [];
    }
  }

  /// Get latest tournaments only
  Future<List<Tournament>> getLatestTournaments({int limit = 5}) async {
    if (_dashboardData != null) {
      return limit > 0
          ? _dashboardData!.latestTournaments.take(limit).toList()
          : _dashboardData!.latestTournaments;
    }

    try {
      final data = await _dashboardService.getDashboardOverview();
      _dashboardData = data;
      notifyListeners();
      return limit > 0
          ? data.latestTournaments.take(limit).toList()
          : data.latestTournaments;
    } catch (e) {
      debugPrint('❌ Error getting latest tournaments: $e');
      return [];
    }
  }

  /// Get quick stats only
  Future<QuickStats> getQuickStats() async {
    if (_dashboardData != null) {
      return _dashboardData!.quickStats;
    }

    try {
      final data = await _dashboardService.getDashboardOverview();
      _dashboardData = data;
      notifyListeners();
      return data.quickStats;
    } catch (e) {
      debugPrint('❌ Error getting quick stats: $e');
      return QuickStats(
        totalMatches: 0,
        totalTournaments: 0,
        totalTeams: 0,
        totalPlayers: 0,
        todayMatches: 0,
        weekMatches: 0,
        activeTournaments: 0,
        liveMatches: 0,
      );
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if data is available
  bool get hasData => _dashboardData != null;

  /// Check if there are live matches
  bool get hasLiveMatches => liveMatches.isNotEmpty;

  /// Check if there are upcoming matches
  bool get hasUpcomingMatches =>
      (_dashboardData?.upcomingMatches.isNotEmpty ?? false);

  /// Check if there are trending players
  bool get hasTrendingPlayers =>
      (_dashboardData?.trendingPlayers.isNotEmpty ?? false);

  /// Check if there are tournaments
  bool get hasTournaments =>
      (_dashboardData?.latestTournaments.isNotEmpty ?? false);

  /// Get first live match ID for scorecard navigation
  String? getFirstLiveMatchId() {
    if (liveMatches.isNotEmpty) {
      return liveMatches.first.id;
    }
    return null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Optional: Add a loading wrapper for easier usage
class DashboardProviderWrapper extends StatelessWidget {
  final Widget child;
  final bool autoLoad;

  const DashboardProviderWrapper({
    super.key,
    required this.child,
    this.autoLoad = true,
  });

  @override
  Widget build(BuildContext context) {
    if (autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<DashboardProvider>(context, listen: false).loadDashboard();
      });
    }
    return child;
  }
}
