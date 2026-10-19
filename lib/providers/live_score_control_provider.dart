import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/services/offline_scoring_store.dart';
import '../data/services/match_service.dart';
import '../data/services/team_service.dart';
import '../data/services/player_service.dart';
import '../data/models/match_model.dart';
import '../data/models/player_model.dart';
import '../core/services/socket_service.dart';
import '../core/utils/friendly_error.dart';
import 'scorecard_provider.dart';
import 'package:dio/dio.dart';

/// Match status flow: scheduled → ready → toss → live → completed
enum MatchFlowStatus {
  scheduled, // Match created, waiting for teams/players
  ready, // Teams selected, ready for toss
  toss, // Toss in progress
  live, // Match is live
  completed, // Match completed
}

class LiveScoreState {
  final int runs;
  final int wickets;
  final String overs;
  final double runRate;
  final String? requiredRR;

  const LiveScoreState({
    this.runs = 0,
    this.wickets = 0,
    this.overs = '0.0',
    this.runRate = 0.0,
    this.requiredRR,
  });
}

class PlayerBattingStat {
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;

  const PlayerBattingStat({
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
  });

  PlayerBattingStat copyWith({
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    bool? isOut,
  }) {
    return PlayerBattingStat(
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isOut: isOut ?? this.isOut,
    );
  }

  double get strikeRate => balls == 0 ? 0 : (runs / balls) * 100;
}

class PlayerBowlingStat {
  final int balls;
  final int runs;
  final int wickets;

  const PlayerBowlingStat({this.balls = 0, this.runs = 0, this.wickets = 0});

  PlayerBowlingStat copyWith({int? balls, int? runs, int? wickets}) {
    return PlayerBowlingStat(
      balls: balls ?? this.balls,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
    );
  }

  String get overs => '${balls ~/ 6}.${balls % 6}';
  double get economy => balls == 0 ? 0 : runs / (balls / 6);
}

class _WicketRule {
  final bool countsAsWicket;
  final bool bowlerCredit;
  final bool freeHitAllowed;
  const _WicketRule({
    required this.countsAsWicket,
    required this.bowlerCredit,
    required this.freeHitAllowed,
  });
}

const Map<String, _WicketRule> _wicketRules = {
  'bowled': _WicketRule(countsAsWicket: true, bowlerCredit: true, freeHitAllowed: false),
  'caught': _WicketRule(countsAsWicket: true, bowlerCredit: true, freeHitAllowed: false),
  'caught_behind': _WicketRule(countsAsWicket: true, bowlerCredit: true, freeHitAllowed: false),
  'caught_and_bowled': _WicketRule(countsAsWicket: true, bowlerCredit: true, freeHitAllowed: false),
  'lbw': _WicketRule(countsAsWicket: true, bowlerCredit: true, freeHitAllowed: false),
  'stumped': _WicketRule(countsAsWicket: true, bowlerCredit: true, freeHitAllowed: false),
  'run_out': _WicketRule(countsAsWicket: true, bowlerCredit: false, freeHitAllowed: true),
  'run_out_non_striker': _WicketRule(countsAsWicket: true, bowlerCredit: false, freeHitAllowed: true),
  'hit_wicket': _WicketRule(countsAsWicket: true, bowlerCredit: true, freeHitAllowed: false),
  'hit_ball_twice': _WicketRule(countsAsWicket: true, bowlerCredit: false, freeHitAllowed: true),
  'obstructing_field': _WicketRule(countsAsWicket: true, bowlerCredit: false, freeHitAllowed: true),
  'handled_ball': _WicketRule(countsAsWicket: true, bowlerCredit: false, freeHitAllowed: true),
  'timed_out': _WicketRule(countsAsWicket: true, bowlerCredit: false, freeHitAllowed: false),
  'retired_out': _WicketRule(countsAsWicket: true, bowlerCredit: false, freeHitAllowed: false),
  'retired_hurt': _WicketRule(countsAsWicket: false, bowlerCredit: false, freeHitAllowed: true),
  'retired_not_out': _WicketRule(countsAsWicket: false, bowlerCredit: false, freeHitAllowed: true),
  'absent_hurt': _WicketRule(countsAsWicket: false, bowlerCredit: false, freeHitAllowed: false),
};

String _normalizeWicketType(String wicketType) {
  const aliases = {
    'runOut': 'run_out',
    'runout': 'run_out',
    'run_out_striker': 'run_out',
    'mankad': 'run_out_non_striker',
    'retire_out': 'retired_out',
    'retired': 'retired_hurt',
    'retiredhurt': 'retired_hurt',
    'absent': 'absent_hurt',
  };
  return aliases[wicketType] ?? wicketType;
}

class LiveScoreControlProvider extends ChangeNotifier {
  final MatchService _matchService;
  final TeamService _teamService;
  final PlayerService _playerService;
  // Socket + connectivity listeners; tests switch them off.
  final bool _realtime;
  SocketService? _socketService;

  LiveScoreControlProvider({
    MatchService? matchService,
    TeamService? teamService,
    PlayerService? playerService,
    bool realtime = true,
  })  : _matchService = matchService ?? MatchService(),
        _teamService = teamService ?? TeamService(),
        _playerService = playerService ?? PlayerService(),
        _realtime = realtime;

  // State
  String? _matchId;
  Match? _match;
  String? _userRole;
  bool _isLoading = false;
  bool _isInitializing = false;
  bool _isUndoing = false;
  String? _error;

  // Offline scoring: every scoring action is queued on the phone first and
  // sent to the server in order, so a lost connection never loses a ball.
  List<PendingScoreAction> _queue = [];
  bool _isSyncing = false;
  bool _isOffline = false;
  bool _replaying = false;
  Timer? _syncRetryTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Toss
  String? _tossWinnerKey;
  String? get tossWinnerKey => _tossWinnerKey;
  String? _tossWinner;
  String? _tossDecision;
  bool _tossPersisted = false;
  bool _isTossSaving = false;
  bool get tossDone => _tossPersisted;
  bool get isTossSaving => _isTossSaving;
  bool get canSubmitToss =>
      !_tossPersisted &&
      !_isTossSaving &&
      _tossWinnerKey != null &&
      _tossDecision != null;
  String? get tossWinner => _tossWinner;
  String get tossDecision => _tossDecision ?? 'bat';

  // Playing XI
  List<Player> _team1Players = [];
  List<Player> _team2Players = [];
  List<Player> _selectedTeam1Players = [];
  List<Player> _selectedTeam2Players = [];

  // Live state
  LiveScoreState _currentScore = const LiveScoreState();

  // Bumped every time a score update is applied (locally or from another
  // scorer via socket), so the UI can key a flash animation off it and give
  // the scorer haptic/visual confirmation that the update actually went
  // through.
  int _updatePulse = 0;
  int get updatePulse => _updatePulse;

