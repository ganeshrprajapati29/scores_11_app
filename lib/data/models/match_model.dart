import 'package:equatable/equatable.dart';

class Match extends Equatable {
  final String id;
  final String? tournament;
  final String team1;
  final String team2;
  final int? matchNumber;
  final String format;
  final String matchType;
  final Venue? venue;
  final DateTime scheduledDate;
  final String? startTime;
  final int overs;
  final String status;
  final Toss? toss;
  final List<Innings> innings;
  final int currentInnings;
  final List<BattingOrder> battingOrder;
  final MatchScore score;
  final MatchResult? result;
  final MatchOfficials? officials;
  final Weather? weather;
  final Pitch? pitch;
  final List<Commentary> commentary;
  final Powerplay? powerplay;
  final MatchStats? stats;
  final String? createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic team1Data;
  final dynamic team2Data;

  const Match({
    required this.id,
    this.tournament,
    required this.team1,
    required this.team2,
    this.matchNumber,
    this.format = 'T20',
    this.matchType = 'LEAGUE',
    this.venue,
    required this.scheduledDate,
    this.startTime,
    this.overs = 20,
    this.status = 'SCHEDULED',
    this.toss,
    this.innings = const [],
    this.currentInnings = 1,
    this.battingOrder = const [],
    required this.score,
    this.result,
    this.officials,
    this.weather,
    this.pitch,
    this.commentary = const [],
    this.powerplay,
    this.stats,
    this.createdBy,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.team1Data,
    this.team2Data,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['_id'] ?? json['id'] ?? '',
      tournament: json['tournament'] is String 
          ? json['tournament'] 
          : json['tournament']?['_id'],
      team1: json['team1'] is String ? json['team1'] : json['team1']?['name'] ?? json['team1']?['_id'] ?? '',
      team2: json['team2'] is String ? json['team2'] : json['team2']?['name'] ?? json['team2']?['_id'] ?? '',
      matchNumber: json['matchNumber'],
      format: json['format'] ?? 'T20',
      matchType: json['matchType'] ?? 'LEAGUE',
      venue: json['venue'] != null ? Venue.fromJson(json['venue']) : null,
      scheduledDate: json['scheduledDate'] != null 
          ? DateTime.parse(json['scheduledDate']) 
          : DateTime.now(),
      startTime: json['startTime'],
      overs: json['overs'] ?? 20,
      status: json['status'] ?? 'SCHEDULED',
      toss: _parseToss(json),
      innings: json['innings'] != null 
          ? (json['innings'] as List).map((e) => Innings.fromJson(e)).toList()
          : [],
      currentInnings: int.tryParse(
            (json['currentInnings'] ??
                    json['currentInningsScore']?['inningsNumber'] ??
                    json['inningsNumber'] ??
                    1)
                .toString(),
          ) ??
          1,
      battingOrder: json['battingOrder'] != null 
          ? (json['battingOrder'] as List).map((e) => BattingOrder.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      score: json['score'] is Map
          ? MatchScore.fromJson(Map<String, dynamic>.from(json['score'] as Map))
          : MatchScore.fromJson(json),
      result: json['result'] is Map
          ? MatchResult.fromJson(Map<String, dynamic>.from(json['result'] as Map))
          : MatchResult.fromJson(json),
      officials: json['officials'] != null ? MatchOfficials.fromJson(json['officials']) : null,
      weather: json['weather'] != null ? Weather.fromJson(json['weather']) : null,
      pitch: json['pitch'] != null ? Pitch.fromJson(json['pitch']) : null,
      commentary: json['commentary'] != null 
          ? (json['commentary'] as List).map((e) => Commentary.fromJson(e)).toList()
          : [],
      powerplay: json['powerplay'] != null ? Powerplay.fromJson(json['powerplay']) : null,
      stats: json['stats'] != null ? MatchStats.fromJson(json['stats']) : null,
      createdBy: json['createdBy'] is String ? json['createdBy'] : json['createdBy']?['_id'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      team1Data: json['team1Data'] ?? (json['team1'] is Map ? json['team1'] : null),
      team2Data: json['team2Data'] ?? (json['team2'] is Map ? json['team2'] : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tournament': tournament,
      'team1': team1,
      'team2': team2,
      'matchNumber': matchNumber,
      'format': format,
      'matchType': matchType,
      'venue': venue?.toJson(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'startTime': startTime,
      'overs': overs,
      'status': status,
      'toss': toss?.toJson(),
      'innings': innings.map((e) => e.toJson()).toList(),
      'currentInnings': currentInnings,
      'battingOrder': battingOrder.map((e) => e.toJson()).toList(),
      'score': score.toJson(),
      'result': result?.toJson(),
      'officials': officials?.toJson(),
      'weather': weather?.toJson(),
      'pitch': pitch?.toJson(),
      'commentary': commentary.map((e) => e.toJson()).toList(),
      'powerplay': powerplay?.toJson(),
      'stats': stats?.toJson(),
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'team1Data': team1Data,
      'team2Data': team2Data,
    };
  }

  static Toss? _parseToss(Map<String, dynamic> json) {
    Toss? parsedToss;
    if (json['toss'] is Map<String, dynamic>) {
      parsedToss = Toss.fromJson(json['toss'] as Map<String, dynamic>);
    } else if (json['toss'] is Map) {
      parsedToss = Toss.fromJson(Map<String, dynamic>.from(json['toss'] as Map));
    }

    final winner = json['tossWinner'] ??
        json['tossWinnerId'] ??
        json['toss_winner'] ??
        json['tossWinnerTeam'] ??
        json['tossWinnerTeamId'];
    final decision = json['tossDecision'] ??
        json['toss_decision'] ??
        json['decision'] ??
        json['tossChoice'];

    final parsedWinner = parsedToss?.winner;
    final parsedDecision = parsedToss?.decision;
    if (parsedWinner == null &&
        parsedDecision == null &&
        winner == null &&
        decision == null) {
      return null;
    }

    return Toss(
      winner: _readTossValue(parsedWinner ?? winner),
      decision: _readTossValue(parsedDecision ?? decision),
      decidedAt: parsedToss?.decidedAt,
    );
  }

  static String? _readTossValue(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return (value['shortName'] ??
              value['name'] ??
              value['teamName'] ??
              value['_id'] ??
              value['id'] ??
              value['value'])
          ?.toString();
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String get normalizedStatus => status.toLowerCase();
  bool get isLive => normalizedStatus == 'live';
  bool get isCompleted => normalizedStatus == 'completed';
  bool get isScheduled => normalizedStatus == 'scheduled';
  bool get isUpcoming => normalizedStatus == 'upcoming' || normalizedStatus == 'scheduled';
  bool get isTeamSelecting => normalizedStatus == 'team_selecting';
  bool get isReady => normalizedStatus == 'ready';
  String get team1Id => team1Data is Map ? (team1Data['_id'] ?? team1Data['id'] ?? team1).toString() : team1;
  String get team2Id => team2Data is Map ? (team2Data['_id'] ?? team2Data['id'] ?? team2).toString() : team2;

  String get team1ScoreDisplay {
    return '${score.team1.runs}/${score.team1.wickets} (${score.team1.overs})';
  }

  String get team2ScoreDisplay {
    return '${score.team2.runs}/${score.team2.wickets} (${score.team2.overs})';
  }

  @override
  List<Object?> get props => [
    id, tournament, team1, team2, matchNumber, format, matchType, venue,
    scheduledDate, startTime, overs, status, toss, innings, currentInnings,
    battingOrder, score, result, officials, weather, pitch, commentary,
    powerplay, stats, createdBy, isActive, createdAt, updatedAt,
  ];
}

// [Rest of all classes unchanged - Venue, Toss, Innings, Extras, BattingOrder, MatchScore, TeamScore, MatchResult, MatchOfficials, Weather, Pitch, Commentary, Powerplay, PowerplayInnings, MatchStats, HighestScore, BestBowling, HighestPartnership, MostSixes, MostFours remain exactly the same as original]
class Venue extends Equatable {
  final String name;
  final String? city;
  final String? state;
  final String? country;

  const Venue({required this.name, this.city, this.state, this.country});

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      name: json['name'] ?? '',
      city: json['city'],
      state: json['state'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': city,
      'state': state,
      'country': country,
    };
  }

  @override
  List<Object?> get props => [name, city, state, country];
}

class Toss extends Equatable {
  final String? winner;
  final String? decision;
  final DateTime? decidedAt;

  const Toss({this.winner, this.decision, this.decidedAt});

  factory Toss.fromJson(Map<String, dynamic> json) {
    return Toss(
      winner: _readValue(
        json['winner'] ??
            json['tossWinner'] ??
            json['tossWinnerId'] ??
            json['team'] ??
            json['winningTeam'],
      ),
      decision: _readValue(
        json['decision'] ??
            json['tossDecision'] ??
            json['toss_decision'] ??
            json['choice'],
      ),
      decidedAt: DateTime.tryParse(json['decidedAt']?.toString() ?? ''),
    );
  }

  static String? _readValue(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return (value['shortName'] ??
              value['name'] ??
              value['teamName'] ??
              value['_id'] ??
              value['id'] ??
              value['value'])
          ?.toString();
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toJson() {
    return {
      'winner': winner,
      'decision': decision,
      'decidedAt': decidedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [winner, decision, decidedAt];
}

class Innings extends Equatable {
  final int inningsNumber;
  final String? battingTeam;
  final String? bowlingTeam;
  final int totalRuns;
  final int totalWickets;
  final double totalOvers;
  final int totalBalls;
  final Extras extras;
  final bool isCompleted;

  const Innings({
    this.inningsNumber = 1,
    this.battingTeam,
    this.bowlingTeam,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalOvers = 0.0,
    this.totalBalls = 0,
    this.extras = const Extras(),
    this.isCompleted = false,
  });

  factory Innings.fromJson(Map<String, dynamic> json) {
    return Innings(
      inningsNumber: json['inningsNumber'] ?? 1,
      battingTeam: json['battingTeam'] is String ? json['battingTeam'] : json['battingTeam']?['name'],
      bowlingTeam: json['bowlingTeam'] is String ? json['bowlingTeam'] : json['bowlingTeam']?['name'],
      totalRuns: json['totalRuns'] ?? 0,
      totalWickets: json['totalWickets'] ?? 0,
      totalOvers: (json['totalOvers'] ?? 0).toDouble(),
      totalBalls: json['totalBalls'] ?? 0,
      extras: json['extras'] != null ? Extras.fromJson(json['extras']) : const Extras(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inningsNumber': inningsNumber,
      'battingTeam': battingTeam,
      'bowlingTeam': bowlingTeam,
      'totalRuns': totalRuns,
      'totalWickets': totalWickets,
      'totalOvers': totalOvers,
      'totalBalls': totalBalls,
      'extras': extras.toJson(),
      'isCompleted': isCompleted,
    };
  }

  String get oversDisplay {
    final overs = totalBalls ~/ 6;
    final balls = totalBalls % 6;
    return '$overs.$balls';
  }

  double get runRate {
    if (totalBalls == 0) return 0.0;
    return (totalRuns / totalBalls) * 6;
  }

  @override
  List<Object?> get props => [
    inningsNumber, battingTeam, bowlingTeam, totalRuns, totalWickets,
    totalOvers, totalBalls, extras, isCompleted,
  ];
}

class Extras extends Equatable {
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final int penalty;
  final int total;

  const Extras({
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.penalty = 0,
    this.total = 0,
  });

  factory Extras.fromJson(Map<String, dynamic> json) {
    final w = json['wides'] ?? 0;
    final nb = json['noBalls'] ?? 0;
    final b = json['byes'] ?? 0;
    final lb = json['legByes'] ?? 0;
    final p = json['penalty'] ?? 0;
    return Extras(
      wides: w,
      noBalls: nb,
      byes: b,
      legByes: lb,
      penalty: p,
      total: w + nb + b + lb + p,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wides': wides,
      'noBalls': noBalls,
      'byes': byes,
      'legByes': legByes,
      'penalty': penalty,
      'total': total,
    };
  }

  @override
  List<Object?> get props => [wides, noBalls, byes, legByes, penalty, total];
}

class BattingOrder extends Equatable {
  final String? team;
  final List<String> players;

  const BattingOrder({this.team, this.players = const []});

  factory BattingOrder.fromJson(Map<String, dynamic> json) {
    return BattingOrder(
      team: json['team'] is String ? json['team'] : json['team']?['_id'],
      players: json['players'] != null 
          ? (json['players'] as List).map((e) => e is String ? e : e['_id'] as String).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team': team,
      'players': players,
    };
  }

  @override
  List<Object?> get props => [team, players];
}

class MatchScore extends Equatable {
  final TeamScore team1;
  final TeamScore team2;

  const MatchScore({required this.team1, required this.team2});

  factory MatchScore.fromJson(Map<String, dynamic> json) {
    final team1Json = _scoreMap(
      json['team1'],
      runs: json['team1Score'] ?? json['team1Runs'] ?? json['team1TotalRuns'],
      wickets: json['team1Wickets'] ?? json['team1TotalWickets'],
      overs: json['team1Overs'] ?? json['team1TotalOvers'],
    );
    final team2Json = _scoreMap(
      json['team2'],
      runs: json['team2Score'] ?? json['team2Runs'] ?? json['team2TotalRuns'],
      wickets: json['team2Wickets'] ?? json['team2TotalWickets'],
      overs: json['team2Overs'] ?? json['team2TotalOvers'],
    );
    return MatchScore(
      team1: TeamScore.fromJson(team1Json),
      team2: TeamScore.fromJson(team2Json),
    );
  }

  static Map<String, dynamic> _scoreMap(
    dynamic value, {
    dynamic runs,
    dynamic wickets,
    dynamic overs,
  }) {
    final map = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    if (runs != null) map['runs'] = runs;
    if (wickets != null) map['wickets'] = wickets;
    if (overs != null) map['overs'] = overs;
    return map;
  }

  factory MatchScore.empty() {
    return const MatchScore(
      team1: TeamScore(),
      team2: TeamScore(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team1': team1.toJson(),
      'team2': team2.toJson(),
    };
  }

  @override
  List<Object?> get props => [team1, team2];
}

class TeamScore extends Equatable {
  final int runs;
  final int wickets;
  final String overs;
  final int innings;

  const TeamScore({
    this.runs = 0,
    this.wickets = 0,
    this.overs = '0.0',
    this.innings = 1,
  });

  factory TeamScore.fromJson(Map<String, dynamic> json) {
    return TeamScore(
      runs: int.tryParse(
            (json['runs'] ?? json['totalRuns'] ?? json['score'] ?? 0).toString(),
          ) ??
          0,
      wickets: int.tryParse(
            (json['wickets'] ?? json['wkts'] ?? json['totalWickets'] ?? 0).toString(),
          ) ??
          0,
      overs: (json['overs'] ?? json['totalOvers'] ?? json['over'] ?? '0.0').toString(),
      innings: int.tryParse((json['innings'] ?? json['inningsNumber'] ?? 1).toString()) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runs': runs,
      'wickets': wickets,
      'overs': overs,
      'innings': innings,
    };
  }

  double get oversInDecimal {
    if (overs.isEmpty) return 0.0;
    final parts = overs.split('.');
    if (parts.length < 2) return int.tryParse(parts[0])?.toDouble() ?? 0.0;
    final oversInt = int.tryParse(parts[0]) ?? 0;
    final ballsInt = int.tryParse(parts[1]) ?? 0;
    return oversInt + (ballsInt / 6);
  }

  @override
  List<Object?> get props => [runs, wickets, overs, innings];
}

class MatchResult extends Equatable {
  final String? winner;
  final String? margin;
  final String? method;
  final String? message;
  final String? playerOfMatch;
  final int? target;
  final int? requiredRuns;
  final int? requiredBalls;

  const MatchResult({
    this.winner,
    this.margin,
    this.method,
    this.message,
    this.playerOfMatch,
    this.target,
    this.requiredRuns,
    this.requiredBalls,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      winner: _readName(json['winner'] ?? json['winnerTeam'] ?? json['winningTeam']),
      margin: json['margin']?.toString(),
      method: json['method']?.toString(),
      message: json['message']?.toString() ?? json['resultMessage']?.toString(),
      playerOfMatch: _readName(json['playerOfMatch'] ?? json['mom']),
      target: int.tryParse((json['target'] ?? json['targetRuns'] ?? '').toString()),
      requiredRuns: int.tryParse((json['requiredRuns'] ?? json['runsRequired'] ?? '').toString()),
      requiredBalls: int.tryParse((json['requiredBalls'] ?? json['ballsRemaining'] ?? '').toString()),
    );
  }

  static String? _readName(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return (value['shortName'] ??
              value['name'] ??
              value['teamName'] ??
              value['playerName'] ??
              value['_id'] ??
              value['id'])
          ?.toString();
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toJson() {
    return {
      'winner': winner,
      'margin': margin,
      'method': method,
      'message': message,
      'playerOfMatch': playerOfMatch,
      'target': target,
      'requiredRuns': requiredRuns,
      'requiredBalls': requiredBalls,
    };
  }

  @override
  List<Object?> get props => [winner, margin, method, message, playerOfMatch, target, requiredRuns, requiredBalls];
}

class MatchOfficials extends Equatable {
  final String? umpire1;
  final String? umpire2;
  final String? referee;

  const MatchOfficials({this.umpire1, this.umpire2, this.referee});

  factory MatchOfficials.fromJson(Map<String, dynamic> json) {
    return MatchOfficials(
      umpire1: json['umpire1'] is String ? json['umpire1'] : json['umpire1']?['name'],
      umpire2: json['umpire2'] is String ? json['umpire2'] : json['umpire2']?['name'],
      referee: json['referee'] is String ? json['referee'] : json['referee']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'umpire1': umpire1,
      'umpire2': umpire2,
      'referee': referee,
    };
  }

  @override
  List<Object?> get props => [umpire1, umpire2, referee];
}

class Weather extends Equatable {
  final String? condition;
  final int? temperature;
  final int? humidity;

  const Weather({this.condition, this.temperature, this.humidity});

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      condition: json['condition'],
      temperature: json['temperature'],
      humidity: json['humidity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'temperature': temperature,
      'humidity': humidity,
    };
  }

  @override
  List<Object?> get props => [condition, temperature, humidity];
}

class Pitch extends Equatable {
  final String? type;
  final String? batting;
  final bool? dew;

  const Pitch({this.type, this.batting, this.dew});

  factory Pitch.fromJson(Map<String, dynamic> json) {
    return Pitch(
      type: json['type'],
      batting: json['batting'],
      dew: json['dew'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'batting': batting,
      'dew': dew,
    };
  }

  @override
  List<Object?> get props => [type, batting, dew];
}

class Commentary extends Equatable {
  final double over;
  final int ball;
  final String? text;
  final int? batsmanRuns;
  final int? totalRuns;
  final bool? isWicket;
  final DateTime? timestamp;

  const Commentary({
    required this.over,
    required this.ball,
    this.text,
    this.batsmanRuns,
    this.totalRuns,
    this.isWicket,
    this.timestamp,
  });

  factory Commentary.fromJson(Map<String, dynamic> json) {
    return Commentary(
      over: (json['over'] ?? 0).toDouble(),
      ball: json['ball'] ?? 0,
      text: json['text'],
      batsmanRuns: json['batsmanRuns'],
      totalRuns: json['totalRuns'],
      isWicket: json['isWicket'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'over': over,
      'ball': ball,
      'text': text,
      'batsmanRuns': batsmanRuns,
      'totalRuns': totalRuns,
      'isWicket': isWicket,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  String get overDisplay {
    final overInt = over.floor();
    final ballInt = ((over - overInt) * 10).round();
    return '$overInt.$ballInt';
  }

  @override
  List<Object?> get props => [over, ball, text, batsmanRuns, totalRuns, isWicket, timestamp];
}

class Powerplay extends Equatable {
  final PowerplayInnings? firstInnings;
  final PowerplayInnings? secondInnings;

  const Powerplay({this.firstInnings, this.secondInnings});

  factory Powerplay.fromJson(Map<String, dynamic> json) {
    return Powerplay(
      firstInnings: json['firstInnings'] != null ? PowerplayInnings.fromJson(json['firstInnings']) : null,
      secondInnings: json['secondInnings'] != null ? PowerplayInnings.fromJson(json['secondInnings']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstInnings': firstInnings?.toJson(),
      'secondInnings': secondInnings?.toJson(),
    };
  }

  @override
  List<Object?> get props => [firstInnings, secondInnings];
}

class PowerplayInnings extends Equatable {
  final int startOver;
  final int endOver;
  final int runs;
  final int wickets;

  const PowerplayInnings({
    this.startOver = 0,
    this.endOver = 6,
    this.runs = 0,
    this.wickets = 0,
  });

  factory PowerplayInnings.fromJson(Map<String, dynamic> json) {
    return PowerplayInnings(
      startOver: json['startOver'] ?? 0,
      endOver: json['endOver'] ?? 6,
      runs: json['runs'] ?? 0,
      wickets: json['wickets'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startOver': startOver,
      'endOver': endOver,
      'runs': runs,
      'wickets': wickets,
    };
  }

  @override
  List<Object?> get props => [startOver, endOver, runs, wickets];
}

class MatchStats extends Equatable {
  final HighestScore? highestIndividualScore;
  final BestBowling? bestBowling;
  final HighestPartnership? highestPartnership;
  final MostSixes? mostSixes;
  final MostFours? mostFours;

  const MatchStats({
    this.highestIndividualScore,
    this.bestBowling,
    this.highestPartnership,
    this.mostSixes,
    this.mostFours,
  });

  factory MatchStats.fromJson(Map<String, dynamic> json) {
    return MatchStats(
      highestIndividualScore: json['highestIndividualScore'] != null 
          ? HighestScore.fromJson(json['highestIndividualScore']) 
          : null,
      bestBowling: json['bestBowling'] != null ? BestBowling.fromJson(json['bestBowling']) : null,
      highestPartnership: json['highestPartnership'] != null 
          ? HighestPartnership.fromJson(json['highestPartnership']) 
          : null,
      mostSixes: json['mostSixes'] != null ? MostSixes.fromJson(json['mostSixes']) : null,
      mostFours: json['mostFours'] != null ? MostFours.fromJson(json['mostFours']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highestIndividualScore': highestIndividualScore?.toJson(),
      'bestBowling': bestBowling?.toJson(),
      'highestPartnership': highestPartnership?.toJson(),
      'mostSixes': mostSixes?.toJson(),
      'mostFours': mostFours?.toJson(),
    };
  }

  @override
  List<Object?> get props => [highestIndividualScore, bestBowling, highestPartnership, mostSixes, mostFours];
}

class HighestScore extends Equatable {
  final int runs;
  final String? player;

  const HighestScore({required this.runs, this.player});

  factory HighestScore.fromJson(Map<String, dynamic> json) {
    return HighestScore(
      runs: json['runs'] ?? 0,
      player: json['player'] is String ? json['player'] : json['player']?['playerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runs': runs,
      'player': player,
    };
  }

  @override
  List<Object?> get props => [runs, player];
}

class BestBowling extends Equatable {
  final int wickets;
  final int runs;
  final String? player;

  const BestBowling({required this.wickets, required this.runs, this.player});

  factory BestBowling.fromJson(Map<String, dynamic> json) {
    return BestBowling(
      wickets: json['wickets'] ?? 0,
      runs: json['runs'] ?? 0,
      player: json['player'] is String ? json['player'] : json['player']?['playerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wickets': wickets,
      'runs': runs,
      'player': player,
    };
  }

  String get figures => '$wickets/$runs';

  @override
  List<Object?> get props => [wickets, runs, player];
}

class HighestPartnership extends Equatable {
  final int runs;
  final List<String> players;

  const HighestPartnership({required this.runs, this.players = const []});

  factory HighestPartnership.fromJson(Map<String, dynamic> json) {
    return HighestPartnership(
      runs: json['runs'] ?? 0,
      players: json['players'] != null 
          ? (json['players'] as List).map((e) => e is String ? e : e['playerName'] as String).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runs': runs,
      'players': players,
    };
  }

  @override
  List<Object?> get props => [runs, players];
}

class MostSixes extends Equatable {
  final int count;
  final String? player;

  const MostSixes({required this.count, this.player});

  factory MostSixes.fromJson(Map<String, dynamic> json) {
    return MostSixes(
      count: json['count'] ?? 0,
      player: json['player'] is String ? json['player'] : json['player']?['playerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'player': player,
    };
  }

  @override
  List<Object?> get props => [count, player];
}

class MostFours extends Equatable {
  final int count;
  final String? player;

  const MostFours({required this.count, this.player});

  factory MostFours.fromJson(Map<String, dynamic> json) {
    return MostFours(
      count: json['count'] ?? 0,
      player: json['player'] is String ? json['player'] : json['player']?['playerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'player': player,
    };
  }

  @override
  List<Object?> get props => [count, player];
}

