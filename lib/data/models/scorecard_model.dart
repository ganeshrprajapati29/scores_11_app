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
  final String? dismissalNote;
  final String? bowlerDismissedBy;
  final String? fielderName;
  final int? wicketNumber;
  final bool notOut;
  final double scoringPoints;
  final Map<String, dynamic> pointsBreakdown;

  const BatsmanStats({
    required this.playerId,
    required this.playerName,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.strikeRate = 0.0,
    this.dismissal,
    this.dismissalNote,
    this.bowlerDismissedBy,
    this.fielderName,
    this.wicketNumber,
    this.notOut = false,
    this.scoringPoints = 0,
    this.pointsBreakdown = const {},
  });

  factory BatsmanStats.fromJson(Map<String, dynamic> json) {
    final player = json['batsman'] ?? json['player'];
    final runs = _toInt(json['runs']);
    final balls = _toInt(json['balls']);
    final sr = balls > 0 ? (runs / balls) * 100 : _toDouble(json['strikeRate']);
    final dismissalText = (json['dismissal'] ?? json['howOut'] ?? json['out'])
        ?.toString()
        .toLowerCase();
    return BatsmanStats(
      playerId: _extractPlayerId(json, player, ['batsmanId', 'playerId', 'id']),
      playerName: _extractPlayerName(json, player, [
        'playerName',
        'name',
        'batsmanName',
        'fullName',
        'displayName',
      ]),
      runs: runs,
      balls: balls,
      fours: _toInt(json['fours'] ?? json['4s']),
      sixes: _toInt(json['sixes'] ?? json['6s']),
      strikeRate: sr,
      dismissal: json['dismissal'] ?? json['howOut'] ?? json['out'],
      dismissalNote: json['dismissalNote']?.toString(),
      bowlerDismissedBy: _extractPlayerName(
        json['bowler'] ?? json['bowlerDismissedBy'],
        null,
        ['playerName', 'name', 'bowlerName'],
      ),
      fielderName: _extractPlayerName(
        json['fielder'] ?? json['assistedBy'] ?? json['catcher'],
        null,
        ['playerName', 'name', 'fielderName'],
      ),
      wicketNumber: _nullableInt(json['wicketNumber'] ?? json['wicket']),
      notOut:
          json['notOut'] == true ||
          dismissalText == 'not_out' ||
          dismissalText == 'not out' ||
          dismissalText == 'retired_hurt',
      scoringPoints: _toDouble(json['scoringPoints']),
      pointsBreakdown: json['pointsBreakdown'] is Map
          ? Map<String, dynamic>.from(json['pointsBreakdown'] as Map)
          : const {},
    );
  }

  static String _extractPlayerId(
    Map<String, dynamic> json,
    dynamic player,
    List<String> possibleKeys,
  ) {
    if (player is Map) {
      return (player['_id'] ??
              player['id'] ??
              player['playerId'] ??
              player['batsmanId'] ??
              '')
          .toString();
    }
    for (final key in possibleKeys) {
      if (json[key] != null) {
        return json[key].toString();
      }
    }
    if (player is String) {
      return player;
    }
    return '';
  }

  static String _extractPlayerName(
    dynamic jsonValue,
    dynamic player,
    List<String> possibleKeys,
  ) {
    if (jsonValue is Map<String, dynamic>) {
      final fromJson = _parseNameMap(jsonValue, possibleKeys);
      if (_isDisplayName(fromJson)) return fromJson;
    }
    if (jsonValue is String && jsonValue.isNotEmpty) {
      return _looksLikeId(jsonValue) ? 'Unknown' : jsonValue;
    }
    if (player is Map<String, dynamic>) {
      final fromPlayer = _parseNameMap(player, possibleKeys);
      if (_isDisplayName(fromPlayer)) return fromPlayer;
    }
    if (player is String && player.isNotEmpty) {
      return _looksLikeId(player) ? 'Unknown' : player;
    }
    return 'Unknown';
  }

  static String _parseNameMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) {
        return _looksLikeId(value) ? '' : value;
      }
    }
    for (final key in const [
      'playerName',
      'fullName',
      'displayName',
      'name',
      'first_name',
      'last_name',
      'nickName',
    ]) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty && !_looksLikeId(value)) {
        return value.trim();
      }
    }
    if (map['firstName'] != null || map['lastName'] != null) {
      final first = map['firstName']?.toString() ?? '';
      final last = map['lastName']?.toString() ?? '';
      final full = '$first ${last}'.trim();
      if (full.isNotEmpty) return full;
    }
    return '';
  }

  static bool _isDisplayName(String value) =>
      value.trim().isNotEmpty && !_looksLikeId(value);

  static bool _looksLikeId(String value) =>
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value.trim());

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static int? _nullableInt(dynamic value) =>
      value == null ? null : _toInt(value);
  static double _toDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0.0;

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'runs': runs,
    'balls': balls,
    'fours': fours,
    'sixes': sixes,
    'strikeRate': strikeRate,
    'dismissal': dismissal,
    'dismissalNote': dismissalNote,
    'bowlerDismissedBy': bowlerDismissedBy,
    'fielderName': fielderName,
    'wicketNumber': wicketNumber,
    'scoringPoints': scoringPoints,
    'pointsBreakdown': pointsBreakdown,
  };

  // ✅ ADD: howOut getter for UI compatibility
  String? get howOut => dismissal;
  bool get isOut {
    final text = dismissal?.toLowerCase().trim();
    return text != null &&
        text.isNotEmpty &&
        text != 'not_out' &&
        text != 'not out' &&
        text != 'retired_hurt';
  }

  String get dismissalDisplay {
    final rawText = dismissal?.toLowerCase().trim();
    final note = dismissalNote?.trim() ?? '';
    if (rawText == 'retired_hurt') {
      return note.isEmpty
          ? 'retired hurt (not out)'
          : 'retired hurt - $note (not out)';
    }
    if (!isOut) return 'not out';
    final outType = dismissal!.toLowerCase().trim();
    final bowler = bowlerDismissedBy?.trim() ?? '';
    final fielder = fielderName?.trim() ?? '';
    if (outType == 'bowled') return bowler.isNotEmpty ? 'b $bowler' : 'bowled';
    if (outType == 'lbw') return bowler.isNotEmpty ? 'lbw b $bowler' : 'lbw';
    if (outType == 'caught') {
      if (fielder.isNotEmpty && bowler.isNotEmpty)
        return 'c $fielder b $bowler';
      if (bowler.isNotEmpty) return 'c & b $bowler';
      return 'caught';
    }
    if (outType == 'stumped') {
      if (fielder.isNotEmpty && bowler.isNotEmpty)
        return 'st $fielder b $bowler';
      return 'stumped';
    }
    if (outType == 'run_out' || outType == 'run out') {
      return fielder.isNotEmpty ? 'run out ($fielder)' : 'run out';
    }
    final outText = outType
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    final base = outText.isNotEmpty ? outText : 'out';
    return note.isEmpty ? base : '$base - $note';
  }

  @override
  List<Object?> get props => [
    playerId,
    playerName,
    runs,
    balls,
    fours,
    sixes,
    strikeRate,
    dismissal,
    dismissalNote,
    bowlerDismissedBy,
    fielderName,
    scoringPoints,
    pointsBreakdown,
  ];
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
  final List<String> wicketDetails;
  final double scoringPoints;
  final Map<String, dynamic> pointsBreakdown;

  const BowlerStats({
    required this.playerId,
    required this.playerName,
    this.overs = 0.0,
    this.maidens = 0,
    this.runs = 0,
    this.wickets = 0,
    this.economy = 0.0,
    this.extras,
    this.wicketDetails = const [],
    this.scoringPoints = 0,
    this.pointsBreakdown = const {},
  });

  factory BowlerStats.fromJson(Map<String, dynamic> json) {
    final player = json['bowler'] ?? json['player'];
    final balls = _toInt(json['balls']);
    final runs = _toInt(json['runs'] ?? json['runsConceded']);
    final oversValue = json['overs'];
    final overs = oversValue == null
        ? balls / 6.0
        : _parseOvers(oversValue.toString());
    final eco = json['economy'] != null
        ? _toDouble(json['economy'])
        : (balls > 0 ? (runs / (balls / 6)) : (overs > 0 ? runs / overs : 0.0));
    return BowlerStats(
      playerId: _extractPlayerId(json, player, ['bowlerId', 'playerId', 'id']),
      playerName: _extractPlayerName(json, player, [
        'playerName',
        'name',
        'bowlerName',
        'fullName',
        'displayName',
      ]),
      overs: overs,
      maidens: _toInt(json['maidens']),
      runs: runs,
      wickets: _toInt(json['wickets']),
      economy: eco,
      extras: _nullableInt(json['extras']),
      wicketDetails: _parseWicketDetails(json['wicketsTaken']),
      scoringPoints: _toDouble(json['scoringPoints']),
      pointsBreakdown: json['pointsBreakdown'] is Map
          ? Map<String, dynamic>.from(json['pointsBreakdown'] as Map)
          : const {},
    );
  }

  static String _extractPlayerId(
    Map<String, dynamic> json,
    dynamic player,
    List<String> possibleKeys,
  ) {
    if (player is Map) {
      return (player['_id'] ??
              player['id'] ??
              player['playerId'] ??
              player['bowlerId'] ??
              '')
          .toString();
    }
    for (final key in possibleKeys) {
      if (json[key] != null) {
        return json[key].toString();
      }
    }
    if (player is String) {
      return player;
    }
    return '';
  }

  static String _extractPlayerName(
    dynamic jsonValue,
    dynamic player,
    List<String> possibleKeys,
  ) {
    if (jsonValue is Map<String, dynamic>) {
      final fromJson = _parseNameMap(jsonValue, possibleKeys);
      if (_isDisplayName(fromJson)) return fromJson;
    }
    if (jsonValue is String && jsonValue.isNotEmpty) {
      return _looksLikeId(jsonValue) ? 'Unknown' : jsonValue;
    }
    if (player is Map<String, dynamic>) {
      final fromPlayer = _parseNameMap(player, possibleKeys);
      if (_isDisplayName(fromPlayer)) return fromPlayer;
    }
    if (player is String && player.isNotEmpty) {
      return _looksLikeId(player) ? 'Unknown' : player;
    }
    return 'Unknown';
  }

  static String _parseNameMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) {
        return _looksLikeId(value) ? '' : value;
      }
    }
    for (final key in const [
      'playerName',
      'fullName',
      'displayName',
      'name',
      'first_name',
      'last_name',
      'nickName',
    ]) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty && !_looksLikeId(value)) {
        return value.trim();
      }
    }
    if (map['firstName'] != null || map['lastName'] != null) {
      final first = map['firstName']?.toString() ?? '';
      final last = map['lastName']?.toString() ?? '';
      final full = '$first ${last}'.trim();
      if (full.isNotEmpty) return full;
    }
    return '';
  }

  static bool _isDisplayName(String value) =>
      value.trim().isNotEmpty && !_looksLikeId(value);

  static bool _looksLikeId(String value) =>
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value.trim());

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static int? _nullableInt(dynamic value) =>
      value == null ? null : _toInt(value);
  static double _toDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0.0;
  static List<String> _parseWicketDetails(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((raw) {
          final batter = _extractPlayerName(raw['batsman'], null, [
            'playerName',
            'name',
            'batsmanName',
          ]);
          final dismissal = (raw['dismissal'] ?? raw['howOut'] ?? 'out')
              .toString()
              .replaceAll('_', ' ');
          final fielder = _extractPlayerName(raw['fielder'], null, [
            'playerName',
            'name',
            'fielderName',
          ]);
          final suffix = fielder.isNotEmpty && fielder != 'Unknown'
              ? ' ($fielder)'
              : '';
          return batter.isNotEmpty && batter != 'Unknown'
              ? '$batter - $dismissal$suffix'
              : '';
        })
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
  }

  static double _parseOvers(String value) {
    final parts = value.split('.');
    if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) +
          ((int.tryParse(parts[1]) ?? 0) / 6);
    }
    return double.tryParse(value) ?? 0.0;
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
    'wicketDetails': wicketDetails,
  };

  // Add this inside BowlerStats class
  String get oversDisplay {
    final oversInt = overs.floor();
    final ballsInt = ((overs - oversInt) * 6).round();
    return '$oversInt.$ballsInt';
  }

  @override
  List<Object?> get props => [
    playerId,
    playerName,
    overs,
    maidens,
    runs,
    wickets,
    economy,
    extras,
    wicketDetails,
  ];
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
    batsman: _fallBatsmanName(json['batsman']),
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

  static String _fallBatsmanName(dynamic value) {
    if (value is Map) {
      final name =
          value['playerName'] ??
          value['name'] ??
          value['fullName'] ??
          value['displayName'];
      final text = name?.toString().trim() ?? '';
      return _looksLikeId(text) || text.isEmpty ? 'Batsman' : text;
    }
    final text = value?.toString().trim() ?? '';
    return _looksLikeId(text) || text.isEmpty ? 'Batsman' : text;
  }

  static bool _looksLikeId(String value) =>
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value.trim());
}

