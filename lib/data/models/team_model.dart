import 'package:equatable/equatable.dart';
import 'player_model.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final String? shortName;
  final Logo? logo;
  final String owner;
  final String? captain;
  final String? viceCaptain;
  final String? coach;
  final String? homeGround;
  final String? city;
  final String? state;
  final String? country;
  final String? description;
  final List<String> players;
  final TeamStats? stats;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Team({
    required this.id,
    required this.name,
    this.shortName,
    this.logo,
    required this.owner,
    this.captain,
    this.viceCaptain,
    this.coach,
    this.homeGround,
    this.city,
    this.state,
    this.country,
    this.description,
    this.players = const [],
    this.stats,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'],
      logo: json['logo'] != null ? Logo.fromJson(json['logo']) : null,
      owner: json['owner'] is String ? json['owner'] : (json['owner']?['_id'] ?? ''),
      captain: json['captain'] is String ? json['captain'] : json['captain']?['_id'],
      viceCaptain: json['viceCaptain'] is String ? json['viceCaptain'] : json['viceCaptain']?['_id'],
      coach: json['coach'],
      homeGround: json['homeGround'],
      city: json['city'],
      state: json['state'],
      country: json['country'] ?? 'India',
      description: json['description'],
      players: json['players'] != null 
          ? (json['players'] as List).map((e) => e is String ? e : e['_id']).toList()
          : [],
      stats: json['stats'] != null ? TeamStats.fromJson(json['stats']) : null,
      isActive: json['isActive'] ?? true,
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'logo': logo?.toJson(),
      'owner': owner,
      'captain': captain,
      'viceCaptain': viceCaptain,
      'coach': coach,
      'homeGround': homeGround,
      'city': city,
      'state': state,
      'country': country,
      'description': description,
      'players': players,
      'stats': stats?.toJson(),
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? shortName,
    Logo? logo,
    String? owner,
    String? captain,
    String? viceCaptain,
    String? coach,
    String? homeGround,
    String? city,
    String? state,
    String? country,
    String? description,
    List<String>? players,
    TeamStats? stats,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logo: logo ?? this.logo,
      owner: owner ?? this.owner,
      captain: captain ?? this.captain,
      viceCaptain: viceCaptain ?? this.viceCaptain,
      coach: coach ?? this.coach,
      homeGround: homeGround ?? this.homeGround,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      description: description ?? this.description,
      players: players ?? this.players,
      stats: stats ?? this.stats,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        shortName,
        logo,
        owner,
        captain,
        viceCaptain,
        coach,
        homeGround,
        city,
        state,
        country,
        description,
        players,
        stats,
        isActive,
        isVerified,
        createdAt,
        updatedAt,
      ];
}

class Logo extends Equatable {
  final String? publicId;
  final String? url;

  const Logo({this.publicId, this.url});

  factory Logo.fromJson(Map<String, dynamic> json) {
    return Logo(
      publicId: json['publicId'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'url': url,
    };
  }

  @override
  List<Object?> get props => [publicId, url];
}

class TeamStats extends Equatable {
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int matchesTied;
  final int totalRuns;
  final int totalWickets;

  const TeamStats({
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.matchesTied = 0,
    this.totalRuns = 0,
    this.totalWickets = 0,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    return TeamStats(
      matchesPlayed: json['matchesPlayed'] ?? 0,
      matchesWon: json['matchesWon'] ?? 0,
      matchesLost: json['matchesLost'] ?? 0,
      matchesTied: json['matchesTied'] ?? 0,
      totalRuns: json['totalRuns'] ?? 0,
      totalWickets: json['totalWickets'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      'matchesLost': matchesLost,
      'matchesTied': matchesTied,
      'totalRuns': totalRuns,
      'totalWickets': totalWickets,
    };
  }

  double get winPercentage {
    if (matchesPlayed == 0) return 0;
    return (matchesWon / matchesPlayed) * 100;
  }

  @override
  List<Object?> get props => [
        matchesPlayed,
        matchesWon,
        matchesLost,
        matchesTied,
        totalRuns,
        totalWickets,
      ];
}
