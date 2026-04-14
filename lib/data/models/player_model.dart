import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? photo;
  final String? profileImage;
  final String? dateOfBirth;
  final String? gender;
  final String? nationality;
  final String? role;
  final String? battingStyle;
  final String? bowlingStyle;
  final String? playerRole;
  final int? jerseyNumber;
  final String? team;
  final String? teamName;
  final String? country;
  final PlayerStats? stats;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Player({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.photo,
    this.profileImage,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.role,
    this.battingStyle,
    this.bowlingStyle,
    this.playerRole,
    this.jerseyNumber,
    this.team,
    this.teamName,
    this.country,
    this.stats,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['_id'] ?? json['id'] ?? '',
name: json['playerName'] ?? json['user']?['name'] ?? json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      photo: json['photo'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      nationality: json['nationality'],
      role: json['role'],
      battingStyle: json['battingStyle'],
      bowlingStyle: json['bowlingStyle'],
      playerRole: json['playerRole'],
      jerseyNumber: (json['jerseyNumber'] as num?)?.toInt() ?? 0,
team: json['team'] is String ? json['team'] : json['team']?['_id'],
      teamName: json['team']?['name'] ?? json['team']?['shortName'] ?? json['teamName'],
      country: json['country'],
      stats: json['stats'] != null ? PlayerStats.fromJson(json['stats']) : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'nationality': nationality,
      'role': role,
      'battingStyle': battingStyle,
      'bowlingStyle': bowlingStyle,
      'playerRole': playerRole,
      'jerseyNumber': jerseyNumber,
      'team': team,
      'country': country,
      'stats': stats?.toJson(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        photo,
        dateOfBirth,
        gender,
        nationality,
        role,
        battingStyle,
        bowlingStyle,
        playerRole,
        jerseyNumber,
        team,
        country,
        stats,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class PlayerStats extends Equatable {
  final int matches;
  final int innings;
  final int runs;
  final int highestScore;
  final double average;
  final double strikeRate;
  final int hundreds;
  final int fifties;
  final int fours;
  final int sixes;
  final int wickets;
  final double economy;
  final int bestBowlingRuns;
  final int bestBowlingWickets;

  const PlayerStats({
    this.matches = 0,
    this.innings = 0,
    this.runs = 0,
    this.highestScore = 0,
    this.average = 0.0,
    this.strikeRate = 0.0,
    this.hundreds = 0,
    this.fifties = 0,
    this.fours = 0,
    this.sixes = 0,
    this.wickets = 0,
    this.economy = 0.0,
    this.bestBowlingRuns = 0,
    this.bestBowlingWickets = 0,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
      return PlayerStats(
      matches: (json['matches'] as num?)?.toInt() ?? 0,
      innings: (json['innings'] as num?)?.toInt() ?? 0,
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      highestScore: (json['highestScore'] as num?)?.toInt() ?? 0,
      average: (json['average'] ?? 0).toDouble(),
      strikeRate: (json['strikeRate'] ?? 0).toDouble(),
      hundreds: (json['hundreds'] as num?)?.toInt() ?? 0,
      fifties: (json['fifties'] as num?)?.toInt() ?? 0,
      fours: (json['fours'] as num?)?.toInt() ?? 0,
      sixes: (json['sixes'] as num?)?.toInt() ?? 0,
      wickets: (json['wickets'] as num?)?.toInt() ?? 0,
      economy: (json['economy'] ?? 0).toDouble(),
      bestBowlingRuns: (json['bestBowlingRuns'] as num?)?.toInt() ?? 0,
      bestBowlingWickets: (json['bestBowlingWickets'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matches': matches,
      'innings': innings,
      'runs': runs,
      'highestScore': highestScore,
      'average': average,
      'strikeRate': strikeRate,
      'hundreds': hundreds,
      'fifties': fifties,
      'fours': fours,
      'sixes': sixes,
      'wickets': wickets,
      'economy': economy,
      'bestBowlingRuns': bestBowlingRuns,
      'bestBowlingWickets': bestBowlingWickets,
    };
  }

  @override
  List<Object?> get props => [
        matches,
        innings,
        runs,
        highestScore,
        average,
        strikeRate,
        hundreds,
        fifties,
        fours,
        sixes,
        wickets,
        economy,
        bestBowlingRuns,
        bestBowlingWickets,
      ];
}
