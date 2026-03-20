import 'package:flutter/material.dart';
import '../data/models/dashboard_model.dart';
import 'package:flutter/foundation.dart';
import '../core/services/api_client.dart';
import '../core/config/api_config.dart';
import '../data/services/dashboard_service.dart';
import '../data/models/user_stats_model.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardData? _dashboardData;
  QuickStats? _quickStats;
  bool _isLoading = false;
  bool _isMockData = false;
  String? _error;

  DashboardData? get dashboardData => _dashboardData;
  QuickStats? get quickStats => _quickStats;
  bool get isLoading => _isLoading;
  bool get isMockData => _isMockData;
  String? get error => _error;

  List<DashboardMatch> get liveMatches => _dashboardData?.liveMatches ?? [];
  List<DashboardMatch> get upcomingMatches => _dashboardData?.upcomingMatches ?? [];
  List<TrendingPlayer> get trendingPlayers => _dashboardData?.trendingPlayers ?? [];
  List<DashboardTournament> get latestTournaments => _dashboardData?.latestTournaments ?? [];

  final DashboardService _dashboardService = DashboardService();

  Future<void> loadDashboard() async {
    await fetchDashboardData();
  }

  Future<void> refreshDashboard([BuildContext? context]) async {
    await fetchDashboardData();
  }

Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load main dashboard data
      _dashboardData = await _dashboardService.getDashboardOverview();
      
      // Load quick stats separately
      _quickStats = await _dashboardService.getQuickStats();
      
      _isMockData = false;
      _error = null;
    } catch (e) {
      debugPrint('Dashboard error: $e');
      _error = e.toString();
      _isMockData = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

Future<UserStats> loadUserStats() async {
    try {
      final response = await ApiClient().get('${ApiConfig.auth}/me/stats');
      if (response.statusCode == 200) {
        return UserStats.fromJson(response.data['data']);
      }
    } catch (e) {
      debugPrint('User stats API error: $e');
    }
    // Mock fallback
    return UserStats(
      followers: 124,
      following: 45, 
      profileViews: 5678,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
