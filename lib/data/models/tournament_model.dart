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

factory Tournament.fromJson(dynamic rawJson) {
    try {
      final json = _safeMap(rawJson);
      // Safe ID extraction
      final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
      final venueMap = _safeMap(json['venue']);
      final logoMap = _safeMap(json['logo']);
      final bannerMap = _safeMap(json['banner']);

      // Safe list extraction with filtering
      List<String> safeTeams = [];
      if (json['teams'] is List) {
        final teamsList = json['teams'] as List;
        safeTeams = teamsList
            .where((e) => e != null)
            .map((e) {
              if (e is String) return e;
              if (e is Map) {
                return e['name']?.toString() ??
                    e['shortName']?.toString() ??
                    e['_id']?.toString() ??
                    e['id']?.toString() ??
                    '';
              }
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
        logo: _mediaUrl(json['logo']),
        banner: _mediaUrl(json['banner']),
        organizer: _displayName(json['organizer']),
        format: (json['format']?.toString() ?? 'T20').toUpperCase(),
        type: (json['type']?.toString() ?? 'LEAGUE').toUpperCase(),
        status: _normalizeStatus(json['status']),
        startDate: _safeDateTime(json['startDate']),
        endDate: _safeDateTime(json['endDate']),
        venue: venueMap['name']?.toString() ?? json['venue']?.toString() ?? '',
        city: venueMap['city']?.toString() ?? json['city']?.toString(),
        state: venueMap['state']?.toString() ?? json['state']?.toString(),
        country: venueMap['country']?.toString() ?? json['country']?.toString(),
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
        bannerUrl: json['bannerUrl']?.toString() ?? bannerMap['url']?.toString(),
        logoUrl: json['logoUrl']?.toString() ?? logoMap['url']?.toString(),
        registeredTeams: int.tryParse(json['registeredTeams']?.toString() ?? '0'),
       
        maxTeams: int.tryParse(json['maxTeams']?.toString() ?? '0'),
      );
    } catch (e) {
      debugPrint('Tournament.fromJson failed: $e');
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

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _normalizeStatus(dynamic value) {
    final status = value?.toString().toLowerCase().trim() ?? '';
    switch (status) {
      case 'live':
      case 'ongoing':
      case 'in_progress':
      case 'in-progress':
      case 'active':
        return 'LIVE';
      case 'published':
      case 'upcoming':
      case 'scheduled':
      case 'draft':
        return 'UPCOMING';
      case 'completed':
      case 'finished':
        return 'COMPLETED';
      case 'cancelled':
      case 'canceled':
        return 'CANCELLED';
      default:
        return status.isEmpty ? 'UPCOMING' : status.toUpperCase();
    }
  }

  String get displayLocation {
    final parts = [venue, city, state, country]
        .where((part) => part != null && part!.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toSet()
        .toList();
    return parts.isEmpty ? 'Venue TBD' : parts.join(', ');
  }

  int get teamsCount => registeredTeams ?? teams.length;
  int get capacityTeams => maxTeams ?? totalTeams;

  static String _safeString(dynamic value) {
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString() ?? value['id']?.toString() ?? value.toString();
    return value?.toString() ?? '';
  }

  static String _displayName(dynamic value) {
    if (value is String) return value;
    if (value is Map) {
      return value['name']?.toString() ??
          value['fullName']?.toString() ??
          value['username']?.toString() ??
          value['email']?.toString() ??
          value['_id']?.toString() ??
          '';
    }
    return value?.toString() ?? '';
  }

  static String? _mediaUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) {
      final url = value['url'] ?? value['secureUrl'] ?? value['path'];
      final text = url?.toString() ?? '';
      return text.isEmpty ? null : text;
    }
    return null;
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

factory TournamentStats.fromJson(dynamic rawJson) {
    final json = rawJson is Map<String, dynamic>
        ? rawJson
        : rawJson is Map
            ? Map<String, dynamic>.from(rawJson)
            : <String, dynamic>{};
    // Safe integer conversion - convert String to int if needed
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return int.tryParse(value.toString()) ?? 0;
    }
    
    return TournamentStats(
      totalMatchesPlayed: safeInt(json['totalMatchesPlayed']),
      totalRuns: safeInt(json['totalRuns']),
      totalWickets: safeInt(json['totalWickets']),
      highestScore: safeInt(json['highestScore']),
      lowestScore: safeInt(json['lowestScore']),
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
    // ✅ FIX: Handle both String and Map types for tournament/team fields
    String safeTournamentId;
    if (json['tournament'] is String) {
      safeTournamentId = json['tournament'] ?? '';
    } else if (json['tournament'] is Map) {
      safeTournamentId = json['tournament']?['_id']?.toString() ?? json['tournament']?['id']?.toString() ?? '';
    } else {
      safeTournamentId = '';
    }

    String safeTeamId;
    if (json['team'] is String) {
      safeTeamId = json['team'] ?? '';
    } else if (json['team'] is Map) {
      safeTeamId = json['team']?['name']?.toString() ??
          json['team']?['shortName']?.toString() ??
          json['team']?['_id']?.toString() ??
          json['team']?['id']?.toString() ??
          '';
    } else {
      safeTeamId = '';
    }

    return PointsTable(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      tournament: safeTournamentId,
      team: safeTeamId,
      matchesPlayed: int.tryParse((json['matchesPlayed'] ?? json['played'])?.toString() ?? '0') ?? 0,
      matchesWon: int.tryParse((json['matchesWon'] ?? json['won'])?.toString() ?? '0') ?? 0,
      matchesLost: int.tryParse((json['matchesLost'] ?? json['lost'])?.toString() ?? '0') ?? 0,
      matchesTied: int.tryParse((json['matchesTied'] ?? json['tied'])?.toString() ?? '0') ?? 0,
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      netRunRate: double.tryParse(json['netRunRate']?.toString() ?? '0') ?? 0.0,
      runsFor: int.tryParse(json['runsFor']?.toString() ?? '0') ?? 0,
      oversFor: int.tryParse(json['oversFor']?.toString() ?? '0') ?? 0,
      runsAgainst: int.tryParse(json['runsAgainst']?.toString() ?? '0') ?? 0,
      oversAgainst: int.tryParse(json['oversAgainst']?.toString() ?? '0') ?? 0,
      position: int.tryParse(json['position']?.toString() ?? '0') ?? 0,
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
