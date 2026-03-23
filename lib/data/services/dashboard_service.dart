// lib/data/services/dashboard_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_model.dart';
import 'dart:developer';

/// Dashboard Service - Real API only (no mock fallback)
class DashboardService {
  final ApiClient _apiClient = ApiClient();

  /// Get complete dashboard overview - Uses the actual dashboard endpoint
  Future<DashboardData> getDashboardOverview() async {
    try {
      debugPrint('🌐 Fetching dashboard data from: ${ApiConfig.baseUrl}/dashboard');
      
      final response = await _apiClient.get('/dashboard');
      
      debugPrint('📡 Dashboard response status: ${response.statusCode}');
      debugPrint('📡 Dashboard response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Check if response has success flag and data
        if (responseData['success'] == true && responseData['data'] != null) {
          return DashboardData.fromJson(responseData['data']);
        } else {
          throw Exception('Invalid response structure: ${responseData['message'] ?? 'Unknown error'}');
        }
      }
      
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Failed with status: ${response.statusCode}',
      );
      
    } on DioException catch (e) {
      debugPrint('❌ Dashboard API DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('❌ Response status: ${e.response?.statusCode}');
        debugPrint('❌ Response data: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Dashboard API error: $e');
      rethrow;
    }
  }

  /// Get live matches - Extracts from dashboard data
  Future<List<LiveMatch>> getLiveMatches() async {
    try {
      final dashboardData = await getDashboardOverview();
      return dashboardData.liveMatches;
    } catch (e) {
      debugPrint('❌ getLiveMatches error: $e');
      return [];
    }
  }

  /// Get upcoming matches - Extracts from dashboard data
  Future<List<UpcomingMatch>> getUpcomingMatches({int limit = 10}) async {
    try {
      final dashboardData = await getDashboardOverview();
      final matches = dashboardData.upcomingMatches;
      return limit > 0 ? matches.take(limit).toList() : matches;
    } catch (e) {
      debugPrint('❌ getUpcomingMatches error: $e');
      return [];
    }
  }

  /// Get trending players - Extracts from dashboard data
  Future<List<TrendingPlayer>> getTrendingPlayers({int limit = 10}) async {
    try {
      final dashboardData = await getDashboardOverview();
      final players = dashboardData.trendingPlayers;
      return limit > 0 ? players.take(limit).toList() : players;
    } catch (e) {
      debugPrint('❌ getTrendingPlayers error: $e');
      return [];
    }
  }

  /// Get latest tournaments - Extracts from dashboard data
  Future<List<Tournament>> getLatestTournaments({int limit = 5}) async {
    try {
      final dashboardData = await getDashboardOverview();
      final tournaments = dashboardData.latestTournaments;
      return limit > 0 ? tournaments.take(limit).toList() : tournaments;
    } catch (e) {
      debugPrint('❌ getLatestTournaments error: $e');
      return [];
    }
  }

  /// Get quick stats - Extracts from dashboard data
  Future<QuickStats> getQuickStats() async {
    try {
      final dashboardData = await getDashboardOverview();
      return dashboardData.quickStats;
    } catch (e) {
      debugPrint('❌ getQuickStats error: $e');
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

  /// Refresh dashboard data (force refresh)
  Future<DashboardData> refreshDashboard() async {
    // Since we're using direct API calls, just fetch again
    return await getDashboardOverview();
  }
}

// Optional: Add a cached version if needed
class CachedDashboardService extends DashboardService {
  DashboardData? _cachedData;
  DateTime? _lastFetch;
  final Duration _cacheDuration = const Duration(minutes: 2);

  @override
  Future<DashboardData> getDashboardOverview() async {
    // Return cached data if still valid
    if (_cachedData != null && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      debugPrint('📦 Returning cached dashboard data');
      return _cachedData!;
    }
    
    // Fetch fresh data
    debugPrint('🔄 Fetching fresh dashboard data');
    _cachedData = await super.getDashboardOverview();
    _lastFetch = DateTime.now();
    return _cachedData!;
  }
  
  void clearCache() {
    _cachedData = null;
    _lastFetch = null;
  }
}