class FieldingStats extends Equatable {
  final String playerId;
  final String playerName;
  final int catches;
  final int runOuts;
  final int stumpings;
  final int dismissals;
  final double scoringPoints;
  final Map<String, dynamic> pointsBreakdown;

  const FieldingStats({
    required this.playerId,
    required this.playerName,
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
    this.dismissals = 0,
    this.scoringPoints = 0,
    this.pointsBreakdown = const {},
  });

  factory FieldingStats.fromJson(Map<String, dynamic> json) {
    final player = json['player'] ?? json['fielder'];
    final catches = _toInt(json['catches']);
    final runOuts = _toInt(json['runOuts'] ?? json['runouts']);
    final stumpings = _toInt(json['stumpings'] ?? json['stumped']);
    final dismissals = _toInt(
      json['dismissals'] ?? (catches + runOuts + stumpings),
    );
    return FieldingStats(
      playerId: _extractPlayerId(json, player),
      playerName: _extractPlayerName(player),
      catches: catches,
      runOuts: runOuts,
      stumpings: stumpings,
      dismissals: dismissals,
      scoringPoints: _toDouble(json['scoringPoints'] ?? (dismissals * 0.5)),
      pointsBreakdown: json['pointsBreakdown'] is Map
          ? Map<String, dynamic>.from(json['pointsBreakdown'] as Map)
          : const {},
    );
  }

