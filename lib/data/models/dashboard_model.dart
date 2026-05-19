// lib/data/models/dashboard_model.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/tournament_model.dart';

// ==================== Main Dashboard Model ====================
class DashboardData {
  final List<LiveMatch> liveMatches;
  final List<UpcomingMatch> upcomingMatches;
  final List<TrendingPlayer> trendingPlayers;
  final List<Tournament> latestTournaments;
  final QuickStats quickStats;
  final DateTime timestamp;

  DashboardData({
    required this.liveMatches,
    required this.upcomingMatches,
    required this.trendingPlayers,
    required this.latestTournaments,
    required this.quickStats,
    required this.timestamp,
  });

factory DashboardData.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Handle quickStats being null, String, Map, or any other type
    Map<String, dynamic> safeQuickStats = {};
    final rawQuickStats = json['quickStats'];
    if (rawQuickStats is Map<String, dynamic>) {
      safeQuickStats = rawQuickStats;
    } else if (rawQuickStats != null) {
      debugPrint('⚠️ quickStats type: ${rawQuickStats.runtimeType} - using empty stats');
    }

    // ✅ FIX: Handle lists safely - check type before casting
    List<LiveMatch> safeLiveMatches = [];
    List<UpcomingMatch> safeUpcomingMatches = [];
    List<TrendingPlayer> safeTrendingPlayers = [];
    List<Tournament> safeLatestTournaments = [];