  void _signalScoreUpdated() {
    if (_replaying) return;
    _updatePulse++;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Player? _currentStriker;
  Player? _currentNonStriker;
  Player? _currentBowler;
  String? _team1CaptainId;
  String? _team1ViceCaptainId;
  String? _team2CaptainId;
  String? _team2ViceCaptainId;

  List<Map<String, dynamic>> _currentOverBalls = [];
  int _legalBalls = 0;
  int get currentBall => _currentBall;
  bool _isFreeHit = false;
  // Bowler of the over that just finished (Law 17.8: cannot bowl the next one).
  String? _lastOverBowlerId;
  Map<String, int> _extras = {
    'wides': 0,
    'noBalls': 0,
    'byes': 0,
    'legByes': 0,
    'penalty': 0,
  };
  final Map<String, PlayerBattingStat> _battingStats = {};
  final Map<String, PlayerBowlingStat> _bowlingStats = {};
  final Set<String> _announcedMilestones = {};
  final Map<String, int> _consecutiveWickets = {};
  final List<String> _appreciations = [];
  String? _localResultMessage;
  String? _localPlayerOfMatch;
  int? _localTarget;
  bool _autoCompletingMatch = false;
  bool _continueAfterTarget = false;
  bool _continueAfterOvers = false;
  bool _continueAfterAllOut = false;

  // Getters
  String? get matchId => _matchId;
  Match? get match => _match;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isUndoing => _isUndoing;
  String? get error => _error;

  /// Scoring actions saved on this phone and not yet on the server.
  int get pendingSyncCount => _queue.where((a) => !a.isSent).length;
  int get pendingBallCount => _queue.where((a) => a.isBall && !a.isSent).length;
  bool get isSyncing => _isSyncing;
  bool get isOffline => _isOffline;
  bool get hasUnsyncedScore => _queue.any((a) => !a.isSent);
  PendingScoreAction? get rejectedAction {
    for (final action in _queue) {
      if (action.isRejected) return action;
    }
    return null;
  }
  LiveScoreState get currentScore => _currentScore;
  String get currentStatus => (_match?.status ?? 'scheduled').toLowerCase();
  bool get canStartMatch =>
      (currentStatus == 'ready' ||
          currentStatus == 'team_selecting' ||
          currentStatus == 'scheduled') &&
      _selectedTeam1Players.length >= 2 &&
      _selectedTeam2Players.length >= 2 &&
      tossDone;
  bool get canInitialize =>
      _selectedTeam1Players.length >= 2 &&
      _selectedTeam2Players.length >= 2 &&
      _hasCaptainAndViceCaptain(1) &&
      _hasCaptainAndViceCaptain(2);
  bool get canEndInnings =>
      currentStatus == 'live' || currentStatus == 'duckworth_lewis';
  bool get isRainAdjusted =>
      currentStatus == 'duckworth_lewis' ||
      ((_match?.result?.method ?? '').toLowerCase() == 'dls');

  List<Player> get team1Players => _team1Players;
  List<Player> get team2Players => _team2Players;
  List<Player> get selectedTeam1Players => _selectedTeam1Players;
  List<Player> get selectedTeam2Players => _selectedTeam2Players;

  Player? get currentStriker => _currentStriker;
  Player? get currentNonStriker => _currentNonStriker;
  Player? get currentBowler => _currentBowler;
  String? get team1CaptainId => _team1CaptainId;
  String? get team1ViceCaptainId => _team1ViceCaptainId;
  String? get team2CaptainId => _team2CaptainId;
  String? get team2ViceCaptainId => _team2ViceCaptainId;
  List<Map<String, dynamic>> get currentOverBalls => _currentOverBalls;
  bool get isFreeHit => _isFreeHit;

  /// Player id that may not bowl the over about to start, if known.
  /// Mirrors the server rule: standard and professional matches only.
  String? get barredBowlerId {
    final category = _match?.scoringRules.matchCategory ?? 'standard';
    if (category != 'standard' && category != 'professional') return null;
    if (_legalBalls == 0 || _legalBalls % 6 != 0) return null;
    return _lastOverBowlerId;
  }
  bool get continueAfterTarget => _continueAfterTarget;
  bool get continueAfterOvers => _continueAfterOvers;
  bool get continueAfterAllOut => _continueAfterAllOut;
  bool get practiceContinuationEnabled =>
      _continueAfterOvers || _continueAfterAllOut || _continueAfterTarget;
  int get _currentOver => _legalBalls ~/ 6;
  int get _currentBall => _legalBalls % 6;
  String get currentOver => '$_currentOver.$_currentBall';
  int get team1SelectedCount => _selectedTeam1Players.length;
  int get team2SelectedCount => _selectedTeam2Players.length;
  Map<String, int> get extras => _extras;
  String? get tossWinnerName =>
      _tossWinnerKey == 'team1' ? _match?.team1 : _match?.team2;
  String get tossDecisionDisplay =>
      _tossDecision == 'bat' ? 'Bat First' : 'Bowl First';
  bool get isTeam1Batting {
    final firstInningsTeam1 =
        (_tossWinnerKey == 'team1' && _tossDecision == 'bat') ||
            (_tossWinnerKey == 'team2' && _tossDecision == 'bowl') ||
            (_tossWinnerKey == null);
    return (_match?.currentInnings ?? 1) == 2
        ? !firstInningsTeam1
        : firstInningsTeam1;
  }

  List<Player> get battingTeamPlayers =>
      isTeam1Batting ? _selectedTeam1Players : _selectedTeam2Players;
  List<Player> get bowlingTeamPlayers =>
      isTeam1Batting ? _selectedTeam2Players : _selectedTeam1Players;
  List<Player> get availableStrikers => _withCurrentPlayer(
        battingTeamPlayers
            .where(
              (player) =>
                  player.id != _currentNonStriker?.id && !_isPlayerOut(player),
            )
            .toList(),
        _currentStriker,
      );
  List<Player> get availableNonStrikers => _withCurrentPlayer(
        battingTeamPlayers
            .where(
              (player) =>
                  player.id != _currentStriker?.id && !_isPlayerOut(player),
            )
            .toList(),
        _currentNonStriker,
      );
  List<Player> get availableBowlers =>
      _withCurrentPlayer(bowlingTeamPlayers, _currentBowler);
  String get battingTeamName => isTeam1Batting
      ? (_match?.team1 ?? 'Team 1')
      : (_match?.team2 ?? 'Team 2');
  String get bowlingTeamName => isTeam1Batting
      ? (_match?.team2 ?? 'Team 2')
      : (_match?.team1 ?? 'Team 1');
  int get inningsNumber => _match?.currentInnings ?? 1;
  bool get isSecondInnings => inningsNumber == 2;
  int? get target => _match?.result?.target ?? _localTarget ?? _computedTarget;
  int? get requiredRuns {
    final chaseTarget = target;
    if (!isSecondInnings || chaseTarget == null)
      return _match?.result?.requiredRuns;
    return (chaseTarget - _currentScore.runs).clamp(0, 9999);
  }

  int? get requiredBalls {
    if (!isSecondInnings) return _match?.result?.requiredBalls;
    return (_effectiveMaxBalls - _legalBalls)
        .clamp(0, _effectiveMaxBalls)
        .toInt();
  }

  String? get resultMessage => _localResultMessage ?? _match?.result?.message;
  String? get playerOfMatchName =>
      _localPlayerOfMatch ?? _match?.result?.playerOfMatch;
  List<String> get appreciations => List.unmodifiable(_appreciations);
  bool get isLocallyCompleted =>
      !_continueAfterTarget &&
      (_localResultMessage != null || currentStatus == 'completed');
  bool get hasFirstInningsCompleted =>
      _match?.innings.any((i) => i.inningsNumber == 1 && i.isCompleted) ??
      false;
  double? get requiredRR => _currentScore.requiredRR != null
      ? double.tryParse(_currentScore.requiredRR!)
      : null;
  bool get canRefresh => !_isLoading;
  bool get canUndoLastBall =>
      !_isUndoing &&
      (_currentOverBalls.isNotEmpty ||
          _currentScore.runs > 0 ||
          _currentScore.wickets > 0 ||
          _legalBalls > 0 ||
          _hasAnyRecordedScore);
  bool get isOverComplete => _legalBalls > 0 && _legalBalls % 6 == 0;
  int get _maxBalls => ((_match?.overs ?? 20) * 6).clamp(6, 600).toInt();
  bool get _isChildMatch => _match?.scoringRules.isChildMatch ?? false;
  int get _effectiveMaxBalls {
    final match = _match;
    if (match == null || !isSecondInnings) return _maxBalls;
    return match.scoringRules
        .effectiveChaseBalls(match.overs, inningsNumber: inningsNumber)
        .clamp(6, _maxBalls)
        .toInt();
  }

  PlayerBattingStat battingStatFor(Player? player) => player == null
      ? const PlayerBattingStat()
      : (_battingStats[player.id] ?? const PlayerBattingStat());
  PlayerBowlingStat bowlingStatFor(Player? player) => player == null
      ? const PlayerBowlingStat()
      : (_bowlingStats[player.id] ?? const PlayerBowlingStat());

  bool get _hasAnyRecordedScore {
    final score = _match?.score;
    if (score == null) return false;
    return score.team1.runs > 0 ||
        score.team1.wickets > 0 ||
        _ballsFromOvers(score.team1.overs) > 0 ||
        score.team2.runs > 0 ||
        score.team2.wickets > 0 ||
        _ballsFromOvers(score.team2.overs) > 0;
  }

  List<Player> _withCurrentPlayer(List<Player> players, Player? current) {
    if (current == null || current.id.isEmpty) return players;
    if (_isPlayerOut(current)) return players;
    if (players.any((player) => player.id == current.id)) return players;
    return [current, ...players];
  }

  bool _isPlayerOut(Player player) {
    final stat = _battingStats[player.id];
    return stat?.isOut == true;
  }

  // Match flow status
  MatchFlowStatus _flowStatus = MatchFlowStatus.scheduled;
  MatchFlowStatus get flowStatus => _flowStatus;

  // Get proper match status for UI
  String get matchStatusDisplay {
    if (_match == null) return 'Unknown';
    switch (_match!.status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'ready':
        return 'Ready for Toss';
      case 'toss':
        return 'Toss in Progress';
      case 'team_selecting':
        return 'Team Selection';
      case 'live':
        return 'Live';
      case 'completed':
        return 'Completed';
      default:
        return _match!.status;
    }
  }

  // Check if teams are ready for toss
  bool get canProceedToToss =>
      _selectedTeam1Players.length >= 2 && _selectedTeam2Players.isNotEmpty;

  void setUserRole(String? role) {
    _userRole = role;
    notifyListeners();
  }

  /// Initialize with dynamic match data - proper flow
  Future<void> initialize(String matchId, Match? match) async {
    _matchId = matchId;
    _match = match;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Determine flow status from match status
    _updateFlowStatus();

    if (matchId.isNotEmpty) {
      _queue = await OfflineScoringStore.loadQueue(matchId);
    }

    try {
      if (matchId.isNotEmpty) {
        _match = await _matchService.getMatchById(matchId, forceRefresh: true);
        _updateFlowStatus();
      }
      await _loadTeamPlayers();
      _hydrateTossAndLineups();
      await _loadLiveData();
      _isOffline = false;
    } catch (e) {
      // No internet: carry on from the last score saved on this phone.
      final restored = await _restoreFromSnapshot();
      if (restored) {
        _isOffline = true;
        _error = null;
      } else {
        _error = friendlyError(e, fallback: 'Could not open match scoring.');
      }
      debugPrint('❌ Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (_realtime) {
      try {
        await _setupSocketListeners();
      } catch (e) {
        debugPrint('Score socket unavailable: $e');
      }
      _watchConnectivity();
    }
    if (hasUnsyncedScore) unawaited(_flushQueue());
  }

  void _updateFlowStatus() {
    final status = _match?.status.toLowerCase();
    if (status == null) {
      _flowStatus = MatchFlowStatus.scheduled;
    } else if (status == 'scheduled') {
      _flowStatus = MatchFlowStatus.scheduled;
    } else if (status == 'ready' || status == 'team_selecting') {
      _flowStatus = MatchFlowStatus.ready;
    } else if (status == 'toss') {
      _flowStatus = MatchFlowStatus.toss;
    } else if (status == 'live') {
      _flowStatus = MatchFlowStatus.live;
    } else if (status == 'completed') {
      _flowStatus = MatchFlowStatus.completed;
    }
  }

  /// Refresh match data from API
  Future<void> refreshMatchData() async {
    if (_matchId == null) return;
    try {
      final updatedMatch = await _matchService.getMatchById(
        _matchId!,
        forceRefresh: true,
      );
      _match = updatedMatch;
      _updateFlowStatus();
      await _loadTeamPlayers();
      _hydrateTossAndLineups();
      await refreshLiveData();
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not refresh match data.');
      debugPrint('❌ Refresh error: $e');
    }
    notifyListeners();
  }

  Future<void> _loadTeamPlayers() async {
    if (_match == null) return;

    _team1Players = await _loadPlayersForTeam(
      _match!.team1Id,
      _match!.team1Data,
    );
    _team2Players = await _loadPlayersForTeam(
      _match!.team2Id,
      _match!.team2Data,
    );
    notifyListeners();
  }

  Future<List<Player>> _loadPlayersForTeam(
    String teamId,
    dynamic teamData,
  ) async {
    final embeddedPlayers = _playersFromTeamData(teamData);
    if (teamId.trim().isEmpty) return embeddedPlayers;

    final loadedPlayers = <Player>[];
    loadedPlayers.addAll(embeddedPlayers);

    try {
      final players = await _playerService.getPlayersByTeam(teamId);
      loadedPlayers.addAll(players);
    } catch (e) {
      debugPrint('Team players API failed for $teamId: $e');
    }

    try {
      final teamWithPlayers = await _teamService.getTeamWithPlayers(teamId);
      final players = teamWithPlayers['players'];
      if (players is List<Player>) loadedPlayers.addAll(players);
      if (players is List) {
        loadedPlayers.addAll(
          players
              .whereType<Map>()
              .map((json) => Player.fromJson(Map<String, dynamic>.from(json)))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Team fallback failed for $teamId: $e');
    }

    return _uniquePlayers(loadedPlayers);
  }

  List<Player> _uniquePlayers(List<Player> players) {
    final byId = <String, Player>{};
    for (final player in players) {
      if (player.id.isEmpty) continue;
      byId[player.id] = player;
    }
    return byId.values.toList();
  }

  List<Player> _playersFromTeamData(dynamic teamData) {
    if (teamData is! Map || teamData['players'] is! List) return const [];
    return (teamData['players'] as List)
        .whereType<Map>()
        .map((json) => Player.fromJson(Map<String, dynamic>.from(json)))
        .where((player) => player.id.isNotEmpty)
        .toList();
  }

  void _hydrateTossAndLineups() {
    final toss = _match?.toss;
    if (toss?.winner != null) {
      final winner = toss!.winner!;
      _tossWinnerKey = _isTeam1Value(winner) ? 'team1' : 'team2';
      _tossWinner = _tossWinnerKey == 'team1' ? _match?.team1 : _match?.team2;
      _tossDecision = toss.decision?.toLowerCase() ?? 'bat';
      _tossPersisted = true;
    } else {
      _tossPersisted = false;
    }

    final team1Order = _match?.battingOrder
        .where((order) => _isTeam1Value(order.team))
        .toList();
    final team2Order = _match?.battingOrder
        .where((order) => _isTeam2Value(order.team))
        .toList();

    if (team1Order != null && team1Order.isNotEmpty) {
      _selectedTeam1Players = _playersFromOrder(
        _team1Players,
        team1Order.first.players,
      );
    } else if (_selectedTeam1Players.isEmpty && _team1Players.isNotEmpty) {
      _selectedTeam1Players = _team1Players.take(25).toList();
    }
    if (team2Order != null && team2Order.isNotEmpty) {
      _selectedTeam2Players = _playersFromOrder(
        _team2Players,
        team2Order.first.players,
      );
    } else if (_selectedTeam2Players.isEmpty && _team2Players.isNotEmpty) {
      _selectedTeam2Players = _team2Players.take(25).toList();
    }

    _team1CaptainId ??= _idFromDynamic(
      _match?.team1Data is Map ? _match!.team1Data['captain'] : null,
    );
    _team1ViceCaptainId ??= _idFromDynamic(
      _match?.team1Data is Map ? _match!.team1Data['viceCaptain'] : null,
    );
    _team2CaptainId ??= _idFromDynamic(
      _match?.team2Data is Map ? _match!.team2Data['captain'] : null,
    );
    _team2ViceCaptainId ??= _idFromDynamic(
      _match?.team2Data is Map ? _match!.team2Data['viceCaptain'] : null,
    );
  }

  List<Player> _playersFromOrder(
    List<Player> availablePlayers,
    List<String> orderedIds,
  ) {
    final byId = {for (final player in availablePlayers) player.id: player};
    return orderedIds.map((id) => byId[id]).whereType<Player>().toList();
  }

  bool _isTeam1Value(String? value) {
    if (value == null) return false;
    return value == _match?.team1Id ||
        value == _match?.team1 ||
        value == _teamMapValue(_match?.team1Data, 'shortName');
  }

  bool _isTeam2Value(String? value) {
    if (value == null) return false;
    return value == _match?.team2Id ||
        value == _match?.team2 ||
        value == _teamMapValue(_match?.team2Data, 'shortName');
  }

  int? get _computedTarget {
    final match = _match;
    if (match == null || !isSecondInnings) return null;
    Innings? firstInnings;
    for (final innings in match.innings) {
      if (innings.inningsNumber == 1) {
        firstInnings = innings;
        break;
      }
    }
    if (firstInnings != null && firstInnings.totalRuns > 0) {
      return firstInnings.totalRuns + 1;
    }
    final firstTeam1 = _firstInningsTeam1Batting;
    final firstScore =
        firstTeam1 ? match.score.team1.runs : match.score.team2.runs;
    return firstScore > 0 ? firstScore + 1 : null;
  }

  bool get _firstInningsTeam1Batting {
    return (_tossWinnerKey == 'team1' && _tossDecision == 'bat') ||
        (_tossWinnerKey == 'team2' && _tossDecision == 'bowl') ||
        (_tossWinnerKey == null);
  }

  String get _firstInningsBattingTeamName => _firstInningsTeam1Batting
      ? (_match?.team1 ?? 'Team 1')
      : (_match?.team2 ?? 'Team 2');

  String get _secondInningsBattingTeamName => _firstInningsTeam1Batting
      ? (_match?.team2 ?? 'Team 2')
      : (_match?.team1 ?? 'Team 1');

  String? _teamMapValue(dynamic data, String key) {
    if (data is Map && data[key] != null) return data[key].toString();
    return null;
  }

  Future<void> refreshTeamPlayers() async {
    await _loadTeamPlayers();
    _hydrateTossAndLineups();
    _mergeNewPlayersIntoSelectedLineups();
    _ensureDefaultLeaders();
    notifyListeners();
  }

  void _mergeNewPlayersIntoSelectedLineups() {
    void merge(List<Player> allPlayers, List<Player> selectedPlayers) {
      final selectedIds = selectedPlayers.map((p) => p.id).toSet();
      for (final player in allPlayers) {
        if (selectedPlayers.length >= 25) break;
        if (player.id.isNotEmpty && !selectedIds.contains(player.id)) {
          selectedPlayers.add(player);
          selectedIds.add(player.id);
        }
      }
    }

    merge(_team1Players, _selectedTeam1Players);
    merge(_team2Players, _selectedTeam2Players);
  }

  Future<void> _loadLiveData() async {
    if (_matchId == null) return;

    Map<String, dynamic> liveData = {};
    var fetched = false;
    try {
      liveData = await _matchService.getLiveScore(_matchId!);
      fetched = true;
    } catch (_) {
      liveData = {};
    }
    if (!fetched && hasUnsyncedScore) {
      // Offline: keep the score on screen, which already includes queued balls.
      notifyListeners();
      return;
    }
    _applyLiveData(liveData);
    if (fetched) {
      // Balls the server confirmed are now part of its state.
      _queue.removeWhere((a) => a.isSent);
      await _persistQueue();
      await _saveSnapshot(liveData);
      if (hasUnsyncedScore) _replayQueuedLocally();
    }
    notifyListeners();
  }

  void _applyLiveData(Map<String, dynamic> liveData) {
    final scorecard = liveData['scorecard'] is Map
        ? liveData['scorecard'] as Map<String, dynamic>
        : <String, dynamic>{};
    _currentScore = LiveScoreState(
      runs: scorecard['runs'] ?? _currentScore.runs,
      wickets: scorecard['wickets'] ?? _currentScore.wickets,
      overs: scorecard['overs']?.toString() ?? _currentScore.overs,
      runRate: double.tryParse(scorecard['runRate']?.toString() ?? '0.00') ??
          _currentScore.runRate,
      requiredRR: liveData['requiredRunRate']?.toString(),
    );
    _localTarget = _match?.result?.target ?? _computedTarget;
    _legalBalls = _ballsFromOvers(_currentScore.overs);
    _hydrateScorecardStats(scorecard);
    _refreshChaseProjection();

    if (liveData.containsKey('currentStriker')) {
      final strikerId = _idFromDynamic(liveData['currentStriker']);
      _currentStriker = strikerId == null
          ? null
          : (_findPlayerById(strikerId) ?? _currentStriker);
    }
    if (liveData.containsKey('currentNonStriker')) {
      final nonStrikerId = _idFromDynamic(liveData['currentNonStriker']);
      _currentNonStriker = nonStrikerId == null
          ? null
          : (_findPlayerById(nonStrikerId) ?? _currentNonStriker);
    }
    if (liveData.containsKey('currentBowler')) {
      final bowlerId = _idFromDynamic(liveData['currentBowler']);
      _currentBowler = bowlerId == null
          ? null
          : (_findPlayerById(bowlerId) ?? _currentBowler);
    }

    final recentBalls = liveData['recentBalls'];
    _currentOverBalls = _normalizeRecentBalls(recentBalls);
    _isFreeHit = _freeHitFromRecentBalls(recentBalls);
  }

  Future<void> refreshLiveData() async {
    try {
      await _loadLiveData();
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not refresh live score.');
      debugPrint('Refresh error: $e');
      notifyListeners();
    }
  }

  Future<void> _setupSocketListeners() async {
    _socketService ??= SocketService();
    await _socketService!.connect();
    _socketService!.joinMatch(_matchId!);
    _socketService?.onLiveScoreUpdate((data) {
      if (data['matchId'] == _matchId) {
        _updateFromSocket(data);
      }
    });
  }

  void _updateFromSocket(Map<String, dynamic> data) {
    // While this phone has unsynced balls its own score is the newest one.
    if (hasUnsyncedScore || _isSyncing) return;
    if (data['action'] == 'matchCompleted') {
      refreshMatchData();
      return;
    }
    final innings = data['currentInnings'];
    if (innings is! Map) {
      refreshMatchData();
      return;
    }
    _currentScore = LiveScoreState(
      runs: innings['totalRuns'] ?? _currentScore.runs,
      wickets: innings['totalWickets'] ?? _currentScore.wickets,
      overs: innings['overs']?.toString() ?? _currentScore.overs,
      runRate:
          (innings['runRate'] as num?)?.toDouble() ?? _currentScore.runRate,
    );
    _legalBalls = _ballsFromOvers(_currentScore.overs);
    _refreshChaseProjection();
    final strikerId = _idFromDynamic(innings['currentStriker']);
    final nonStrikerId = _idFromDynamic(innings['currentNonStriker']);
    final bowlerId = _idFromDynamic(innings['currentBowler']);
    _currentStriker = strikerId == null
        ? null
        : (_findPlayerById(strikerId) ?? _currentStriker);
    _currentNonStriker = nonStrikerId == null
        ? null
        : (_findPlayerById(nonStrikerId) ?? _currentNonStriker);
    _currentBowler =
        bowlerId == null ? null : (_findPlayerById(bowlerId) ?? _currentBowler);
    _signalScoreUpdated();
    notifyListeners();
  }

  // Toss Methods
  void setTossWinner(String winner) {
    _tossWinnerKey = winner;
    _tossWinner = winner == 'team1' ? _match?.team1 : _match?.team2;
    notifyListeners();
  }

  void setTossDecision(String decision) {
    _tossDecision = decision;
    notifyListeners();
  }

  Future<void> submitToss() async {
    if (!canSubmitToss || _matchId == null || _match == null) return;
    if (_blockedWhileSyncing()) return;

    _isTossSaving = true;
    _error = null;
    notifyListeners();
    try {
      final winnerId =
          _tossWinnerKey == 'team1' ? _match!.team1Id : _match!.team2Id;
      _match = await _matchService.updateToss(
        _matchId!,
        winnerId,
        _tossDecision!,
      );
      _updateFlowStatus();
      _hydrateTossAndLineups();
    } catch (e) {
      await refreshMatchData();
      _error = tossDone
          ? null
          : friendlyError(e, fallback: 'Could not update toss.');
    } finally {
      _isTossSaving = false;
    }
    notifyListeners();
  }

  Future<bool> undoToss() async {
    if (_matchId == null || !tossDone) return false;
    if (_blockedWhileSyncing()) return false;
    _error = null;
    notifyListeners();
    try {
      _match = await _matchService.undoToss(_matchId!);
      _tossWinnerKey = null;
      _tossDecision = null;
      _updateFlowStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Toss undo failed: ${_friendlyError(e)}';
      notifyListeners();
      return false;
    }
  }

  void setContinueAfterTarget(bool value) {
    _continueAfterTarget = value;
    if (value) {
      _localResultMessage = null;
      _localPlayerOfMatch = null;
    }
    notifyListeners();
  }

  // XI Selection
  void toggleTeam1Player(Player player) {
    if (_selectedTeam1Players.any((p) => p.id == player.id)) {
      _selectedTeam1Players.removeWhere((p) => p.id == player.id);
      if (_team1CaptainId == player.id) _team1CaptainId = null;
      if (_team1ViceCaptainId == player.id) _team1ViceCaptainId = null;
    } else if (_selectedTeam1Players.length < 25) {
      _selectedTeam1Players.add(player);
    }
    _ensureDefaultLeaders();
    notifyListeners();
  }

  void toggleTeam2Player(Player player) {
    if (_selectedTeam2Players.any((p) => p.id == player.id)) {
      _selectedTeam2Players.removeWhere((p) => p.id == player.id);
      if (_team2CaptainId == player.id) _team2CaptainId = null;
      if (_team2ViceCaptainId == player.id) _team2ViceCaptainId = null;
    } else if (_selectedTeam2Players.length < 25) {
      _selectedTeam2Players.add(player);
    }
    _ensureDefaultLeaders();
    notifyListeners();
  }

  void setTeamCaptain(int teamNumber, Player player) {
    final players =
        teamNumber == 1 ? _selectedTeam1Players : _selectedTeam2Players;
    if (!players.any((p) => p.id == player.id)) return;
    if (teamNumber == 1) {
      _team1CaptainId = player.id;
      if (_team1ViceCaptainId == player.id) _team1ViceCaptainId = null;
    } else {
      _team2CaptainId = player.id;
      if (_team2ViceCaptainId == player.id) _team2ViceCaptainId = null;
    }
    notifyListeners();
  }

  void setTeamViceCaptain(int teamNumber, Player player) {
    final players =
        teamNumber == 1 ? _selectedTeam1Players : _selectedTeam2Players;
    if (!players.any((p) => p.id == player.id)) return;
    if (teamNumber == 1) {
      _team1ViceCaptainId = player.id;
      if (_team1CaptainId == player.id) _team1CaptainId = null;
    } else {
      _team2ViceCaptainId = player.id;
      if (_team2CaptainId == player.id) _team2CaptainId = null;
    }
    notifyListeners();
  }

  bool _hasCaptainAndViceCaptain(int teamNumber) {
    final players =
        teamNumber == 1 ? _selectedTeam1Players : _selectedTeam2Players;
    final captainId = teamNumber == 1 ? _team1CaptainId : _team2CaptainId;
    final viceCaptainId =
        teamNumber == 1 ? _team1ViceCaptainId : _team2ViceCaptainId;

    if (captainId == null ||
        viceCaptainId == null ||
        captainId == viceCaptainId) {
      return false;
    }

    return players.any((player) => player.id == captainId) &&
        players.any((player) => player.id == viceCaptainId);
  }

  void _ensureDefaultLeaders() {
    void applyForTeam(int teamNumber, List<Player> players) {
      if (players.isEmpty) return;
      final captainId = teamNumber == 1 ? _team1CaptainId : _team2CaptainId;
      final viceCaptainId =
          teamNumber == 1 ? _team1ViceCaptainId : _team2ViceCaptainId;

      final validCaptain =
          captainId != null && players.any((player) => player.id == captainId);
      final validViceCaptain = viceCaptainId != null &&
          viceCaptainId != captainId &&
          players.any((player) => player.id == viceCaptainId);

      if (teamNumber == 1) {
        _team1CaptainId = validCaptain ? captainId : players.first.id;
        _team1ViceCaptainId = validViceCaptain
            ? viceCaptainId
            : (players.length > 1 ? players[1].id : null);
      } else {
        _team2CaptainId = validCaptain ? captainId : players.first.id;
        _team2ViceCaptainId = validViceCaptain
            ? viceCaptainId
            : (players.length > 1 ? players[1].id : null);
      }
    }

    applyForTeam(1, _selectedTeam1Players);
    applyForTeam(2, _selectedTeam2Players);
  }

  Future<void> initializeMatch() async {
    if (_isInitializing) return;
    _isInitializing = true;
    _error = null;
    notifyListeners();
    if (_selectedTeam1Players.isEmpty && _team1Players.isNotEmpty) {
      _selectedTeam1Players = _team1Players.take(25).toList();
    }
    if (_selectedTeam2Players.isEmpty && _team2Players.isNotEmpty) {
      _selectedTeam2Players = _team2Players.take(25).toList();
    }
    _ensureDefaultLeaders();
    if (!canInitialize) {
      _error =
          'Select at least 2 players plus captain and vice-captain for both teams first';
      _isInitializing = false;
      notifyListeners();
      return;
    }
    try {
      final battingOrder = [
        {
          'team': _match!.team1Id,
          'players': _selectedTeam1Players.map((p) => p.id).toList(),
        },
        {
          'team': _match!.team2Id,
          'players': _selectedTeam2Players.map((p) => p.id).toList(),
        },
      ];
      await _matchService.initializeMatch(_matchId!, battingOrder);
      await refreshMatchData();
      _error = null;
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not initialize match.');
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _ensureScoringReady() async {
    if (_matchId == null || _match == null) return;
    final hasInnings = _match!.innings.isNotEmpty;
    final isLive = currentStatus == 'live';
    if (hasInnings && isLive) return;

    try {
      await initializeMatch();
      _error = null;
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not initialize match.');
      rethrow;
    }
  }

  // Live Scoring
  Future<void> setStriker(Player player) async {
    if (_isPlayerOut(player)) {
      _error =
          '${player.name} is already out. Select the next available batter.';
      notifyListeners();
      return;
    }
    if (_currentNonStriker?.id == player.id) _currentNonStriker = null;
    _currentStriker = player;
    _error = null;
    notifyListeners();
    await _queueRoleChange('striker', player.id);
  }

  Future<void> setNonStriker(Player player) async {
    if (_isPlayerOut(player)) {
      _error =
          '${player.name} is already out. Select the next available batter.';
      notifyListeners();
      return;
    }
    if (_currentStriker?.id == player.id) _currentStriker = null;
    _currentNonStriker = player;
    _error = null;
    notifyListeners();
    await _queueRoleChange('nonStriker', player.id);
  }

  Future<void> setBowler(Player player) async {
    _currentBowler = player;
    _error = null;
    notifyListeners();
    await _queueRoleChange('bowler', player.id);
  }

  String _serverErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message ?? 'Unable to sync score with server';
    }
    return friendlyError(error, fallback: 'Unable to sync score with server');
  }

  Future<void> _recoverFromScoreSyncFailure(Object error) async {
    final message = _serverErrorMessage(error);
    try {
      await refreshMatchData();
      _error = 'Score not saved: $message. Server score restored.';
    } catch (_) {
      _error =
          'Score not saved: $message. Refresh the match before scoring again.';
    }
    notifyListeners();
  }

  Future<void> addRuns(int runs) async {
    if (isLocallyCompleted) return;
    if (_currentStriker == null || _currentBowler == null) {
      _error = 'Set striker and bowler first';
      notifyListeners();
      return;
    }

    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'runs': runs,
      'isFour': runs == 4,
      'isSix': runs == 6,
      'continueAfterTarget': _continueAfterTarget,
      'allowAllOutContinue': true,
    };

    final local = _ballReplayInfo(runs: runs);
    _applyLocalBall(runs: runs);
    await _queueBall(ballData, local);
  }

  Future<void> addWagonShot({
    required int runs,
    required int zone,
    required String label,
  }) async {
    if (isLocallyCompleted) return;
    if (_currentStriker == null || _currentBowler == null) {
      _error = 'Set striker and bowler first';
      notifyListeners();
      return;
    }

    final scoredRuns = runs;
    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'runs': scoredRuns,
      'isFour': runs == 4,
      'isSix': runs == 6,
      'wagonZone': zone,
      'wagonLabel': label,
      'comment': '$runs run${runs == 1 ? '' : 's'} through $label',
      'continueAfterTarget': _continueAfterTarget,
      'allowAllOutContinue': true,
    };

    final local = _ballReplayInfo(runs: scoredRuns, wagonZone: zone, wagonLabel: label);
    _applyLocalBall(runs: scoredRuns, wagonZone: zone, wagonLabel: label);
    await _queueBall(ballData, local);
  }

  Future<void> addExtra(String type, {int runs = 0}) async {
    if (isLocallyCompleted) return;
    if (_currentStriker == null || _currentBowler == null) {
      _error = 'Set striker and bowler first';
      notifyListeners();
      return;
    }
    final apiKey = type == 'wide'
        ? 'isWide'
        : type == 'noBall'
            ? 'isNoBall'
            : type == 'bye'
                ? 'isBye'
                : type == 'legBye'
                    ? 'isLegBye'
                    : 'is$type';
    final scoredRuns = _isChildMatch && type == 'bye' && runs <= 0 ? 1 : runs;
    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'runs': scoredRuns,
      apiKey: true,
      'isFreeHit': _isFreeHit,
      'continueAfterTarget': _continueAfterTarget,
      'allowAllOutContinue': true,
    };
    final local = _ballReplayInfo(runs: scoredRuns, extraType: type);
    _applyLocalBall(runs: scoredRuns, extraType: type);
    await _queueBall(ballData, local);
  }

  Future<void> addCustomRuns({
    required int runs,
    bool isPenalty = false,
    bool? forceStrikeChange,
  }) async {
    if (isLocallyCompleted) return;
    if (_currentStriker == null || _currentBowler == null) {
      _error = 'Set striker and bowler first';
      notifyListeners();
      return;
    }
    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'runs': runs,
      if (isPenalty) 'isPenalty': true,
      if (forceStrikeChange != null) 'forceStrikeChange': forceStrikeChange,
      'continueAfterTarget': _continueAfterTarget,
      'allowAllOutContinue': true,
      'comment': isPenalty
          ? '$runs penalty run${runs == 1 ? '' : 's'}'
          : '$runs custom run${runs == 1 ? '' : 's'}',
    };
    final local = _ballReplayInfo(
      runs: runs,
      extraType: isPenalty ? 'penalty' : null,
      forceStrikeChange: forceStrikeChange,
    );
    _applyLocalBall(
      runs: runs,
      extraType: isPenalty ? 'penalty' : null,
      forceStrikeChange: forceStrikeChange,
    );
    await _queueBall(ballData, local);
  }