  static String _extractPlayerId(Map<String, dynamic> json, dynamic player) {
    if (player is Map) {
      return (player['_id'] ?? player['id'] ?? player['playerId'] ?? '')
          .toString();
    }
    return (json['playerId'] ?? json['fielderId'] ?? '').toString();
  }

  static String _extractPlayerName(dynamic player) {
    if (player is Map) {
      final name =
          player['playerName'] ??
          player['name'] ??
          player['fullName'] ??
          player['displayName'];
      final text = name?.toString().trim() ?? '';
      return text.isEmpty || RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(text)
          ? 'Fielder'
          : text;
    }
    final text = player?.toString().trim() ?? '';
    return text.isEmpty || RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(text)
        ? 'Fielder'
        : text;
  }

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _toDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0.0;

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'catches': catches,
    'runOuts': runOuts,
    'stumpings': stumpings,
    'dismissals': dismissals,
    'scoringPoints': scoringPoints,
    'pointsBreakdown': pointsBreakdown,
  };

  @override
  List<Object?> get props => [
    playerId,
    playerName,
    catches,
    runOuts,
    stumpings,
    dismissals,
    scoringPoints,
    pointsBreakdown,
  ];
}

/// Complete scorecard response
class FullScorecard extends Equatable {
  final Match match;
  final List<Innings> innings;
  final List<List<BatsmanStats>> batting;
  final List<List<BowlerStats>> bowling;
  final List<List<FieldingStats>> fielding;
  final List<FallOfWicket> fallOfWickets;
  final List<List<FallOfWicket>> fallOfWicketsByInnings;
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
    this.fielding = const [],
    this.fallOfWickets = const [],
    this.fallOfWicketsByInnings = const [],
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
          return inningsBatting
              .map<BatsmanStats>(
                (p) => BatsmanStats.fromJson(p as Map<String, dynamic>),
              )
              .toList();
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
        websiteBatting = websiteBattingRaw
            .map<BatsmanStats>(
              (p) => BatsmanStats.fromJson(p as Map<String, dynamic>),
            )
            .toList();
        // Also set safeBatting for Flutter compatibility
        safeBatting = [websiteBatting];
      }
    }

    List<List<BowlerStats>> safeBowling = [];
    final bowlingRaw = json['bowling'] ?? [];
    if (bowlingRaw is List && bowlingRaw.isNotEmpty) {
      safeBowling = bowlingRaw.map<List<BowlerStats>>((inningsBowling) {
        if (inningsBowling is List) {
          return inningsBowling
              .map<BowlerStats>(
                (p) => BowlerStats.fromJson(p as Map<String, dynamic>),
              )
              .toList();
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
        websiteBowling = websiteBowlingRaw
            .map<BowlerStats>(
              (p) => BowlerStats.fromJson(p as Map<String, dynamic>),
            )
            .toList();
        if (safeBowling.isEmpty) {
          safeBowling = [websiteBowling];
        }
      }
    }

    List<List<FieldingStats>> safeFielding = [];
    final fieldingRaw = json['fielding'] ?? json['fieldingScorecard'];
    if (fieldingRaw is List && fieldingRaw.isNotEmpty) {
      if (fieldingRaw.first is List) {
        safeFielding = fieldingRaw.map<List<FieldingStats>>((inningsFielding) {
          if (inningsFielding is! List) return <FieldingStats>[];
          return inningsFielding
              .whereType<Map>()
              .map((p) => FieldingStats.fromJson(Map<String, dynamic>.from(p)))
              .toList();
        }).toList();
      } else {
        safeFielding = [
          fieldingRaw
              .whereType<Map>()
              .map((p) => FieldingStats.fromJson(Map<String, dynamic>.from(p)))
              .toList(),
        ];
      }
    }
    if (safeFielding.isEmpty && json['innings'] is List) {
      safeFielding = (json['innings'] as List).map<List<FieldingStats>>((raw) {
        if (raw is! Map) return <FieldingStats>[];
        final rows = raw['fieldingScorecard'];
        if (rows is! List) return <FieldingStats>[];
        return rows
            .whereType<Map>()
            .map((p) => FieldingStats.fromJson(Map<String, dynamic>.from(p)))
            .toList();
      }).toList();
    }

    List<FallOfWicket> safeFallOfWickets = [];
    List<List<FallOfWicket>> safeFallOfWicketsByInnings = [];
    final cachedFowByInnings = json['fallOfWicketsByInnings'];
    if (cachedFowByInnings is List) {
      safeFallOfWicketsByInnings = cachedFowByInnings.map<List<FallOfWicket>>((
        raw,
      ) {
        if (raw is! List) return <FallOfWicket>[];
        return raw
            .whereType<Map>()
            .map((e) => FallOfWicket.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }).toList();
    }
    final inningsRaw = json['innings'];
    if (inningsRaw is List && safeFallOfWicketsByInnings.isEmpty) {
      safeFallOfWicketsByInnings = inningsRaw.map<List<FallOfWicket>>((raw) {
        if (raw is! Map) return <FallOfWicket>[];
        final fow = raw['fallOfWickets'];
        if (fow is! List) return <FallOfWicket>[];
        return fow
            .whereType<Map>()
            .map((e) => FallOfWicket.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }).toList();
    }
    final fallOfWicketsRaw = json['fallOfWickets'] ?? [];
    if (fallOfWicketsRaw is List) {
      safeFallOfWickets = fallOfWicketsRaw
          .map<FallOfWicket>(
            (e) => FallOfWicket.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    if (safeFallOfWickets.isEmpty && safeFallOfWicketsByInnings.isNotEmpty) {
      safeFallOfWickets = safeFallOfWicketsByInnings.expand((e) => e).toList();
    }

    // ✅ NEW: Extract extra fields from live scoring
    final extras = json['extras'] ?? {};

    return FullScorecard(
      match: Match.fromJson(json['match'] ?? {}),
      innings: (json['innings'] ?? [])
          .map<Innings>((e) => Innings.fromJson(e as Map<String, dynamic>))
          .toList(),
      batting: safeBatting,
      bowling: safeBowling,
      fielding: safeFielding,
      fallOfWickets: safeFallOfWickets,
      fallOfWicketsByInnings: safeFallOfWicketsByInnings,
      partnerships: List<Map<String, dynamic>>.from(json['partnerships'] ?? []),
      // ✅ NEW: Website format fields
      battingScorecard: websiteBatting,
      bowlingScorecard: websiteBowling,
      partnership: json['partnership'] is Map
          ? json['partnership'] as Map<String, dynamic>
          : null,
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
      'batting': batting
          .map(
            (inningsBatting) => inningsBatting.map((b) => b.toJson()).toList(),
          )
          .toList(),
      'bowling': bowling
          .map(
            (inningsBowling) => inningsBowling.map((b) => b.toJson()).toList(),
          )
          .toList(),
      'fielding': fielding
          .map(
            (inningsFielding) =>
                inningsFielding.map((f) => f.toJson()).toList(),
          )
          .toList(),
      'fallOfWickets': fallOfWickets.map((e) => e.toJson()).toList(),
      'fallOfWicketsByInnings': fallOfWicketsByInnings
          .map(
            (inningsWickets) => inningsWickets.map((e) => e.toJson()).toList(),
          )
          .toList(),
      'partnerships': partnerships,
    };
  }

  @override
  List<Object?> get props => [
    match,
    innings,
    batting,
    bowling,
    fielding,
    fallOfWickets,
    fallOfWicketsByInnings,
    partnerships,
  ];
}
