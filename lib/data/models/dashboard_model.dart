// lib/data/models/dashboard_model.dart

import 'package:flutter/material.dart';

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
    return DashboardData(
      liveMatches: (json['liveMatches'] as List? ?? [])
          .map((e) => LiveMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingMatches: (json['upcomingMatches'] as List? ?? [])
          .map((e) => UpcomingMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      trendingPlayers: (json['trendingPlayers'] as List? ?? [])
          .map((e) => TrendingPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      latestTournaments: (json['latestTournaments'] as List? ?? [])
          .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
          .toList(),
      quickStats: QuickStats.fromJson(json['quickStats'] as Map<String, dynamic>? ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
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
    return QuickStats(
      totalMatches: json['totalMatches'] ?? 0,
      totalTournaments: json['totalTournaments'] ?? 0,
      totalTeams: json['totalTeams'] ?? 0,
      totalPlayers: json['totalPlayers'] ?? 0,
      todayMatches: json['todayMatches'] ?? 0,
      weekMatches: json['weekMatches'] ?? 0,
      activeTournaments: json['activeTournaments'] ?? 0,
      liveMatches: json['liveMatches'] ?? 0,
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

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      logo: json['logo'],
    );
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

// ==================== Tournament Model ====================
class Tournament {
  final String id;
  final String name;
  final String format;
  final String type;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final Venue venue;
  final int totalTeams;
  final int entryFee;
  final String? logo;

  Tournament({
    required this.id,
    required this.name,
    required this.format,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.venue,
    required this.totalTeams,
    required this.entryFee,
    this.logo,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    try {
      return Tournament(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        format: json['format']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
        venue: Venue.fromJson(Map<String, dynamic>.from(json['venue'] ?? {})),
        totalTeams: int.tryParse(json['totalTeams']?.toString() ?? '0') ?? 0,
        entryFee: int.tryParse(json['entryFee']?.toString() ?? '0') ?? 0,
        logo: json['logo']?.toString(),
      );
    } catch (e) {
      debugPrint('⚠️ Dashboard Tournament.fromJson fallback: $e');
      return Tournament(
        id: '',
        name: 'Unknown',
        format: 'T20',
        type: 'LEAGUE',
        status: 'UPCOMING',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        venue: Venue(name: '', city: '', country: ''),
        totalTeams: 0,
        entryFee: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'format': format,
      'type': type,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'venue': venue.toJson(),
      'totalTeams': totalTeams,
      'entryFee': entryFee,
      'logo': logo,
    };
  }
}

// ==================== Venue Model ====================
class Venue {
  final String name;
  final String city;
  final String country;

  Venue({
    required this.name,
    required this.city,
    required this.country,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': city,
      'country': country,
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
  });

  factory LiveMatch.fromJson(Map<String, dynamic> json) {
    return LiveMatch(
      id: json['id'] ?? '',
      team1: Team.fromJson(json['team1'] ?? {}),
      team2: Team.fromJson(json['team2'] ?? {}),
      status: json['status'] ?? '',
      format: json['format'] ?? '',
      scheduledDate: DateTime.tryParse(json['scheduledDate'] ?? '') ?? DateTime.now(),
      tournament: Tournament.fromJson(json['tournament'] ?? {}),
      innings: json['innings'],
      scoreString: json['scoreString'],
      team1Score: json['team1Score'],
      team2Score: json['team2Score'],
    );
  }

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
    };
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

  factory UpcomingMatch.fromJson(Map<String, dynamic> json) {
    return UpcomingMatch(
      id: json['id'] ?? '',
      team1: Team.fromJson(json['team1'] ?? {}),
      team2: Team.fromJson(json['team2'] ?? {}),
      format: json['format'] ?? '',
      scheduledDate: DateTime.tryParse(json['scheduledDate'] ?? '') ?? DateTime.now(),
      tournament: Tournament.fromJson(json['tournament'] ?? {}),
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

  factory TrendingPlayer.fromJson(Map<String, dynamic> json) {
    return TrendingPlayer(
      rank: json['rank'] ?? 0,
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      jerseyNumber: json['jerseyNumber'] ?? 0,
      role: json['role'] ?? '',
      team: Team.fromJson(json['team'] ?? {}),
      stats: PlayerStats.fromJson(json['stats'] ?? {}),
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

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      runs: json['runs'] ?? 0,
      wickets: json['wickets'] ?? 0,
      matches: json['matches'] ?? 0,
      average: (json['average'] ?? 0).toDouble(),
      strikeRate: (json['strikeRate'] ?? 0).toDouble(),
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