  Future<void> addWicket(String wicketType) async {
    await addWicketDetailed(wicketType: wicketType);
  }

  Future<void> addWicketDetailed({
    required String wicketType,
    Player? dismissedPlayer,
    Player? fielder,
    int completedRuns = 0,
  }) async {
    if (isLocallyCompleted) return;
    if (_currentStriker == null || _currentBowler == null) {
      _error = 'Set striker and bowler first';
      notifyListeners();
      return;
    }
    final normalizedWicketType = _normalizeWicketType(wicketType);
    final dismissed = dismissedPlayer ?? _currentStriker!;
    if (!_wicketRules.containsKey(normalizedWicketType)) {
      _error = 'Unsupported wicket type: $wicketType';
      notifyListeners();
      return;
    }
    if (_isFreeHit && !_isFreeHitWicketAllowed(normalizedWicketType)) {
      _error = '$normalizedWicketType is not allowed on a free hit';
      notifyListeners();
      return;
    }
    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'isWicket': true,
      'wicketType': normalizedWicketType,
      'runs': completedRuns,
      'dismissedBatsmanId': dismissed.id,
      if (fielder != null) 'fielderId': fielder.id,
      'isFreeHit': _isFreeHit,
      'continueAfterTarget': _continueAfterTarget,
      'allowAllOutContinue': true,
    };
    final local = _ballReplayInfo(
      runs: completedRuns,
      wicketType: normalizedWicketType,
      dismissedPlayerId: dismissed.id,
    );
    _applyLocalBall(
      runs: completedRuns,
      wicketType: normalizedWicketType,
      dismissedPlayer: dismissed,
    );
    await _queueBall(ballData, local);
  }

  Future<bool> undoLastBall() async {
    if (_matchId == null || _isUndoing) return false;
    if (_queue.any((a) => a.isBall && !a.isSent)) {
      return _undoQueuedBall();
    }
    if (hasUnsyncedScore || _isSyncing) {
      _error = 'Please wait a moment - the last change is still syncing.';
      notifyListeners();
      return false;
    }
    _isUndoing = true;
    _error = null;
    notifyListeners();

    try {
      await _matchService.undoLastBall(_matchId!);
      _localResultMessage = null;
      _localPlayerOfMatch = null;
      await refreshMatchData();
      _error = null;
      return true;
    } catch (e) {
      _error = 'Undo failed: ${_friendlyError(e)}';
      notifyListeners();
      return false;
    } finally {
      _isUndoing = false;
      notifyListeners();
    }
  }

  Future<bool> retireBatter({
    required Player batter,
    required String type,
    required String reason,
  }) async {
    if (_matchId == null) return false;
    if (_blockedWhileSyncing()) return false;
    _error = null;
    notifyListeners();
    try {
      await _matchService.retireBatter(_matchId!, {
        'batsmanId': batter.id,
        'type': type,
        'reason': reason,
      });
      if (_currentStriker?.id == batter.id) _currentStriker = null;
      if (_currentNonStriker?.id == batter.id) _currentNonStriker = null;
      await refreshLiveData();
      return true;
    } catch (e) {
      _error = 'Retirement failed: ${_friendlyError(e)}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePracticeContinuation({
    required bool afterOvers,
    required bool afterAllOut,
    required bool afterTarget,
  }) async {
    if (_matchId == null) return false;
    if (_blockedWhileSyncing()) return false;
    _error = null;
    notifyListeners();
    try {
      await _matchService.updateInningsContinuation(_matchId!, {
        'afterOvers': afterOvers,
        'afterAllOut': afterAllOut,
        'afterTarget': afterTarget,
      });
      _continueAfterOvers = afterOvers;
      _continueAfterAllOut = afterAllOut;
      _continueAfterTarget = afterTarget;
      if (practiceContinuationEnabled) {
        _localResultMessage = null;
        _localPlayerOfMatch = null;
      }
      await refreshMatchData();
      return true;
    } catch (e) {
      _error = 'Continuation update failed: ${_friendlyError(e)}';
      notifyListeners();
      return false;
    }
  }

  Future<void> applyRainDls({
    required String method,
    required int revisedOvers,
    bool completeMatch = false,
  }) async {
    if (_matchId == null) return;
    if (_blockedWhileSyncing()) return;
    _error = null;
    notifyListeners();
    try {
      final result = await _matchService.applyRainDls(_matchId!, {
        'method': method,
        'revisedOvers': revisedOvers,
        'wicketsLost': _currentScore.wickets,
        'completeMatch': completeMatch,
      });
      final resultData = result['result'];
      if (resultData is Map && resultData['message'] != null) {
        _localResultMessage = resultData['message'].toString();
      }
      if (resultData is Map && resultData['target'] != null) {
        _localTarget = int.tryParse(resultData['target'].toString());
      }
      await refreshMatchData();
    } catch (e) {
      _error = 'Rain/DLS update failed: ${_friendlyError(e)}';
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null)
        return friendlyError(data['message']);
      if (error.message != null && error.message!.isNotEmpty)
        return friendlyError(error.message);
    }
    return friendlyError(error);
  }

  bool _isFreeHitWicketAllowed(String wicketType) {
    return _wicketRules[_normalizeWicketType(wicketType)]?.freeHitAllowed ?? false;
  }

  Future<void> startMatch() async {
    if (_blockedWhileSyncing()) return;
    _error = null;
    notifyListeners();
    try {
      await _ensureScoringReady();
      await refreshMatchData();
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not start match.');
    }
    notifyListeners();
  }

  Future<void> endInnings() async {
    if (_blockedWhileSyncing()) return;
    _error = null;
    notifyListeners();
    try {
      await _matchService.endInnings(_matchId!);
      _currentStriker = null;
      _currentNonStriker = null;
      _currentBowler = null;
      await refreshMatchData();
    } catch (e) {
      _error = inningsNumber == 1
          ? friendlyError(e, fallback: 'Could not end the first innings.')
          : friendlyError(e, fallback: 'Could not finish the match.');
      notifyListeners();
    }
  }

  Future<void> _syncAutoResultIfNeeded() async {
    if (hasUnsyncedScore) return;
    if (_continueAfterTarget ||
        _matchId == null ||
        _autoCompletingMatch ||
        _localResultMessage == null) return;
    if (currentStatus == 'completed') return;

    _autoCompletingMatch = true;
    try {
      await _matchService.updateMatchResult(_matchId!, {
        'winner': _localResultMessage!.startsWith('Match tied')
            ? null
            : _winnerNameFromMessage(),
        'message': _localResultMessage,
        'method': 'normal',
        'playerOfMatch': _localPlayerOfMatch,
        'target': target,
        'requiredRuns': requiredRuns,
        'requiredBalls': requiredBalls,
      });
      await _matchService.endMatch(_matchId!);
      await refreshMatchData();
    } catch (e) {
      _error = friendlyError(
        e,
        fallback: 'Result saved on this device but could not be published. Please try again.',
      );
      notifyListeners();
    } finally {
      _autoCompletingMatch = false;
    }
  }

  String? _winnerNameFromMessage() {
    final message = _localResultMessage;
    if (message == null || message.startsWith('Match tied')) return null;
    final wonIndex = message.indexOf(' won ');
    return wonIndex > 0 ? message.substring(0, wonIndex) : null;
  }

  @override
  void dispose() {
    _syncRetryTimer?.cancel();
    _connectivitySub?.cancel();
    if (_matchId != null) _socketService?.leaveMatch(_matchId!);
    _socketService?.offLiveScoreUpdate();
    super.dispose();
  }

  Player? _findPlayerById(String id) {
    for (final player in [..._team1Players, ..._team2Players]) {
      if (player.id == id) return player;
    }
    return null;
  }

  String? _idFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      return (value['_id'] ??
              value['id'] ??
              value['batsman'] ??
              value['bowler'])
          ?.toString();
    }
    return value.toString();
  }

  int _ballsFromOvers(String overs) {
    final parts = overs.split('.');
    final overPart = int.tryParse(parts.isNotEmpty ? parts.first : '0') ?? 0;
    final ballPart = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return (overPart * 6) + ballPart.clamp(0, 5);
  }

  void _hydrateScorecardStats(Map<String, dynamic> scorecard) {
    final batting = scorecard['battingScorecard'];
    if (batting is List) {
      for (final raw in batting.whereType<Map>()) {
        final id = _idFromDynamic(raw['batsman']);
        if (id == null) continue;
        final howOut = (raw['howOut'] ?? raw['dismissal'] ?? 'not_out')
            .toString()
            .toLowerCase();
        _battingStats[id] = PlayerBattingStat(
          runs: (raw['runs'] as num?)?.toInt() ?? 0,
          balls: (raw['balls'] as num?)?.toInt() ?? 0,
          fours: (raw['fours'] as num?)?.toInt() ?? 0,
          sixes: (raw['sixes'] as num?)?.toInt() ?? 0,
          isOut: howOut != 'not_out' &&
              howOut != 'not out' &&
              howOut != 'retired_hurt',
        );
      }
    }

    final bowling = scorecard['bowlingScorecard'];
    if (bowling is List) {
      for (final raw in bowling.whereType<Map>()) {
        final id = _idFromDynamic(raw['bowler']);
        if (id == null) continue;
        _bowlingStats[id] = PlayerBowlingStat(
          balls: _ballsFromOvers((raw['overs'] ?? '0.0').toString()),
          runs: (raw['runsConceded'] as num?)?.toInt() ?? 0,
          wickets: (raw['wickets'] as num?)?.toInt() ?? 0,
        );
      }
    }

    final extras = scorecard['extras'];
    if (extras is Map) {
      _extras = {
        'wides': (extras['wides'] as num?)?.toInt() ?? _extras['wides'] ?? 0,
        'noBalls':
            (extras['noBalls'] as num?)?.toInt() ?? _extras['noBalls'] ?? 0,
        'byes': (extras['byes'] as num?)?.toInt() ?? _extras['byes'] ?? 0,
        'legByes':
            (extras['legByes'] as num?)?.toInt() ?? _extras['legByes'] ?? 0,
        'penalty':
            (extras['penalty'] as num?)?.toInt() ?? _extras['penalty'] ?? 0,
      };
    }
  }

  List<Map<String, dynamic>> _normalizeRecentBalls(dynamic raw) {
    if (raw is! List) return _currentOverBalls;
    return raw.whereType<Map>().map((ball) {
      final isWide = ball['isWide'] == true;
      final isNoBall = ball['isNoBall'] == true;
      final isBye = ball['isBye'] == true;
      final isLegBye = ball['isLegBye'] == true;
      final wicketType = ball['wicketType']?.toString();
      final wicketRule =
          wicketType == null ? null : _wicketRules[_normalizeWicketType(wicketType)];
      final extra = isWide
          ? 'Wd'
          : isNoBall
              ? 'Nb'
              : isBye
                  ? 'B'
                  : isLegBye
                      ? 'LB'
                      : null;
      return {
        'runs': (ball['runs'] as num?)?.toInt() ?? 0,
        'wicket': ball['wicket'] == true || ball['isWicket'] == true,
        'wicketCounts': wicketRule?.countsAsWicket ?? (ball['wicket'] == true || ball['isWicket'] == true),
        'wicketType': wicketType == null ? null : _normalizeWicketType(wicketType),
        'extra': extra,
        'wagonZone': (ball['wagonZone'] as num?)?.toInt(),
        'wagonLabel': ball['wagonLabel']?.toString(),
        'overNumber': ball['overNumber'],
        'ballNumber': ball['ballNumber'],
      };
    }).toList();
  }

  bool _freeHitFromRecentBalls(dynamic raw) {
    if (raw is! List || raw.isEmpty) return _isFreeHit;
    final last =
        raw.whereType<Map>().isEmpty ? null : raw.whereType<Map>().last;
    if (last == null) return _isFreeHit;
    final isWide = last['isWide'] == true;
    final isNoBall = last['isNoBall'] == true;
    final wasFreeHit = last['isFreeHit'] == true;
    if (isNoBall) return true;
    if (wasFreeHit && (isWide || isNoBall)) return true;
    return false;
  }

  void _applyLocalBall({
    required int runs,
    String? extraType,
    String? wicketType,
    int? wagonZone,
    String? wagonLabel,
    Player? dismissedPlayer,
    bool? forceStrikeChange,
  }) {
    final striker = _currentStriker;
    final bowler = _currentBowler;
    if (striker == null || bowler == null) return;

    final isWide = extraType == 'wide';
    final isNoBall = extraType == 'noBall';
    final isPenalty = extraType == 'penalty';
    final isLegal = !isWide && !isNoBall && !isPenalty;
    final isBye = extraType == 'bye';
    final isLegBye = extraType == 'legBye';
    final scoredRuns = _isChildMatch && isBye && runs <= 0 ? 1 : runs;
    final extraRuns = extraType == null
        ? 0
        : isWide
            ? scoredRuns + 1
            : isNoBall
                ? 1
                : scoredRuns;
    final batsmanRuns = (isBye || isLegBye || isPenalty) ? 0 : scoredRuns;
    final isWicket = wicketType != null;
    final normalizedWicketType =
        wicketType == null ? null : _normalizeWicketType(wicketType);
    final wicketRule = normalizedWicketType == null
        ? null
        : _wicketRules[normalizedWicketType];
    final wicketCounts = isWicket && (wicketRule?.countsAsWicket ?? true);
    final isBowlerWicket = wicketCounts && (wicketRule?.bowlerCredit ?? false);
    final totalRuns = (isWide || isBye || isLegBye || isPenalty)
        ? extraRuns
        : scoredRuns + extraRuns;
    final nextBalls = _legalBalls + (isLegal ? 1 : 0);
    final wasFreeHit = _isFreeHit;

    _currentScore = LiveScoreState(
      runs: _currentScore.runs + totalRuns,
      wickets: _currentScore.wickets + (wicketCounts ? 1 : 0),
      overs: _formatOvers(nextBalls),
      runRate: _calculateRunRate(_currentScore.runs + totalRuns, nextBalls),
      requiredRR: _currentScore.requiredRR,
    );

    if (extraType != null) {
      final key = extraType == 'wide'
          ? 'wides'
          : extraType == 'noBall'
              ? 'noBalls'
              : extraType == 'bye'
                  ? 'byes'
                  : extraType == 'legBye'
                      ? 'legByes'
                      : 'penalty';
      _extras[key] = (_extras[key] ?? 0) + extraRuns;
    }

    if (!isWide && !isBye && !isLegBye && !isPenalty) {
      final stat = _battingStats[striker.id] ?? const PlayerBattingStat();
      final updatedBatting = stat.copyWith(
        runs: stat.runs + batsmanRuns,
        balls: stat.balls + (isLegal ? 1 : 0),
        fours: stat.fours + (batsmanRuns == 4 ? 1 : 0),
        sixes: stat.sixes + (batsmanRuns == 6 ? 1 : 0),
        isOut: (wicketCounts &&
                (dismissedPlayer?.id ?? striker.id) == striker.id) ||
            stat.isOut,
      );
      _battingStats[striker.id] = updatedBatting;
      _recordBattingMilestone(striker, stat.runs, updatedBatting.runs);
    }

    if (wicketCounts &&
        dismissedPlayer != null &&
        dismissedPlayer.id != striker.id) {
      final dismissedStat =
          _battingStats[dismissedPlayer.id] ?? const PlayerBattingStat();
      _battingStats[dismissedPlayer.id] = dismissedStat.copyWith(isOut: true);
    }

    final bowlerStat = _bowlingStats[bowler.id] ?? const PlayerBowlingStat();
    final updatedBowling = bowlerStat.copyWith(
      balls: bowlerStat.balls + (isLegal ? 1 : 0),
      runs: bowlerStat.runs + (isPenalty ? 0 : totalRuns),
      wickets: bowlerStat.wickets + (isBowlerWicket ? 1 : 0),
    );
    _bowlingStats[bowler.id] = updatedBowling;
    if (isLegal) {
      _recordBowlingMoment(bowler, isBowlerWicket, updatedBowling);
    }

    _legalBalls = nextBalls;
    _currentOverBalls.add({
      'runs': scoredRuns,
      'wicket': isWicket,
      'wicketCounts': wicketCounts,
      'wicketType': normalizedWicketType,
      'extra': extraType == 'wide'
          ? 'Wd'
          : extraType == 'noBall'
              ? 'Nb'
              : extraType == 'bye'
                  ? 'B'
                  : extraType == 'legBye'
                      ? 'LB'
                      : extraType == 'penalty'
                          ? 'P'
                          : wasFreeHit
                              ? 'FH'
                              : null,
      'wagonZone': wagonZone,
      'wagonLabel': wagonLabel,
      'overNumber': _currentOver,
      'ballNumber': _currentBall,
    });
    if (_currentOverBalls.length > 12) {
      _currentOverBalls = _currentOverBalls.sublist(
        _currentOverBalls.length - 12,
      );
    }

    if (isNoBall) {
      _isFreeHit = true;
    } else if (isLegal) {
      _isFreeHit = false;
    }

    if (isWicket) {
      final dismissedId = dismissedPlayer?.id ?? striker.id;
      if (_currentStriker?.id == dismissedId) _currentStriker = null;
      if (_currentNonStriker?.id == dismissedId) _currentNonStriker = null;
    } else if (forceStrikeChange == true ||
        (forceStrikeChange == null && !isPenalty && runs.isOdd)) {
      swapStrike();
    }
    if (isLegal && _currentBall == 0) {
      swapStrike();
      _lastOverBowlerId = bowler.id;
      _currentBowler = null;
    }
    _refreshChaseProjection();
    _updateAutomaticResultIfFinished();
    _error = null;
    _signalScoreUpdated();
    notifyListeners();
  }

  void _recordBattingMilestone(
    Player striker,
    int previousRuns,
    int currentRuns,
  ) {
    for (final mark in const [50, 100]) {
      if (previousRuns < mark && currentRuns >= mark) {
        final key = 'bat-${striker.id}-$mark';
        if (_announcedMilestones.add(key)) {
          _appreciations.insert(
            0,
            '${striker.name} gets a brilliant $mark. Great batting.',
          );
        }
      }
    }
    if (_appreciations.length > 6) _appreciations.removeLast();
  }

  void _recordBowlingMoment(
    Player bowler,
    bool isWicket,
    PlayerBowlingStat stat,
  ) {
    if (!isWicket) {
      _consecutiveWickets[bowler.id] = 0;
      return;
    }
    final streak = (_consecutiveWickets[bowler.id] ?? 0) + 1;
    _consecutiveWickets[bowler.id] = streak;
    if (streak >= 3) {
      final key = 'hat-${bowler.id}-${stat.wickets}';
      if (_announcedMilestones.add(key)) {
        _appreciations.insert(
          0,
          '${bowler.name} takes a hat-trick. Outstanding bowling.',
        );
      }
    } else {
      final key = 'wkt-${bowler.id}-${stat.wickets}';
      if (stat.wickets >= 3 && _announcedMilestones.add(key)) {
        _appreciations.insert(
          0,
          '${bowler.name} has ${stat.wickets} wickets. Match-changing spell.',
        );
      }
    }
    if (_appreciations.length > 6) _appreciations.removeLast();
  }

  void _refreshChaseProjection() {
    if (!isSecondInnings) return;
    final chaseTarget = target;
    if (chaseTarget == null) return;
    _localTarget = chaseTarget;
    final ballsLeft =
        (_effectiveMaxBalls - _legalBalls).clamp(0, _effectiveMaxBalls).toInt();
    final runsLeft = (chaseTarget - _currentScore.runs).clamp(0, 9999).toInt();
    final rrr =
        ballsLeft == 0 ? null : ((runsLeft * 6) / ballsLeft).toStringAsFixed(2);
    _currentScore = LiveScoreState(
      runs: _currentScore.runs,
      wickets: _currentScore.wickets,
      overs: _currentScore.overs,
      runRate: _currentScore.runRate,
      requiredRR: rrr,
    );
  }

  void _updateAutomaticResultIfFinished() {
    if (_continueAfterTarget) return;
    if (!isSecondInnings || _localResultMessage != null) return;
    final chaseTarget = target;
    if (chaseTarget == null) return;

    final chasingTeam = _secondInningsBattingTeamName;
    final defendingTeam = _firstInningsBattingTeamName;
    if (_currentScore.runs >= chaseTarget) {
      final wicketsLeft = (10 - _currentScore.wickets).clamp(0, 10);
      _localResultMessage =
          '$chasingTeam won by $wicketsLeft wicket${wicketsLeft == 1 ? '' : 's'}';
    } else if (_currentScore.wickets >= 10 ||
        _legalBalls >= _effectiveMaxBalls) {
      final firstInningsRuns = chaseTarget - 1;
      if (_currentScore.runs == firstInningsRuns) {
        _localResultMessage = 'Match tied';
      } else {
        final margin = firstInningsRuns - _currentScore.runs;
        _localResultMessage =
            '$defendingTeam won by $margin run${margin == 1 ? '' : 's'}';
      }
    }
    if (_localResultMessage != null) {
      _localPlayerOfMatch = _calculatePlayerOfMatch();
      if (_localPlayerOfMatch != null) {
        _appreciations.insert(0, 'Player of the Match: $_localPlayerOfMatch');
      }
    }
  }

  String? _calculatePlayerOfMatch() {
    Player? bestPlayer;
    int bestScore = -1;
    for (final player in [..._selectedTeam1Players, ..._selectedTeam2Players]) {
      final bat = _battingStats[player.id] ?? const PlayerBattingStat();
      final bowl = _bowlingStats[player.id] ?? const PlayerBowlingStat();
      final score = bat.runs +
          (bat.fours * 2) +
          (bat.sixes * 3) +
          (bowl.wickets * 25) -
          (bowl.runs ~/ 10);
      if (score > bestScore) {
        bestScore = score;
        bestPlayer = player;
      }
    }
    return bestPlayer?.name;
  }

  // ===========================================================================
  // Offline scoring engine
  // ===========================================================================

  /// What [_replayQueuedLocally] needs to re-apply a ball exactly as scored.
  Map<String, dynamic> _ballReplayInfo({
    required int runs,
    String? extraType,
    String? wicketType,
    int? wagonZone,
    String? wagonLabel,
    String? dismissedPlayerId,
    bool? forceStrikeChange,
  }) =>
      {
        'runs': runs,
        if (extraType != null) 'extraType': extraType,
        if (wicketType != null) 'wicketType': wicketType,
        if (wagonZone != null) 'wagonZone': wagonZone,
        if (wagonLabel != null) 'wagonLabel': wagonLabel,
        if (dismissedPlayerId != null) 'dismissedPlayerId': dismissedPlayerId,
        if (forceStrikeChange != null) 'forceStrikeChange': forceStrikeChange,
        'strikerId': _currentStriker?.id,
        'nonStrikerId': _currentNonStriker?.id,
        'bowlerId': _currentBowler?.id,
      };

  Future<void> _queueBall(Map<String, dynamic> ballData, Map<String, dynamic> local) async {
    if (_matchId == null) return;
    final id = OfflineScoringStore.newActionId();
    _queue.add(PendingScoreAction(
      id: id,
      type: 'ball',
      payload: {...ballData, 'clientBallId': id},
      local: local,
    ));
    await _persistQueue();
    notifyListeners();
    await _flushQueue();
  }

  Future<void> _queueRoleChange(String role, String playerId) async {
    if (_matchId == null) return;
    // Only the latest choice for a role matters if it has not been sent yet.
    if (_queue.isNotEmpty) {
      final last = _queue.last;
      if (last.type == role && last.isPending && !_isSyncing) _queue.removeLast();
    }
    _queue.add(PendingScoreAction(
      id: OfflineScoringStore.newActionId(),
      type: role,
      payload: {'playerId': playerId},
      local: {'playerId': playerId},
    ));
    await _persistQueue();
    notifyListeners();
    await _flushQueue();
  }

  Future<void> _persistQueue() async {
    final id = _matchId;
    if (id == null || id.isEmpty) return;
    await OfflineScoringStore.saveQueue(id, _queue);
  }

  /// Send queued actions to the server, oldest first, stopping at the first
  /// one that cannot go through (no internet, or the server refused it).
  Future<void> _flushQueue() async {
    if (_isSyncing || _matchId == null) return;
    if (!_queue.any((a) => a.isPending)) return;
    _isSyncing = true;
    notifyListeners();

    var sentAny = false;
    try {
      while (true) {
        PendingScoreAction? next;
        for (final action in _queue) {
          if (action.isRejected) break; // wait for the scorer to decide
          if (action.isPending) {
            next = action;
            break;
          }
        }
        if (next == null) break;

        try {
          await _sendQueuedAction(next);
          next.status = 'sent';
          next.error = null;
          sentAny = true;
          _isOffline = false;
          await _persistQueue();
          notifyListeners();
        } on DioException catch (e) {
          if (_isRetryableError(e)) {
            _isOffline = true;
            break;
          }
          await _handleRejected(next, _serverErrorMessage(e));
          break;
        } catch (e) {
          if (_looksLikeNetworkFailure(e)) {
            _isOffline = true;
            break;
          }
          await _handleRejected(next, friendlyError(e, fallback: 'The server did not accept this ball.'));
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }

    if (sentAny && !hasUnsyncedScore) {
      await refreshMatchData();
      await _syncAutoResultIfNeeded();
    }
    _scheduleRetryIfNeeded();
    notifyListeners();
  }

  Future<void> _sendQueuedAction(PendingScoreAction action) async {
    final matchId = _matchId!;
    if (action.isBall) {
      await _matchService.addBall(matchId, action.payload);
      return;
    }
    await _ensureScoringReady();
    await _matchService.sendScoringRoleRaw(
      matchId,
      action.type,
      action.payload['playerId'].toString(),
    );
  }

  /// No response at all, a timeout, or a server/gateway failure: keep the
  /// action and try again later. A 4xx answer means the server refused it.
  bool _isRetryableError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        return status >= 500 || status == 408 || status == 429 || status == 401;
      default:
        return false;
    }
  }

  /// Some service methods wrap Dio errors in a plain Exception; recognise a
  /// lost connection from the wrapped text so it is retried, not discarded.
  bool _looksLikeNetworkFailure(Object e) {
    final text = friendlyError(e).toLowerCase();
    return text.contains('internet connection') || text.contains('took too long');
  }

  Future<void> _handleRejected(PendingScoreAction action, String message) async {
    final hasLaterActions = _queue.indexOf(action) < _queue.length - 1;
    if (!hasLaterActions) {
      // Same as before offline support: drop it and show the server's score.
      _queue.remove(action);
      await _persistQueue();
      if (action.isBall) {
        await _recoverFromScoreSyncFailure(DioException(
          requestOptions: RequestOptions(path: ''),
          message: message,
        ));
      } else {
        _error = message;
        await refreshMatchData();
      }
      return;
    }
    // Later balls depend on this one: pause and let the scorer decide.
    action.status = 'rejected';
    action.error = message;
    await _persistQueue();
    _error = 'A saved ${action.isBall ? 'ball' : 'change'} was not accepted: $message';
    notifyListeners();
  }

  /// Scorer chose to drop the refused action; send the rest.
  Future<void> discardRejectedAction() async {
    final rejected = rejectedAction;
    if (rejected == null) return;
    _queue.remove(rejected);
    await _persistQueue();
    _error = null;
    await _rebuildFromSnapshotAndQueue();
    await _flushQueue();
  }

  /// "Sync now" button, and the automatic retries.
  Future<void> retrySync() async {
    for (final action in _queue) {
      if (action.isRejected) {
        action.status = 'pending';
        action.error = null;
      }
    }
    await _persistQueue();
    await _flushQueue();
    if (!hasUnsyncedScore && !_isOffline) await refreshMatchData();
  }

  void _scheduleRetryIfNeeded() {
    _syncRetryTimer?.cancel();
    if (!_queue.any((a) => a.isPending)) return;
    _syncRetryTimer = Timer(const Duration(seconds: 15), () => _flushQueue());
  }

  void _watchConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && hasUnsyncedScore) _flushQueue();
      if (!online && hasUnsyncedScore) {
        _isOffline = true;
        notifyListeners();
      }
    });
  }

  bool _blockedWhileSyncing() {
    if (!hasUnsyncedScore && !_isSyncing) return false;
    final count = pendingSyncCount;
    _error = count > 0
        ? '$count scoring update${count == 1 ? ' is' : 's are'} still saved only on this phone. '
            'Connect to the internet and wait for them to sync first.'
        : 'Please wait a moment - scoring is syncing.';
    notifyListeners();
    return true;
  }

  Future<bool> _undoQueuedBall() async {
    final index = _queue.lastIndexWhere((a) => a.isBall && !a.isSent);
    if (index < 0) return false;
    if (_isSyncing && index == _queue.indexWhere((a) => a.isPending)) {
      _error = 'This ball is being sent right now. Try undo again in a moment.';
      notifyListeners();
      return false;
    }
    // Role changes made after that ball go with it.
    _queue.removeRange(index, _queue.length);
    await _persistQueue();
    _localResultMessage = null;
    _localPlayerOfMatch = null;
    _error = null;
    await _rebuildFromSnapshotAndQueue();
    return true;
  }

  Future<void> _saveSnapshot(Map<String, dynamic> liveData) async {
    final id = _matchId;
    final match = _match;
    if (id == null || id.isEmpty || match == null) return;
    try {
      await OfflineScoringStore.saveSnapshot(id, {
        'match': match.toJson(),
        'live': liveData,
        'team1Players': _team1Players.map((p) => p.toJson()).toList(),
        'team2Players': _team2Players.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Offline snapshot not saved: $e');
    }
  }

  /// Rebuild the screen from the last server-confirmed state saved on the
  /// phone. Returns false when nothing was saved for this match yet.
  Future<bool> _restoreFromSnapshot() async {
    final id = _matchId;
    if (id == null || id.isEmpty) return false;
    final snapshot = await OfflineScoringStore.loadSnapshot(id);
    if (snapshot == null) return false;
    try {
      final matchJson = snapshot['match'];
      if (matchJson is Map) {
        _match = Match.fromJson(Map<String, dynamic>.from(matchJson));
        _updateFlowStatus();
      }
      List<Player> players(dynamic raw) => raw is List
          ? raw.whereType<Map>().map((p) => Player.fromJson(Map<String, dynamic>.from(p))).toList()
          : <Player>[];
      final team1 = players(snapshot['team1Players']);
      final team2 = players(snapshot['team2Players']);
      if (team1.isNotEmpty) _team1Players = team1;
      if (team2.isNotEmpty) _team2Players = team2;
      _hydrateTossAndLineups();

      _battingStats.clear();
      _bowlingStats.clear();
      _extras = {'wides': 0, 'noBalls': 0, 'byes': 0, 'legByes': 0, 'penalty': 0};
      _currentOverBalls = [];
      _currentScore = const LiveScoreState();
      final live = snapshot['live'];
      _applyLiveData(live is Map ? Map<String, dynamic>.from(live) : <String, dynamic>{});
      _replayQueuedLocally();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Offline snapshot unreadable: $e');
      return false;
    }
  }

  Future<void> _rebuildFromSnapshotAndQueue() async {
    final restored = await _restoreFromSnapshot();
    if (!restored) await refreshMatchData();
    notifyListeners();
  }

  /// Re-apply every queued action on top of the server state on screen.
  void _replayQueuedLocally() {
    if (_queue.isEmpty) return;
    _replaying = true;
    try {
      // Every action still in the queue is missing from the state on screen:
      // "sent" ones are purged at the same moment a fresh server state is
      // saved, so any that remain are newer than the snapshot.
      for (final action in _queue) {
        final local = action.local;
        if (!action.isBall) {
          final player = _findPlayerById(local['playerId']?.toString() ?? '');
          if (player == null) continue;
          if (action.type == 'striker') {
            if (_currentNonStriker?.id == player.id) _currentNonStriker = null;
            _currentStriker = player;
          } else if (action.type == 'nonStriker') {
            if (_currentStriker?.id == player.id) _currentStriker = null;
            _currentNonStriker = player;
          } else if (action.type == 'bowler') {
            _currentBowler = player;
          }
          continue;
        }
        final striker = _findPlayerById(local['strikerId']?.toString() ?? '');
        final bowler = _findPlayerById(local['bowlerId']?.toString() ?? '');
        final nonStriker = _findPlayerById(local['nonStrikerId']?.toString() ?? '');
        if (striker != null) _currentStriker = striker;
        if (bowler != null) _currentBowler = bowler;
        if (nonStriker != null) _currentNonStriker = nonStriker;
        final dismissedId = local['dismissedPlayerId']?.toString();
        _applyLocalBall(
          runs: (local['runs'] as num?)?.toInt() ?? 0,
          extraType: local['extraType']?.toString(),
          wicketType: local['wicketType']?.toString(),
          wagonZone: (local['wagonZone'] as num?)?.toInt(),
          wagonLabel: local['wagonLabel']?.toString(),
          dismissedPlayer: dismissedId == null ? null : _findPlayerById(dismissedId),
          forceStrikeChange: local['forceStrikeChange'] as bool?,
        );
      }
    } finally {
      _replaying = false;
    }
  }

  void swapStrike() {
    final oldStriker = _currentStriker;
    _currentStriker = _currentNonStriker;
    _currentNonStriker = oldStriker;
  }

  /// Manually swap the striker/non-striker via a dedicated one-tap control
  /// (as opposed to [swapStrike], which is only ever applied as a side
  /// effect of scoring a ball). Persists to the backend so it survives a
  /// refresh, unlike the local-only swap above.
  Future<bool> swapStrikeManual() async {
    if (_matchId == null) return false;
    if (_blockedWhileSyncing()) return false;

    if (currentStriker == null || currentNonStriker == null) {
      _error = 'Set both striker and non-striker first';
      notifyListeners();
      return false;
    }
    _error = null;
    notifyListeners();
    try {
      await _matchService.swapStrike(_matchId!);
      swapStrike();
      await refreshMatchData();
      return true;
    } catch (e) {
      _error = 'Swap strike failed: ${_friendlyError(e)}';
      notifyListeners();
      return false;
    }
  }

  String _formatOvers(int balls) => '${balls ~/ 6}.${balls % 6}';

  double _calculateRunRate(int runs, int balls) {
    if (balls <= 0) return 0;
    return runs / (balls / 6);
  }
}
