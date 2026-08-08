import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id;
  final String? userId;
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
    this.userId,
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
    // FIXED: Handle null/undefined safely
    final teamValue = json['team'];
    final String? teamId;
    if (teamValue == null) {
      teamId = null;
    } else if (teamValue is String) {
      teamId = teamValue;
    } else if (teamValue is Map<String, dynamic>) {
      teamId = (teamValue['_id'] ?? teamValue['id'])?.toString();
    } else if (teamValue is Map) {
      teamId = (teamValue['_id'] ?? teamValue['id'])?.toString();
    } else {
      teamId = null;
    }
    
    final teamNameValue = json['team'];
    final String? teamLabel;
    if (teamNameValue is Map) {
      teamLabel = teamNameValue['name']?.toString() ?? teamNameValue['shortName']?.toString();
    } else {
      teamLabel = json['teamName']?.toString();
    }
    
    final cricketProfile = json['cricketProfile'] is Map<String, dynamic>
        ? json['cricketProfile'] as Map<String, dynamic>
        : json['cricketProfile'] is Map
            ? Map<String, dynamic>.from(json['cricketProfile'] as Map)
            : <String, dynamic>{};
    final avatar = json['avatar'] is Map<String, dynamic>
        ? json['avatar'] as Map<String, dynamic>
        : json['avatar'] is Map
            ? Map<String, dynamic>.from(json['avatar'] as Map)
            : <String, dynamic>{};
    final profileImageValue = json['profileImage'];
    final profileImageUrl = profileImageValue is Map
        ? profileImageValue['url']?.toString()
        : profileImageValue?.toString();
    final playerId = cricketProfile['playerId']?.toString();
    final userValue = json['user'];
    final String? userId;
    if (userValue is String && userValue.isNotEmpty) {
      userId = userValue;
    } else if (userValue is Map) {
      final id = userValue['_id'] ?? userValue['id'];
      userId = id?.toString();
    } else {
      userId = null;
    }

    final userMap = userValue is Map ? userValue : const <String, dynamic>{};

    return Player(
      id: playerId?.isNotEmpty == true ? playerId! : (json['_id'] ?? json['id'] ?? '').toString(),
      userId: userId,
      name: (json['playerName'] ??
              userMap['name'] ??
              userMap['fullName'] ??
              json['fullName'] ??
              json['name'] ??
              '')
          .toString(),
      email: json['email']?.toString() ?? userMap['email']?.toString(),
      phone: json['phone']?.toString() ?? userMap['phone']?.toString(),
      photo: json['photo']?.toString() ?? avatar['url']?.toString(),
      profileImage: profileImageUrl ?? avatar['url']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      nationality: json['nationality']?.toString() ?? json['country']?.toString(),
      role: json['role'] == 'player'
          ? cricketProfile['playerType']?.toString()
          : json['role']?.toString(),
      battingStyle: json['battingStyle']?.toString() ?? cricketProfile['battingStyle']?.toString(),
      bowlingStyle: json['bowlingStyle']?.toString() ?? cricketProfile['bowlingStyle']?.toString(),
      playerRole: json['playerRole']?.toString() ?? cricketProfile['playerType']?.toString(),
      jerseyNumber: _toNullableInt(json['jerseyNumber']) ?? 0,
      team: teamId,
      teamName: teamLabel,
      country: json['country']?.toString(),
      stats: json['stats'] is Map
          ? PlayerStats.fromJson(Map<String, dynamic>.from(json['stats'] as Map))
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
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
  final int bowlingInnings;
  final double bowlingOvers;
  final int runsConceded;

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
    this.bowlingInnings = 0,
    this.bowlingOvers = 0.0,
    this.runsConceded = 0,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
      return PlayerStats(
      matches: _toInt(json['matches']),
      innings: _toInt(json['innings']),
      runs: _toInt(json['runs']),
      highestScore: _toInt(json['highestScore']),
      average: _toDouble(json['average']),
      strikeRate: _toDouble(json['strikeRate']),
      hundreds: _toInt(json['hundreds']),
      fifties: _toInt(json['fifties']),
      fours: _toInt(json['fours']),
      sixes: _toInt(json['sixes']),
      wickets: _toInt(json['wickets']),
      economy: _toDouble(json['economy']),
      bestBowlingRuns: _toInt(json['bestBowlingRuns']),
      bestBowlingWickets: _toInt(json['bestBowlingWickets']),
      bowlingInnings: _toInt(json['bowlingInnings']),
      bowlingOvers: _toDouble(json['bowlingOvers']),
      runsConceded: _toInt(json['runsConceded']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
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
      'bowlingInnings': bowlingInnings,
      'bowlingOvers': bowlingOvers,
      'runsConceded': runsConceded,
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
        bowlingInnings,
        bowlingOvers,
        runsConceded,
      ];
}
