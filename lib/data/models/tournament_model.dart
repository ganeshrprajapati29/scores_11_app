import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class Tournament extends Equatable {
  final String id;
  final String name;
  final String? shortName;
  final String? description;
  final String? logo;
  final String? banner;
  final String organizer;
  final String format;
  final String type;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? venue;
  final String? city;
  final String? state;
  final String? country;
  final int totalTeams;
  final int totalMatches;
  final int overs;
  final bool isPaid;
  final double? entryFee;
  final double? prizeMoney;
  final String? rules;
  final List<String> teams;
  final List<String> matches;
  final TournamentStats? stats;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bannerUrl;
  final String? logoUrl;
  final int? registeredTeams;
  final int? maxTeams;

  const Tournament({
    required this.id,
    required this.name,
    this.shortName,
    this.description,
    this.logo,
    this.banner,
    required this.organizer,
    this.format = 'T20',
    this.type = 'LEAGUE',
    this.status = 'UPCOMING',
    this.startDate,
    this.endDate,
    this.venue,
    this.city,
    this.state,
    this.country,
    this.totalTeams = 0,
    this.totalMatches = 0,
    this.overs = 20,
    this.isPaid = false,
    this.entryFee,
    this.prizeMoney,
    this.rules,
    this.teams = const [],
    this.matches = const [],
    this.stats,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.bannerUrl,
    this.logoUrl,
    this.registeredTeams,
    this.maxTeams,
  });

factory Tournament.fromJson(Map<String, dynamic> json) {
    try {
      // Safe ID extraction
      final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

      // Safe list extraction with filtering
      List<String> safeTeams = [];
      if (json['teams'] is List) {
        final teamsList = json['teams'] as List;
        safeTeams = teamsList
            .where((e) => e != null)
            .map((e) {
              if (e is String) return e;
              if (e is Map) return e['_id']?.toString() ?? e['id']?.toString() ?? '';
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList();
      }

      List<String> safeMatches = [];
      if (json['matches'] is List) {
        final matchesList = json['matches'] as List;
        safeMatches = matchesList
            .where((e) => e != null)
            .map((e) {
              if (e is String) return e;
              if (e is Map) return e['_id']?.toString() ?? e['id']?.toString() ?? '';
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList();
      }

      return Tournament(
        id: id,
        name: json['name']?.toString() ?? '',
        shortName: json['shortName']?.toString(),
        description: json['description']?.toString(),
        logo: json['logo']?.toString(),
        banner: json['banner']?.toString(),
        organizer: _safeString(json['organizer']),
        format: json['format']?.toString() ?? 'T20',
        type: json['type']?.toString() ?? 'LEAGUE',
        status: json['status']?.toString() ?? 'UPCOMING',
        startDate: _safeDateTime(json['startDate']),
        endDate: _safeDateTime(json['endDate']),
        venue: json['venue']?['name']?.toString() ?? json['venue']?.toString() ?? '',
        city: json['venue']?['city']?.toString(),
        state: json['venue']?['state']?.toString(),
        country: json['venue']?['country']?.toString(),
        totalTeams: int.tryParse(json['maxTeams']?.toString() ?? '0') ?? 
                     int.tryParse(json['totalTeams']?.toString() ?? '0') ?? 
                     safeTeams.length,
        totalMatches: int.tryParse(json['totalMatches']?.toString() ?? '0') ?? 0,
        overs: int.tryParse(json['overs']?.toString() ?? '20') ?? 20,
        isPaid: (double.tryParse(json['entryFee']?.toString() ?? '0') ?? 0) > 0,
        entryFee: double.tryParse(json['entryFee']?.toString() ?? '0'),
        prizeMoney: double.tryParse(json['prizeMoney']?.toString() ?? '0'),
        rules: json['rules']?.toString(),
        teams: safeTeams,
        matches: safeMatches,
        stats: json['stats'] != null ? TournamentStats.fromJson(json['stats']) : null,
        isActive: json['isActive']?.toString() == 'true' || (json['isActive'] ?? true) == true,
        createdAt: _safeDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _safeDateTime(json['updatedAt']) ?? DateTime.now(),
        bannerUrl: json['bannerUrl']?.toString(),
        logoUrl: json['logoUrl']?.toString(),
        registeredTeams: int.tryParse(json['registeredTeams']?.toString() ?? '0'),
        maxTeams: int.tryParse(json['maxTeams']?.toString() ?? '0'),
      );
    } catch (e) {
      debugPrint('❌ Tournament.fromJson failed for json keys: ${json.keys.toList()}: $e');
      // Fallback to minimal valid Tournament
      return Tournament(
        id: '',
        name: 'Unknown Tournament',
        organizer: 'Unknown',
        format: 'T20',
        type: 'LEAGUE',
        status: 'UPCOMING',
        totalTeams: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        teams: [],
        matches: [],
      );
    }
  }

  static String _safeString(dynamic value) {
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString() ?? value['id']?.toString() ?? value.toString();
    return value?.toString() ?? '';
  }

  static DateTime? _safeDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'description': description,
      'logo': logo,
      'banner': banner,
      'organizer': organizer,
      'format': format,
      'type': type,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'venue': venue,
      'totalTeams': totalTeams,
      'totalMatches': totalMatches,
      'overs': overs,
      'isPaid': isPaid,
      'entryFee': entryFee,
      'prizeMoney': prizeMoney,
      'rules': rules,
      'teams': teams,
      'matches': matches,
      'stats': stats?.toJson(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isLive => status == 'LIVE';
  bool get isUpcoming => status == 'UPCOMING';
  bool get isCompleted => status == 'COMPLETED';

@override
  List<Object?> get props => [
        id,
        name,
        shortName,
        description,
        logo,
        banner,
        organizer,
        format,
        type,
        status,
        startDate,
        endDate,
        venue,
        city,
        state,
        country,
        totalTeams,
        totalMatches,
        overs,
        isPaid,
        entryFee,
        prizeMoney,
        rules,
        teams,
        matches,
        stats,
        isActive,
        createdAt,
        updatedAt,
        bannerUrl,
        logoUrl,
        registeredTeams,
        maxTeams,
      ];
}

class TournamentStats extends Equatable {
  final int totalMatchesPlayed;
  final int totalRuns;
  final int totalWickets;
  final int highestScore;
  final int lowestScore;

  const TournamentStats({
    this.totalMatchesPlayed = 0,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.highestScore = 0,
    this.lowestScore = 0,
  });

  factory TournamentStats.fromJson(Map<String, dynamic> json) {
    return TournamentStats(
      totalMatchesPlayed: json['totalMatchesPlayed'] ?? 0,
      totalRuns: json['totalRuns'] ?? 0,
      totalWickets: json['totalWickets'] ?? 0,
      highestScore: json['highestScore'] ?? 0,
      lowestScore: json['lowestScore'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMatchesPlayed': totalMatchesPlayed,
      'totalRuns': totalRuns,
      'totalWickets': totalWickets,
      'highestScore': highestScore,
      'lowestScore': lowestScore,
    };
  }

  @override
  List<Object?> get props => [totalMatchesPlayed, totalRuns, totalWickets, highestScore, lowestScore];
}

class PointsTable extends Equatable {
  final String id;
  final String tournament;
  final String team;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int matchesTied;
  final int points;
  final double netRunRate;
  final int runsFor;
  final int oversFor;
  final int runsAgainst;
  final int oversAgainst;
  final int position;

  const PointsTable({
    required this.id,
    required this.tournament,
    required this.team,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.matchesTied = 0,
    this.points = 0,
    this.netRunRate = 0.0,
    this.runsFor = 0,
    this.oversFor = 0,
    this.runsAgainst = 0,
    this.oversAgainst = 0,
    this.position = 0,
  });

  factory PointsTable.fromJson(Map<String, dynamic> json) {
    return PointsTable(
      id: json['_id'] ?? json['id'] ?? '',
      tournament: json['tournament'] is String ? json['tournament'] : json['tournament']?['_id'] ?? '',
      team: json['team'] is String ? json['team'] : json['team']?['_id'] ?? '',
      matchesPlayed: json['matchesPlayed'] ?? 0,
      matchesWon: json['matchesWon'] ?? 0,
      matchesLost: json['matchesLost'] ?? 0,
      matchesTied: json['matchesTied'] ?? 0,
      points: json['points'] ?? 0,
      netRunRate: (json['netRunRate'] ?? 0).toDouble(),
      runsFor: json['runsFor'] ?? 0,
      oversFor: json['oversFor'] ?? 0,
      runsAgainst: json['runsAgainst'] ?? 0,
      oversAgainst: json['oversAgainst'] ?? 0,
      position: json['position'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournament,
        team,
        matchesPlayed,
        matchesWon,
        matchesLost,
        matchesTied,
        points,
        netRunRate,
        runsFor,
        oversFor,
        runsAgainst,
        oversAgainst,
        position,
      ];
}
