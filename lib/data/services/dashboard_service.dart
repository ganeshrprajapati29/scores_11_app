import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/match_model.dart';
import '../models/tournament_model.dart';

/// Dashboard data model containing all home screen data
class DashboardData {
  final List<DashboardMatch> liveMatches;
  final List<DashboardMatch> upcomingMatches;
  final List<TrendingPlayer> trendingPlayers;
  final List<DashboardTournament> latestTournaments;
  final QuickStats quickStats;
  final String? timestamp;

  DashboardData({
    required this.liveMatches,
    required this.upcomingMatches,
    required this.trendingPlayers,
    required this.latestTournaments,
    required this.quickStats,
    this.timestamp,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      liveMatches: (json['liveMatches'] as List<dynamic>?)
              ?.map((e) => DashboardMatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      upcomingMatches: (json['upcomingMatches'] as List<dynamic>?)
              ?.map((e) => DashboardMatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      trendingPlayers: (json['trendingPlayers'] as List<dynamic>?)
              ?.map((e) => TrendingPlayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      latestTournaments: (json['latestTournaments'] as List<dynamic>?)
              ?.map((e) => DashboardTournament.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quickStats: json['quickStats'] != null
          ? QuickStats.fromJson(json['quickStats'] as Map<String, dynamic>)
          : QuickStats.empty(),
      timestamp: json['timestamp'] as String?,
    );
  }
}

/// Simplified match model for dashboard
class DashboardMatch {
  final String id;
  final int? matchNumber;
  final DashboardTeam team1;
  final DashboardTeam team2;
  final String status;
  final String format;
  final DateTime? scheduledDate;
  final DashboardTournamentInfo? tournament;
  final DashboardInnings? innings;

  DashboardMatch({
    required this.id,
    this.matchNumber,
    required this.team1,
    required this.team2,
    required this.status,
    required this.format,
    this.scheduledDate,
    this.tournament,
    this.innings,
  });

  factory DashboardMatch.fromJson(Map<String, dynamic> json) {
    return DashboardMatch(
      id: json['id'] as String? ?? '',
      matchNumber: json['matchNumber'] as int?,
      team1: json['team1'] != null
          ? DashboardTeam.fromJson(json['team1'] as Map<String, dynamic>)
          : DashboardTeam.empty(),
      team2: json['team2'] != null
          ? DashboardTeam.fromJson(json['team2'] as Map<String, dynamic>)
          : DashboardTeam.empty(),
      status: json['status'] as String? ?? '',
      format: json['format'] as String? ?? 'T20',
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'] as String)
          : null,
      tournament: json['tournament'] != null
          ? DashboardTournamentInfo.fromJson(
              json['tournament'] as Map<String, dynamic>)
          : null,
      innings: json['innings'] != null
          ? DashboardInnings.fromJson(json['innings'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isLive => status == 'LIVE';
  bool get isUpcoming =>
      status == 'SCHEDULED' || status == 'READY';
  bool get isCompleted => status == 'COMPLETED';
}

/// Simplified team model for dashboard
class DashboardTeam {
  final String? id;
  final String name;
  final String shortName;
  final String? logo;

  DashboardTeam({
    this.id,
    required this.name,
    required this.shortName,
    this.logo,
  });

  factory DashboardTeam.fromJson(Map<String, dynamic> json) {
    return DashboardTeam(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'TBD',
      shortName: json['shortName'] as String? ?? 'TBD',
      logo: json['logo'] as String?,
    );
  }

  factory DashboardTeam.empty() {
    return DashboardTeam(name: 'TBD', shortName: 'TBD');
  }
}

/// Tournament info for dashboard
class DashboardTournamentInfo {
  final String? id;
  final String name;
  final String? format;

  DashboardTournamentInfo({
    this.id,
    required this.name,
    this.format,
  });

  factory DashboardTournamentInfo.fromJson(Map<String, dynamic> json) {
    return DashboardTournamentInfo(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      format: json['format'] as String?,
    );
  }
}

/// Innings info for dashboard
class DashboardInnings {
  final int? currentInnings;
  final int? totalRuns;
  final int? wickets;
  final double? overs;

  DashboardInnings({
    this.currentInnings,
    this.totalRuns,
    this.wickets,
    this.overs,
  });

  factory DashboardInnings.fromJson(Map<String, dynamic> json) {
    return DashboardInnings(
      currentInnings: json['currentInnings'] as int?,
      totalRuns: json['totalRuns'] as int?,
      wickets: json['wickets'] as int?,
      overs: (json['overs'] as num?)?.toDouble(),
    );
  }

  String get scoreString =>
      '${totalRuns ?? 0}/${wickets ?? 0} (${overs?.toStringAsFixed(1) ?? "0.0"})';
}

/// Trending player model
class TrendingPlayer {
  final int rank;
  final String id;
  final String name;
  final int? jerseyNumber;
  final String? role;
  final String? avatar;
  final DashboardTeam? team;
  final PlayerStats stats;

  TrendingPlayer({
    required this.rank,
    required this.id,
    required this.name,
    this.jerseyNumber,
    this.role,
    this.avatar,
    this.team,
    required this.stats,
  });

  factory TrendingPlayer.fromJson(Map<String, dynamic> json) {
    return TrendingPlayer(
      rank: json['rank'] as int? ?? 0,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      jerseyNumber: json['jerseyNumber'] as int?,
      role: json['role'] as String?,
      avatar: json['avatar'] as String?,
      team: json['team'] != null
          ? DashboardTeam.fromJson(json['team'] as Map<String, dynamic>)
          : null,
      stats: json['stats'] != null
          ? PlayerStats.fromJson(json['stats'] as Map<String, dynamic>)
          : PlayerStats.empty(),
    );
  }
}

/// Player stats
class PlayerStats {
  final int runs;
  final int wickets;
  final int matches;
  final double average;
  final double strikeRate;

  PlayerStats({
    required this.runs,
    required this.wickets,
    required this.matches,
    required this.average,
    required this.strikeRate,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      runs: json['runs'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      matches: json['matches'] as int? ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      strikeRate: (json['strikeRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory PlayerStats.empty() {
    return PlayerStats(runs: 0, wickets: 0, matches: 0, average: 0, strikeRate: 0);
  }
}

/// Dashboard tournament model
class DashboardTournament {
  final String id;
  final String name;
  final String? shortName;
  final String format;
  final String type;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? venue;
  final int totalTeams;
  final double? prizeMoney;
  final bool isPaid;
  final double? entryFee;
  final String? image;

  DashboardTournament({
    required this.id,
    required this.name,
    this.shortName,
    required this.format,
    required this.type,
    required this.status,
    this.startDate,
    this.endDate,
    this.venue,
    required this.totalTeams,
    this.prizeMoney,
    required this.isPaid,
    this.entryFee,
    this.image,
  });

  factory DashboardTournament.fromJson(Map<String, dynamic> json) {
    return DashboardTournament(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String?,
      format: json['format'] as String? ?? 'T20',
      type: json['type'] as String? ?? 'LEAGUE',
      status: json['status'] as String? ?? 'SCHEDULED',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      venue: json['venue'] as String?,
      totalTeams: json['totalTeams'] as int? ?? 0,
      prizeMoney: (json['prizeMoney'] as num?)?.toDouble(),
      isPaid: json['isPaid'] as bool? ?? false,
      entryFee: (json['entryFee'] as num?)?.toDouble(),
      image: json['image'] as String?,
    );
  }
}

/// Quick stats model
class QuickStats {
  final int totalMatches;
  final int totalTournaments;
  final int totalTeams;
  final int totalPlayers;
  final int todayMatches;
  final int weekMatches;
  final int activeTournaments;
  final int liveMatches;

  QuickStats({
    required this.totalMatches,
    required this.totalTournaments,
    required this.totalTeams,
    required this.totalPlayers,
    required this.todayMatches,
    required this.weekMatches,
    required this.activeTournaments,
    required this.liveMatches,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      totalMatches: json['totalMatches'] as int? ?? 0,
      totalTournaments: json['totalTournaments'] as int? ?? 0,
      totalTeams: json['totalTeams'] as int? ?? 0,
      totalPlayers: json['totalPlayers'] as int? ?? 0,
      todayMatches: json['todayMatches'] as int? ?? 0,
      weekMatches: json['weekMatches'] as int? ?? 0,
      activeTournaments: json['activeTournaments'] as int? ?? 0,
      liveMatches: json['liveMatches'] as int? ?? 0,
    );
  }

  factory QuickStats.empty() {
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

/// Dashboard Service for fetching home screen data
class DashboardService {
  final ApiClient _apiClient = ApiClient();

  /// Get complete dashboard overview
  Future<DashboardData> getDashboardOverview() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/overview',
      );
      if (response.statusCode == 200) {
        return DashboardData.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to get dashboard');
    } catch (e) {
      rethrow;
    }
  }

  /// Get live matches only
  Future<List<DashboardMatch>> getLiveMatches() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/live-matches',
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data
            .map((json) => DashboardMatch.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get live matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Get upcoming matches
  Future<List<DashboardMatch>> getUpcomingMatches({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/upcoming-matches',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data
            .map((json) => DashboardMatch.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get upcoming matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Get trending players
  Future<List<TrendingPlayer>> getTrendingPlayers({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/trending-players',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data
            .map((json) => TrendingPlayer.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get trending players');
    } catch (e) {
      rethrow;
    }
  }

  /// Get latest tournaments
  Future<List<DashboardTournament>> getLatestTournaments({int limit = 5}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/latest-tournaments',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data
            .map((json) => DashboardTournament.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get tournaments');
    } catch (e) {
      rethrow;
    }
  }

  /// Get quick stats
  Future<QuickStats> getQuickStats() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.dashboard}/quick-stats',
      );
      if (response.statusCode == 200) {
        return QuickStats.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to get stats');
    } catch (e) {
      rethrow;
    }
  }
}

