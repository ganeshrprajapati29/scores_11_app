import 'package:equatable/equatable.dart';

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
    return Tournament(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'],
      description: json['description'],
      logo: json['logo'],
      banner: json['banner'],
      organizer: json['organizer'] is String ? json['organizer'] : json['organizer']?['_id'] ?? '',
      format: json['format'] ?? 'T20',
      type: json['type'] ?? 'LEAGUE',
      status: json['status'] ?? 'UPCOMING',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      venue: json['venue'],
      totalTeams: json['totalTeams'] ?? 0,
      totalMatches: json['totalMatches'] ?? 0,
      overs: json['overs'] ?? 20,
      isPaid: json['isPaid'] ?? false,
      entryFee: json['entryFee']?.toDouble(),
      prizeMoney: json['prizeMoney']?.toDouble(),
      rules: json['rules'],
      teams: json['teams'] != null 
          ? (json['teams'] as List).map((e) => e is String ? e : e['_id'] as String).toList()
          : [],
      matches: json['matches'] != null 
          ? (json['matches'] as List).map((e) => e is String ? e : e['_id'] as String).toList()
          : [],
      stats: json['stats'] != null ? TournamentStats.fromJson(json['stats']) : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
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
