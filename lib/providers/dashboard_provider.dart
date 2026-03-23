// lib/providers/dashboard_provider.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../data/models/dashboard_model.dart';
import '../data/services/dashboard_service.dart';
import '../core/services/api_client.dart';
import '../core/config/api_config.dart';
import 'dart:developer';

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
  List<LiveMatch> get liveMatches => _dashboardData?.liveMatches ?? [];
  List<UpcomingMatch> get upcomingMatches => _dashboardData?.upcomingMatches ?? [];
  List<TrendingPlayer> get trendingPlayers => _dashboardData?.trendingPlayers ?? [];
  List<Tournament> get latestTournaments => _dashboardData?.latestTournaments ?? [];
  QuickStats get quickStats => _dashboardData?.quickStats ?? const QuickStats(
    totalMatches: 0,
    totalTournaments: 0,
    totalTeams: 0,
    totalPlayers: 0,
    todayMatches: 0,
    weekMatches: 0,
    activeTournaments: 0,
    liveMatches: 0,
  );

  final DashboardService _dashboardService = DashboardService();

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

  /// Fetch dashboard data from API
  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔄 Fetching dashboard data...');
      
      // Load main dashboard data (includes all sections)
      _dashboardData = await _dashboardService.getDashboardOverview();
      
      if (_dashboardData != null) {
        _isMockData = false;
        _error = null;
        debugPrint('✅ Dashboard data loaded successfully');
        debugPrint('📊 Live matches: ${_dashboardData!.liveMatches.length}');
        debugPrint('📊 Upcoming matches: ${_dashboardData!.upcomingMatches.length}');
        debugPrint('📊 Trending players: ${_dashboardData!.trendingPlayers.length}');
        debugPrint('📊 Tournaments: ${_dashboardData!.latestTournaments.length}');
      } else {
        _error = 'No data received from server';
        _isMockData = true;
        debugPrint('⚠️ No dashboard data received');
      }
      
    } on DioException catch (e) {
      debugPrint('❌ Dashboard DioException: ${e.type} - ${e.message}');
      
      if (e.response?.statusCode == 401) {
        _error = 'Session expired. Please login again.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        _error = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        _error = 'No internet connection. Please check your network.';
      } else if (e.response?.statusCode == 404) {
        _error = 'Dashboard endpoint not found. Please contact support.';
      } else if (e.response?.statusCode == 500) {
        _error = 'Server error. Please try again later.';
      } else {
        _error = e.message ?? 'Failed to load dashboard data';
      }
      
      _isMockData = true;
      
    } catch (e) {
      debugPrint('❌ Dashboard error: $e');
      _error = e.toString();
      _isMockData = true;
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  bool get hasLiveMatches => (_dashboardData?.liveMatches.isNotEmpty ?? false);

  /// Check if there are upcoming matches
  bool get hasUpcomingMatches => (_dashboardData?.upcomingMatches.isNotEmpty ?? false);

  /// Check if there are trending players
  bool get hasTrendingPlayers => (_dashboardData?.trendingPlayers.isNotEmpty ?? false);

  /// Check if there are tournaments
  bool get hasTournaments => (_dashboardData?.latestTournaments.isNotEmpty ?? false);

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