    try {
      if (json['liveMatches'] is List) {
        safeLiveMatches = (json['liveMatches'] as List)
            .where((e) => e is Map<String, dynamic>)
            .map((e) => LiveMatch.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) { debugPrint('⚠️.liveMatches error: $e'); }

    try {
      if (json['upcomingMatches'] is List) {
        safeUpcomingMatches = (json['upcomingMatches'] as List)
            .where((e) => e is Map<String, dynamic>)
            .map((e) => UpcomingMatch.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) { debugPrint('⚠️ upcomingMatches error: $e'); }

    try {
      if (json['trendingPlayers'] is List) {
        safeTrendingPlayers = (json['trendingPlayers'] as List)
            .where((e) => e is Map<String, dynamic>)
            .map((e) => TrendingPlayer.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) { debugPrint('⚠️ trendingPlayers error: $e'); }

    try {
      if (json['latestTournaments'] is List) {
        safeLatestTournaments = (json['latestTournaments'] as List)
            .where((e) => e is Map<String, dynamic>)
            .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) { debugPrint('⚠️ latestTournaments error: $e'); }

    return DashboardData(
      liveMatches: safeLiveMatches,
      upcomingMatches: safeUpcomingMatches,
      trendingPlayers: safeTrendingPlayers,
      latestTournaments: safeLatestTournaments,
      quickStats: QuickStats.fromJson(safeQuickStats),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'liveMatches': liveMatches.map((e) => e.toJson()).toList(),
      'upcomingMatches': upcomingMatches.map((e) => e.toJson()).toList(),
      'trendingPlayers': trendingPlayers.map((e) => e.toJson()).toList(),
      'latestTournaments': latestTournaments.map((e) => e.toJson()).toList(),
      'quickStats': quickStats.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// ==================== Quick Stats Model ====================
class QuickStats {
  final int totalMatches;
  final int totalTournaments;
  final int totalTeams;
  final int totalPlayers;
  final int todayMatches;
  final int weekMatches;
  final int activeTournaments;
  final int liveMatches;

  const QuickStats({
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
    // ✅ FIX: Handle both int and String types for all fields
    return QuickStats(
      totalMatches: int.tryParse(json['totalMatches']?.toString() ?? '0') ?? 0,
      totalTournaments: int.tryParse(json['totalTournaments']?.toString() ?? '0') ?? 0,
      totalTeams: int.tryParse(json['totalTeams']?.toString() ?? '0') ?? 0,
      totalPlayers: int.tryParse(json['totalPlayers']?.toString() ?? '0') ?? 0,
      todayMatches: int.tryParse(json['todayMatches']?.toString() ?? '0') ?? 0,
      weekMatches: int.tryParse(json['weekMatches']?.toString() ?? '0') ?? 0,
      activeTournaments: int.tryParse(json['activeTournaments']?.toString() ?? '0') ?? 0,
      liveMatches: int.tryParse(json['liveMatches']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMatches': totalMatches,
      'totalTournaments': totalTournaments,
      'totalTeams': totalTeams,
      'totalPlayers': totalPlayers,
      'todayMatches': todayMatches,
      'weekMatches': weekMatches,
      'activeTournaments': activeTournaments,
      'liveMatches': liveMatches,
    };
  }
}

// ==================== Team Model ====================
class Team {
  final String id;
  final String name;
  final String shortName;
  final String? logo;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.logo,
  });

  factory Team.fromJson(dynamic json) {
    // ✅ FIX: Handle Map, String, or null input
    if (json is String) {
      return Team(id: json, name: json, shortName: json);
    }
    if (json is Map) {
      return Team(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        shortName: json['shortName']?.toString() ?? json['name']?.toString().substring(0, 1) ?? '',
        logo: json['logo']?.toString(),
      );
    }
    return Team(id: '', name: 'Unknown', shortName: '?');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'logo': logo,
    };
  }
}


// ==================== Live Match Model ====================
class LiveMatch {
  final String id;
  final Team team1;
  final Team team2;
  final String status;
  final String format;
  final DateTime scheduledDate;
  final Tournament tournament;
  final Map<String, dynamic>? innings;
  final String? scoreString;
  final int? team1Score;
  final int? team2Score;
  final int? team1Wickets;
  final int? team2Wickets;
  final String? team1Overs;
  final String? team2Overs;
  final int currentInnings;
  final String? venue;
  final String? venueCity;
  final String? matchType;
  final String? result;
  final String? tossWinner;
  final String? tossDecision;
  final int? target;
  final int? requiredRuns;

  LiveMatch({
    required this.id,
    required this.team1,
    required this.team2,
    required this.status,
    required this.format,
    required this.scheduledDate,
    required this.tournament,
    this.innings,
    this.scoreString,
    this.team1Score,
    this.team2Score,
    this.team1Wickets,
    this.team2Wickets,
    this.team1Overs,
    this.team2Overs,
    this.currentInnings = 1,
    this.venue,
    this.venueCity,
    this.matchType,
    this.result,
    this.tossWinner,
    this.tossDecision,
    this.target,
    this.requiredRuns,
  });

  factory LiveMatch.fromJson(dynamic json) {
    // ✅ FIX: Handle dynamic input (Map, String, null)
    Map<String, dynamic> safeJson = {};
    if (json is Map) {
      safeJson = Map<String, dynamic>.from(json);
    }
    
    return LiveMatch(
      id: safeJson['_id']?.toString() ?? safeJson['id']?.toString() ?? '',
      team1: Team.fromJson(safeJson['team1']),
      team2: Team.fromJson(safeJson['team2']),
      status: safeJson['status']?.toString() ?? '',
      format: safeJson['format']?.toString() ?? '',
      scheduledDate: DateTime.tryParse(safeJson['scheduledDate']?.toString() ?? '') ?? DateTime.now(),
      tournament: Tournament.fromJson(safeJson['tournament'] ?? {}),
      innings: safeJson['innings'] is Map ? Map<String, dynamic>.from(safeJson['innings']) : null,
      scoreString: safeJson['scoreString']?.toString() ?? _scoreText(safeJson),
      team1Score: int.tryParse(safeJson['team1Score']?.toString() ?? safeJson['team1Runs']?.toString() ?? safeJson['score']?['team1']?['runs']?.toString() ?? ''),
      team2Score: int.tryParse(safeJson['team2Score']?.toString() ?? safeJson['team2Runs']?.toString() ?? safeJson['score']?['team2']?['runs']?.toString() ?? ''),
      team1Wickets: int.tryParse(safeJson['team1Wickets']?.toString() ?? safeJson['score']?['team1']?['wickets']?.toString() ?? ''),
      team2Wickets: int.tryParse(safeJson['team2Wickets']?.toString() ?? safeJson['score']?['team2']?['wickets']?.toString() ?? ''),
      team1Overs: _readOvers(safeJson, 1),
      team2Overs: _readOvers(safeJson, 2),
      currentInnings: int.tryParse(safeJson['currentInnings']?.toString() ?? safeJson['currentInningsScore']?['inningsNumber']?.toString() ?? '1') ?? 1,
      venue: safeJson['venue']?.toString(),
      venueCity: safeJson['venueCity']?.toString() ?? safeJson['city']?.toString(),
      matchType: safeJson['matchType']?.toString() ?? safeJson['type']?.toString(),
      result: _readResultText(safeJson),
      tossWinner: _readTossValue(safeJson, 'winner'),
      tossDecision: _readTossValue(safeJson, 'decision'),
      target: int.tryParse(safeJson['target']?.toString() ?? safeJson['result']?['target']?.toString() ?? ''),
      requiredRuns: int.tryParse(safeJson['requiredRuns']?.toString() ?? safeJson['result']?['requiredRuns']?.toString() ?? ''),
    );
  }

  static String? _readResultText(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map) {
      return result['message']?.toString() ?? result['winner']?['name']?.toString() ?? result['winner']?.toString();
    }
    return result?.toString();
  }

  static String? _readTossValue(Map<String, dynamic> json, String key) {
    final directKeys = key == 'winner'
        ? const ['tossWinner', 'tossWinnerId', 'toss_winner']
        : const ['tossDecision', 'toss_decision'];
    for (final directKey in directKeys) {
      final direct = json[directKey];
      if (direct is Map) {
        final text = direct['shortName']?.toString() ??
            direct['name']?.toString() ??
            direct['_id']?.toString();
        if (text != null && text.isNotEmpty) return text;
      }
      final text = direct?.toString();
      if (text != null && text.isNotEmpty) return text;
    }

    final toss = json['toss'];
    if (toss is! Map) return null;
    final value = toss[key];
    if (value is Map) {
      return value['shortName']?.toString() ?? value['name']?.toString() ?? value['_id']?.toString();
    }
    return value?.toString();
  }

  static String? _scoreText(Map<String, dynamic> json) {
    final score = json['score'];
    if (score is! Map) return null;
    final team1 = score['team1'];
    final team2 = score['team2'];
    String formatTeam(dynamic data) {
      if (data is! Map) return '0/0 (0.0)';
      return '${data['runs'] ?? 0}/${data['wickets'] ?? 0} (${data['overs'] ?? '0.0'})';
    }
    return '${formatTeam(team1)} | ${formatTeam(team2)}';
  }

  static String? _readOvers(Map<String, dynamic> json, int team) {
    final directKey = team == 1 ? 'team1Overs' : 'team2Overs';
    final direct = json[directKey]?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final score = json['score'];
    if (score is Map) {
      final teamScore = score[team == 1 ? 'team1' : 'team2'];
      if (teamScore is Map) {
        final overs = teamScore['overs']?.toString();
        if (overs != null && overs.isNotEmpty) return overs;
      }
    }
    return null;
  }

  String? scoreForTeam(int team) {
    final runs = team == 1 ? team1Score : team2Score;
    if (runs == null) return null;
    final wickets = team == 1 ? team1Wickets : team2Wickets;
    final overs = team == 1 ? team1Overs : team2Overs;
    final score = '$runs/${wickets ?? 0}';
    if (overs == null || overs.isEmpty) return score;
    return '$score ($overs ov)';
  }

  bool get isActuallyLive {
    final normalized = status.toLowerCase().trim();
    if (normalized == 'completed' || normalized == 'finished' || normalized == 'cancelled') {
      return false;
    }
    if (result != null && result!.trim().isNotEmpty && normalized != 'live') {
      return false;
    }
    return normalized == 'live' || normalized == 'in_progress' || normalized == 'started';
  }

  String get liveSummary {
    if (result != null && result!.trim().isNotEmpty) return result!;
    if (target != null && currentInnings == 2) {
      final needed = requiredRuns == null ? '' : ' - $requiredRuns needed';
      return 'Target $target$needed';
    }
    if (tossWinner != null && tossWinner!.trim().isNotEmpty) {
      final decision = tossDecision == null || tossDecision!.trim().isEmpty
          ? ''
          : ' chose ${tossDecision!.toLowerCase()}';
      return 'Toss: $tossWinner$decision';
    }
    return 'Innings $currentInnings in progress';
  }

  bool get hasAnyScore => team1Score != null || team2Score != null || (scoreString?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team1': team1.toJson(),
      'team2': team2.toJson(),
      'status': status,
      'format': format,
      'scheduledDate': scheduledDate.toIso8601String(),
      'tournament': tournament.toJson(),
      'innings': innings,
      'scoreString': scoreString,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'team1Wickets': team1Wickets,
      'team2Wickets': team2Wickets,
      'team1Overs': team1Overs,
      'team2Overs': team2Overs,
      'currentInnings': currentInnings,
      'venue': venue,
      'venueCity': venueCity,
      'matchType': matchType,
      'result': result,
      'tossWinner': tossWinner,
      'tossDecision': tossDecision,
      'target': target,
      'requiredRuns': requiredRuns,
    };
  }

  // Format scheduled date for display
  String get formattedDate {
    final now = DateTime.now();
    final diff = scheduledDate.difference(now);
    
    if (diff.isNegative) {
      // Past match - show result
      if (result != null && result!.isNotEmpty) {
        return result!;
      }
      return status == 'completed' ? 'Completed' : '$team1Score - $team2Score';
    }
    
    // Today
    if (scheduledDate.day == now.day && 
        scheduledDate.month == now.month && 
        scheduledDate.year == now.year) {
      return 'Today, ${_formatTime(scheduledDate)}';
    }
    
    // Tomorrow
    final tomorrow = now.add(const Duration(days: 1));
    if (scheduledDate.day == tomorrow.day && 
        scheduledDate.month == tomorrow.month && 
        scheduledDate.year == tomorrow.year) {
      return 'Tomorrow, ${_formatTime(scheduledDate)}';
    }
    
    // Other days
    return '${_formatDate(scheduledDate)}, ${_formatTime(scheduledDate)}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

// ==================== Upcoming Match Model ====================
class UpcomingMatch {
  final String id;
  final Team team1;
  final Team team2;
  final String format;
  final DateTime scheduledDate;
  final Tournament tournament;

  UpcomingMatch({
    required this.id,
    required this.team1,
    required this.team2,
    required this.format,
    required this.scheduledDate,
    required this.tournament,
  });

  factory UpcomingMatch.fromJson(dynamic json) {
    // ✅ FIX: Handle dynamic input (Map, String, null)
    Map<String, dynamic> safeJson = {};
    if (json is Map) {
      safeJson = Map<String, dynamic>.from(json);
    }
    
    return UpcomingMatch(
      id: safeJson['_id']?.toString() ?? safeJson['id']?.toString() ?? '',
      team1: Team.fromJson(safeJson['team1']),
      team2: Team.fromJson(safeJson['team2']),
      format: safeJson['format']?.toString() ?? '',
      scheduledDate: DateTime.tryParse(safeJson['scheduledDate']?.toString() ?? '') ?? DateTime.now(),
      tournament: Tournament.fromJson(safeJson['tournament'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team1': team1.toJson(),
      'team2': team2.toJson(),
      'format': format,
      'scheduledDate': scheduledDate.toIso8601String(),
      'tournament': tournament.toJson(),
    };
  }
}

// ==================== Trending Player Model ====================
class TrendingPlayer {
  final int rank;
  final String id;
  final String name;
  final int jerseyNumber;
  final String role;
  final Team team;
  final PlayerStats stats;

  TrendingPlayer({
    required this.rank,
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.role,
    required this.team,
    required this.stats,
  });

  factory TrendingPlayer.fromJson(dynamic json) {
    // ✅ FIX: Handle dynamic input (Map, String, null)
    Map<String, dynamic> safeJson = {};
    if (json is Map) {
      safeJson = Map<String, dynamic>.from(json);
    }
    final player = safeJson['player'] is Map
        ? Map<String, dynamic>.from(safeJson['player'] as Map)
        : safeJson;
    final statsJson = safeJson['stats'] ?? player['stats'] ?? safeJson;
    
    return TrendingPlayer(
      rank: int.tryParse(safeJson['rank']?.toString() ?? '0') ?? 0,
      id: player['_id']?.toString() ?? player['id']?.toString() ?? safeJson['_id']?.toString() ?? safeJson['id']?.toString() ?? '',
      name: player['name']?.toString() ?? player['playerName']?.toString() ?? safeJson['name']?.toString() ?? '',
      jerseyNumber: int.tryParse(player['jerseyNumber']?.toString() ?? safeJson['jerseyNumber']?.toString() ?? '0') ?? 0,
      role: player['role']?.toString() ?? safeJson['role']?.toString() ?? '',
      team: Team.fromJson(player['team'] ?? safeJson['team']),
      stats: PlayerStats.fromJson(statsJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'id': id,
      'name': name,
      'jerseyNumber': jerseyNumber,
      'role': role,
      'team': team.toJson(),
      'stats': stats.toJson(),
    };
  }
}

// ==================== Player Stats Model ====================
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

  factory PlayerStats.fromJson(dynamic json) {
    // ✅ FIX: Handle dynamic input (Map, String, null)
    Map<String, dynamic> safeJson = {};
    if (json is Map) {
      safeJson = Map<String, dynamic>.from(json);
    }
    
    return PlayerStats(
      runs: int.tryParse((safeJson['runs'] ?? safeJson['totalRuns'] ?? safeJson['battingRuns'] ?? '0').toString()) ?? 0,
      wickets: int.tryParse((safeJson['wickets'] ?? safeJson['totalWickets'] ?? safeJson['bowlingWickets'] ?? '0').toString()) ?? 0,
      matches: int.tryParse((safeJson['matches'] ?? safeJson['totalMatches'] ?? safeJson['matchesPlayed'] ?? '0').toString()) ?? 0,
      average: double.tryParse(safeJson['average']?.toString() ?? '0') ?? 0.0,
      strikeRate: double.tryParse((safeJson['strikeRate'] ?? safeJson['sr'] ?? safeJson['battingStrikeRate'] ?? '0').toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runs': runs,
      'wickets': wickets,
      'matches': matches,
      'average': average,
      'strikeRate': strikeRate,
    };
  }
}

// ==================== Helper Extensions ====================
extension MatchStatusExtension on String {
  Color get statusColor {
    switch (this.toLowerCase()) {
      case 'live':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'upcoming':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (this.toLowerCase()) {
      case 'live':
        return 'LIVE';
      case 'completed':
        return 'COMPLETED';
      case 'upcoming':
        return 'UPCOMING';
      default:
        return this.toUpperCase();
    }
  }
}

extension FormatExtension on String {
  String get formatDisplay {
    switch (this.toLowerCase()) {
      case 't20':
        return 'T20';
      case 'odi':
        return 'ODI';
      case 'test':
        return 'TEST';
      default:
        return this.toUpperCase();
    }
  }
}
