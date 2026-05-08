import 'match_model.dart';
import 'package:equatable/equatable.dart';

/// Detailed batsman stats for scorecard table
class BatsmanStats extends Equatable {
  final String playerId;
  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;
  final String? dismissal;
  final String? bowlerDismissedBy;
  final int? wicketNumber;
  final bool notOut;

  const BatsmanStats({
    required this.playerId,
    required this.playerName,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.strikeRate = 0.0,
    this.dismissal,
    this.bowlerDismissedBy,
    this.wicketNumber,
    this.notOut = false,
  });

factory BatsmanStats.fromJson(Map<String, dynamic> json) {
    final sr = json['balls'] > 0 ? (json['runs'] / json['balls']) * 100 : 0.0;
    return BatsmanStats(
      playerId: json['_id'] ?? json['playerId'] ?? '',
      playerName: json['playerName'] ?? json['name'] ?? '',
      runs: json['runs'] ?? 0,
      balls: json['balls'] ?? 0,
      fours: json['fours'] ?? json['4s'] ?? 0,
      sixes: json['sixes'] ?? json['6s'] ?? 0,
      strikeRate: sr,
      dismissal: json['dismissal'],
      bowlerDismissedBy: json['bowler'] ?? json['bowlerDismissedBy'],
      wicketNumber: json['wicketNumber'],
      notOut: json['notOut'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'runs': runs,
    'balls': balls,
    'fours': fours,
    'sixes': sixes,
    'strikeRate': strikeRate,
    'dismissal': dismissal,
    'bowlerDismissedBy': bowlerDismissedBy,
    'wicketNumber': wicketNumber,
  };

// ✅ ADD: howOut getter for UI compatibility
  String? get howOut => dismissal;

  @override
  List<Object?> get props => [playerId, playerName, runs, balls, fours, sixes, strikeRate, dismissal];
}

/// Detailed bowler stats
class BowlerStats extends Equatable {
  final String playerId;
  final String playerName;
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;
  final int? extras;

  const BowlerStats({
    required this.playerId,
    required this.playerName,
    this.overs = 0.0,
    this.maidens = 0,
    this.runs = 0,
    this.wickets = 0,
    this.economy = 0.0,
    this.extras,
  });

  factory BowlerStats.fromJson(Map<String, dynamic> json) {
    final eco = json['balls'] > 0 ? (json['runs'] / (json['balls'] / 6)) : 0.0;
    return BowlerStats(
      playerId: json['_id'] ?? json['playerId'] ?? '',
      playerName: json['playerName'] ?? json['name'] ?? '',
      overs: (json['balls'] ?? 0) / 6.0,
      maidens: json['maidens'] ?? 0,
      runs: json['runs'] ?? 0,
      wickets: json['wickets'] ?? 0,
      economy: eco,
      extras: json['extras'],
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'overs': overs,
    'maidens': maidens,
    'runs': runs,
    'wickets': wickets,
    'economy': economy,
    'extras': extras,
  };

  // Add this inside BowlerStats class
  String get oversDisplay {
    final oversInt = overs.floor();
    final ballsInt = ((overs - oversInt) * 6).round();
    return '$oversInt.$ballsInt';
  }

  @override
  List<Object?> get props => [playerId, playerName, overs, maidens, runs, wickets, economy, extras];
}

/// Fall of wicket
class FallOfWicket extends Equatable {
  final int wicket;
  final String batsman;
  final int runs;
  final String overs;

  const FallOfWicket({
    required this.wicket,
    required this.batsman,
    required this.runs,
    required this.overs,
  });

  factory FallOfWicket.fromJson(Map<String, dynamic> json) => FallOfWicket(
    wicket: json['wicketNumber'] ?? json['wicket'] ?? 0,
    batsman: json['batsman'] is Map ? json['batsman']['playerName'] ?? '' : json['batsman'] ?? '',
    runs: json['runs'] ?? 0,
    overs: json['overs'] ?? json['partnership'] ?? '0.0',
  );

  Map<String, dynamic> toJson() => {
    'wicket': wicket,
    'batsman': batsman,
    'runs': runs,
    'overs': overs,
  };

  @override
  List<Object?> get props => [wicket, batsman, runs, overs];
}

/// Complete scorecard response
class FullScorecard extends Equatable {
  final Match match;
  final List<Innings> innings;
  final List<List<BatsmanStats>> batting;
  final List<List<BowlerStats>> bowling;
  final List<FallOfWicket> fallOfWickets;
  final List<Map<String, dynamic>> partnerships;
  
  // ✅ NEW: Website format support
  final List<BatsmanStats>? battingScorecard;
  final List<BowlerStats>? bowlingScorecard;
  final Map<String, dynamic>? partnership;
  final int? runs;
  final int? wickets;
  final String? overs;
  final double? runRate;

  const FullScorecard({
    required this.match,
    required this.innings,
    this.batting = const [],
    this.bowling = const [],
    this.fallOfWickets = const [],
    this.partnerships = const [],
    this.battingScorecard,
    this.bowlingScorecard,
    this.partnership,
    this.runs,
    this.wickets,
    this.overs,
    this.runRate,
  });

  factory FullScorecard.fromJson(Map<String, dynamic> json) {
    // ✅ FIXED: Support both website format (battingScorecard) and Flutter format (batting)
    List<List<BatsmanStats>> safeBatting = [];
    final battingRaw = json['batting'] ?? [];
    if (battingRaw is List && battingRaw.isNotEmpty) {
      safeBatting = battingRaw.map<List<BatsmanStats>>((inningsBatting) {
        if (inningsBatting is List) {
          return inningsBatting.map<BatsmanStats>((p) => BatsmanStats.fromJson(p as Map<String, dynamic>)).toList();
        }
        return <BatsmanStats>[];
      }).toList();
    }
    
    // ✅ NEW: Also support website flat array format (battingScorecard)
    List<BatsmanStats>? websiteBatting;
    final websiteBattingRaw = json['battingScorecard'] ?? json['batting'];
    if (websiteBattingRaw is List && websiteBattingRaw.isNotEmpty) {
      // Check if it's flat array (website format) or nested (Flutter format)
      if (websiteBattingRaw.first is List) {
        // It's nested format - use existing parsing
      } else {
        // It's flat array (website format) - convert to nested
        websiteBatting = websiteBattingRaw.map<BatsmanStats>((p) => BatsmanStats.fromJson(p as Map<String, dynamic>)).toList();
        // Also set safeBatting for Flutter compatibility
        safeBatting = [websiteBatting];
      }
    }

    List<List<BowlerStats>> safeBowling = [];
    final bowlingRaw = json['bowling'] ?? [];
    if (bowlingRaw is List && bowlingRaw.isNotEmpty) {
      safeBowling = bowlingRaw.map<List<BowlerStats>>((inningsBowling) {
        if (inningsBowling is List) {
          return inningsBowling.map<BowlerStats>((p) => BowlerStats.fromJson(p as Map<String, dynamic>)).toList();
        }
        return <BowlerStats>[];
      }).toList();
    }
    
    // ✅ NEW: Also support website bowling flat array format
    List<BowlerStats>? websiteBowling;
    final websiteBowlingRaw = json['bowlingScorecard'] ?? json['bowling'];
    if (websiteBowlingRaw is List && websiteBowlingRaw.isNotEmpty) {
      if (websiteBowlingRaw.first is List) {
        // It's nested format
      } else {
        // It's flat array (website format)
        websiteBowling = websiteBowlingRaw.map<BowlerStats>((p) => BowlerStats.fromJson(p as Map<String, dynamic>)).toList();
        if (safeBowling.isEmpty) {
          safeBowling = [websiteBowling];
        }
      }
    }

    List<FallOfWicket> safeFallOfWickets = [];
    final fallOfWicketsRaw = json['fallOfWickets'] ?? [];
    if (fallOfWicketsRaw is List) {
      safeFallOfWickets = fallOfWicketsRaw.map<FallOfWicket>((e) => FallOfWicket.fromJson(e as Map<String, dynamic>)).toList();
    }

    // ✅ NEW: Extract extra fields from live scoring
    final extras = json['extras'] ?? {};
    
    return FullScorecard(
      match: Match.fromJson(json['match'] ?? {}),
      innings: (json['innings'] ?? []).map<Innings>((e) => Innings.fromJson(e as Map<String, dynamic>)).toList(),
      batting: safeBatting,
      bowling: safeBowling,
      fallOfWickets: safeFallOfWickets,
      partnerships: List<Map<String, dynamic>>.from(json['partnerships'] ?? []),
      // ✅ NEW: Website format fields
      battingScorecard: websiteBatting,
      bowlingScorecard: websiteBowling,
      partnership: json['partnership'] is Map ? json['partnership'] as Map<String, dynamic> : null,
      runs: json['runs'] ?? extras['total'] ?? 0,
      wickets: json['wickets'] ?? 0,
      overs: json['overs'] ?? '0.0',
      runRate: _parseRunRate(json['runRate']),
    );
  }
  
  static double? _parseRunRate(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Add toJson method
  Map<String, dynamic> toJson() {
    return {
      'match': match.toJson(),
      'innings': innings.map((e) => e.toJson()).toList(),
      'batting': batting.map((inningsBatting) => 
        inningsBatting.map((b) => b.toJson()).toList()
      ).toList(),
      'bowling': bowling.map((inningsBowling) => 
        inningsBowling.map((b) => b.toJson()).toList()
      ).toList(),
      'fallOfWickets': fallOfWickets.map((e) => e.toJson()).toList(),
      'partnerships': partnerships,
    };
  }

  @override
  List<Object?> get props => [match, innings, batting, bowling, fallOfWickets, partnerships];
}