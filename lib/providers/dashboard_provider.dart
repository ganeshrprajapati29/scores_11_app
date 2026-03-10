import 'package:flutter/foundation.dart';
import '../../data/services/dashboard_service.dart';

/// Dashboard Provider - State Management for Home Screen
class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  // State variables
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;

  // Getters
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetched => _lastFetched;

  // Convenience getters
  List<DashboardMatch> get liveMatches => _dashboardData?.liveMatches ?? [];
  List<DashboardMatch> get upcomingMatches => _dashboardData?.upcomingMatches ?? [];
  List<TrendingPlayer> get trendingPlayers => _dashboardData?.trendingPlayers ?? [];
  List<DashboardTournament> get latestTournaments => _dashboardData?.latestTournaments ?? [];
  QuickStats get quickStats => _dashboardData?.quickStats ?? QuickStats.empty();

  bool get hasData => _dashboardData != null;
  bool get hasError => _error != null;
  bool get isStale =>
      _lastFetched == null ||
      DateTime.now().difference(_lastFetched!).inMinutes > 5;

  /// Load all dashboard data
  Future<void> loadDashboard() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardData = await _dashboardService.getDashboardOverview();
      _lastFetched = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Dashboard load error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    _lastFetched = null;
    await loadDashboard();
  }

  /// Load data if stale (older than 5 minutes)
  Future<void> loadIfStale() async {
    if (isStale || _dashboardData == null) {
      await loadDashboard();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data
  void clearData() {
    _dashboardData = null;
    _lastFetched = null;
    _error = null;
    notifyListeners();
  }
}

