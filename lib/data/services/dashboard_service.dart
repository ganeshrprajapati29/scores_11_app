import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_model.dart';

/// Dashboard Service with offline mock fallback
class DashboardService {
  final ApiClient _apiClient = ApiClient();

  /// Get complete dashboard overview with 404 fallback
  Future<DashboardData> getDashboardOverview() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/overview',
      );
      if (response.statusCode == 200) {
        return DashboardData.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw DioException(requestOptions: response.requestOptions, response: response, type: DioExceptionType.badResponse);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        debugPrint('Dashboard API 404/Timeout - using mock data');
        return _getMockDashboardData();
      }
      rethrow;
    } catch (e) {
      debugPrint('Dashboard API error: $e');
      return _getMockDashboardData();
    }
  }

  /// Mock data for offline/demo mode
  DashboardData _getMockDashboardData() {
    return DashboardData(
      tournaments: [],
      matches: [],
      news: [],
      videos: [],
      stats: {},
      liveMatches: [
        DashboardMatch(
          tournament: DashboardTournament(
            id: 'ipl2024',
            name: 'IPL 2024',
            format: 'T20',
          ),
          id: 'mock-live1',
          title: 'MI vs CSK',
          team1: 'Mumbai Indians',
          team2: 'Chennai Super Kings',
          status: 'LIVE',
          format: 'T20',
          team1Score: 164,
          team2Score: 3,  // wickets
        ),
      ],
      upcomingMatches: [
        DashboardMatch(
          tournament: DashboardTournament(
            id: 'ipl2024',
            name: 'IPL 2024',
            format: 'T20',
          ),
          id: 'mock-up1',
          title: 'DC vs KKR',
          team1: 'Delhi Capitals',
          team2: 'Kolkata Knight Riders',
          status: 'SCHEDULED',
          format: 'T20',
        ),
        DashboardMatch(
          tournament: DashboardTournament(
            id: 'ipl2024',
            name: 'IPL 2024',
            format: 'T20',
          ),
          id: 'mock-up2',
          title: 'RCB vs PBKS',
          team1: 'RCB',
          team2: 'Punjab Kings',
          status: 'SCHEDULED',
          format: 'T20',
        ),
      ],
      trendingPlayers: [
        TrendingPlayer(
          rank: 1,
          id: 'virat',
          name: 'Virat Kohli',
          role: 'Batsman',
          stats: PlayerStats(runs: 452, wickets: 0, matches: 8, average: 64.57, strikeRate: 148.2),
        ),
        TrendingPlayer(
          rank: 2,
          id: 'bumrah',
          name: 'Jasprit Bumrah',
          role: 'Bowler',
          stats: PlayerStats(runs: 23, wickets: 12, matches: 8, average: 8.5, strikeRate: 112.0),
        ),
        TrendingPlayer(
          rank: 3,
          id: 'skyy',
          name: 'Suryakumar Yadav',
          role: 'Batsman',
          stats: PlayerStats(runs: 312, wickets: 0, matches: 7, average: 52.0, strikeRate: 167.7),
        ),
      ],
      latestTournaments: [
        DashboardTournament(
          id: 'ipl2024',
          name: 'IPL 2024',
          format: 'T20',
          status: 'LIVE',
        ),
        DashboardTournament(
          id: 't20blast',
          name: 'T20 Blast 2024',
          format: 'T20',
          status: 'UPCOMING',
        ),
      ],
      quickStats: QuickStats(
        totalMatches: 1247,
        totalTournaments: 89,
        totalTeams: 1562,
        totalPlayers: 24567,
        todayMatches: 3,
        weekMatches: 28,
        activeTournaments: 12,
        liveMatches: 1,
      ),
    );
  }

  Future<List<DashboardMatch>> getLiveMatches() async {
    try {
      final response = await _apiClient.get('${ApiConfig.dashboard}/live-matches');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => DashboardMatch.fromJson(json)).toList();
      }
      throw Exception('Failed to get live matches');
    } catch (e) {
      return _getMockDashboardData().liveMatches;
    }
  }

  Future<List<DashboardMatch>> getUpcomingMatches({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/upcoming-matches',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => DashboardMatch.fromJson(json)).toList();
      }
      throw Exception('Failed to get upcoming matches');
    } catch (e) {
      return _getMockDashboardData().upcomingMatches.take(limit).toList();
    }
  }

  Future<List<TrendingPlayer>> getTrendingPlayers({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/trending-players',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => TrendingPlayer.fromJson(json)).toList();
      }
      throw Exception('Failed to get trending players');
    } catch (e) {
      return _getMockDashboardData().trendingPlayers.take(limit).toList();
    }
  }

  Future<List<DashboardTournament>> getLatestTournaments({int limit = 5}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/latest-tournaments',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => DashboardTournament.fromJson(json)).toList();
      }
      throw Exception('Failed to get tournaments');
    } catch (e) {
      return _getMockDashboardData().latestTournaments.take(limit).toList();
    }
  }

  Future<QuickStats> getQuickStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.dashboard}/quick-stats');
      if (response.statusCode == 200) {
        return QuickStats.fromJson(response.data['data']);
      }
      throw Exception('Failed to get stats');
    } catch (e) {
      return _getMockDashboardData().quickStats;
    }
  }
}
