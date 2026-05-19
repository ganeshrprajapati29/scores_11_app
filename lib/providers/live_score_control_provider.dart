import 'package:flutter/foundation.dart';
import '../data/services/match_service.dart';
import '../data/services/team_service.dart';
import '../data/services/player_service.dart';
import '../data/models/match_model.dart';
import '../data/models/player_model.dart';
import '../core/services/socket_service.dart';
import 'scorecard_provider.dart';

/// Match status flow: scheduled → ready → toss → live → completed
enum MatchFlowStatus {
  scheduled,  // Match created, waiting for teams/players
  ready,     // Teams selected, ready for toss
  toss,      // Toss in progress
  live,      // Match is live
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

  const PlayerBowlingStat({
    this.balls = 0,
    this.runs = 0,
    this.wickets = 0,
  });

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

class LiveScoreControlProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  final TeamService _teamService = TeamService();
  final PlayerService _playerService = PlayerService();
  SocketService? _socketService;

  // State
  String? _matchId;
  Match? _match;
  String? _userRole;
  bool _isLoading = false;
  bool _isInitializing = false;
  String? _error;

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
  Map<String, int> _extras = {'wides': 0, 'noBalls': 0, 'byes': 0, 'legByes': 0};
  final Map<String, PlayerBattingStat> _battingStats = {};
  final Map<String, PlayerBowlingStat> _bowlingStats = {};
  final Set<String> _announcedMilestones = {};
  final Map<String, int> _consecutiveWickets = {};
  final List<String> _appreciations = [];
  String? _localResultMessage;
  String? _localPlayerOfMatch;
  int? _localTarget;
  bool _autoCompletingMatch = false;

  // Getters
  String? get matchId => _matchId;
  Match? get match => _match;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
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
  bool get canEndInnings => currentStatus == 'live';

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
  int get _currentOver => _legalBalls ~/ 6;
  int get _currentBall => _legalBalls % 6;
  String get currentOver => '$_currentOver.$_currentBall';
  int get team1SelectedCount => _selectedTeam1Players.length;
  int get team2SelectedCount => _selectedTeam2Players.length;
  Map<String, int> get extras => _extras;
  String? get tossWinnerName => _tossWinnerKey == 'team1' ? _match?.team1 : _match?.team2;
  String get tossDecisionDisplay => _tossDecision == 'bat' ? 'Bat First' : 'Bowl First';
  bool get isTeam1Batting {
    final firstInningsTeam1 = (_tossWinnerKey == 'team1' && _tossDecision == 'bat') ||
        (_tossWinnerKey == 'team2' && _tossDecision == 'bowl') ||
        (_tossWinnerKey == null);
    return (_match?.currentInnings ?? 1) == 2 ? !firstInningsTeam1 : firstInningsTeam1;
  }
  List<Player> get battingTeamPlayers => isTeam1Batting ? _selectedTeam1Players : _selectedTeam2Players;
  List<Player> get bowlingTeamPlayers => isTeam1Batting ? _selectedTeam2Players : _selectedTeam1Players;
  List<Player> get availableStrikers => _withCurrentPlayer(
        battingTeamPlayers
            .where((player) =>
                !battingStatFor(player).isOut &&
                player.id != _currentNonStriker?.id)
            .toList(),
        _currentStriker,
      );
  List<Player> get availableNonStrikers => _withCurrentPlayer(
        battingTeamPlayers
            .where((player) =>
                !battingStatFor(player).isOut &&
                player.id != _currentStriker?.id)
            .toList(),
        _currentNonStriker,
      );
  List<Player> get availableBowlers =>
      _withCurrentPlayer(bowlingTeamPlayers, _currentBowler);
  String get battingTeamName => isTeam1Batting ? (_match?.team1 ?? 'Team 1') : (_match?.team2 ?? 'Team 2');
  String get bowlingTeamName => isTeam1Batting ? (_match?.team2 ?? 'Team 2') : (_match?.team1 ?? 'Team 1');
  int get inningsNumber => _match?.currentInnings ?? 1;
  bool get isSecondInnings => inningsNumber == 2;
  int? get target => _match?.result?.target ?? _localTarget ?? _computedTarget;
  int? get requiredRuns {
    final chaseTarget = target;
    if (!isSecondInnings || chaseTarget == null) return _match?.result?.requiredRuns;
    return (chaseTarget - _currentScore.runs).clamp(0, 9999);
  }
  int? get requiredBalls {
    if (!isSecondInnings) return _match?.result?.requiredBalls;
    return (_maxBalls - _legalBalls).clamp(0, _maxBalls);
  }
  String? get resultMessage => _localResultMessage ?? _match?.result?.message;
  String? get playerOfMatchName => _localPlayerOfMatch ?? _match?.result?.playerOfMatch;
  List<String> get appreciations => List.unmodifiable(_appreciations);
  bool get isLocallyCompleted => _localResultMessage != null || currentStatus == 'completed';
  bool get hasFirstInningsCompleted => _match?.innings.any((i) => i.inningsNumber == 1 && i.isCompleted) ?? false;
  double? get requiredRR => _currentScore.requiredRR != null ? double.tryParse(_currentScore.requiredRR!) : null;
  bool get canRefresh => !_isLoading;
  bool get isOverComplete => _legalBalls > 0 && _legalBalls % 6 == 0;
  int get _maxBalls => ((_match?.overs ?? 20) * 6).clamp(6, 600);
  PlayerBattingStat battingStatFor(Player? player) =>
      player == null ? const PlayerBattingStat() : (_battingStats[player.id] ?? const PlayerBattingStat());
  PlayerBowlingStat bowlingStatFor(Player? player) =>
      player == null ? const PlayerBowlingStat() : (_bowlingStats[player.id] ?? const PlayerBowlingStat());

  List<Player> _withCurrentPlayer(List<Player> players, Player? current) {
    if (current == null || current.id.isEmpty) return players;
    if (players.any((player) => player.id == current.id)) return players;
    return [current, ...players];
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

  LiveScoreControlProvider();

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

    try {
      if (matchId.isNotEmpty) {
        _match = await _matchService.getMatchById(matchId, forceRefresh: true);
        _updateFlowStatus();
      }
      await _loadTeamPlayers();
      _hydrateTossAndLineups();
      await _loadLiveData();
      await _setupSocketListeners();
    } catch (e) {
      _error = 'Failed to initialize: $e';
      debugPrint('❌ Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      final updatedMatch = await _matchService.getMatchById(_matchId!, forceRefresh: true);
      _match = updatedMatch;
      _updateFlowStatus();
      await _loadTeamPlayers();
      _hydrateTossAndLineups();
      await refreshLiveData();
    } catch (e) {
      _error = 'Failed to refresh: $e';
      debugPrint('❌ Refresh error: $e');
    }
    notifyListeners();
  }

  Future<void> _loadTeamPlayers() async {
    if (_match == null) return;

    _team1Players = await _loadPlayersForTeam(_match!.team1Id, _match!.team1Data);
    _team2Players = await _loadPlayersForTeam(_match!.team2Id, _match!.team2Data);
    notifyListeners();
  }

  Future<List<Player>> _loadPlayersForTeam(String teamId, dynamic teamData) async {
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
        loadedPlayers.addAll(players
            .whereType<Map>()
            .map((json) => Player.fromJson(Map<String, dynamic>.from(json)))
            .toList());
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
      _selectedTeam1Players = _playersFromOrder(_team1Players, team1Order.first.players);
    } else if (_selectedTeam1Players.isEmpty && _team1Players.isNotEmpty) {
      _selectedTeam1Players = _team1Players.take(11).toList();
    }
    if (team2Order != null && team2Order.isNotEmpty) {
      _selectedTeam2Players = _playersFromOrder(_team2Players, team2Order.first.players);
    } else if (_selectedTeam2Players.isEmpty && _team2Players.isNotEmpty) {
      _selectedTeam2Players = _team2Players.take(11).toList();
    }

    _team1CaptainId ??= _idFromDynamic(_match?.team1Data is Map ? _match!.team1Data['captain'] : null);
    _team1ViceCaptainId ??= _idFromDynamic(_match?.team1Data is Map ? _match!.team1Data['viceCaptain'] : null);
    _team2CaptainId ??= _idFromDynamic(_match?.team2Data is Map ? _match!.team2Data['captain'] : null);
    _team2ViceCaptainId ??= _idFromDynamic(_match?.team2Data is Map ? _match!.team2Data['viceCaptain'] : null);
  }

  List<Player> _playersFromOrder(List<Player> availablePlayers, List<String> orderedIds) {
    final byId = {for (final player in availablePlayers) player.id: player};
    return orderedIds.map((id) => byId[id]).whereType<Player>().toList();
  }

  bool _isTeam1Value(String? value) {
    if (value == null) return false;
    return value == _match?.team1Id || value == _match?.team1 || value == _teamMapValue(_match?.team1Data, 'shortName');
  }

  bool _isTeam2Value(String? value) {
    if (value == null) return false;
    return value == _match?.team2Id || value == _match?.team2 || value == _teamMapValue(_match?.team2Data, 'shortName');
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
    final firstScore = firstTeam1 ? match.score.team1.runs : match.score.team2.runs;
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
        if (selectedPlayers.length >= 11) break;
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
    try {
      liveData = await _matchService.getLiveScore(_matchId!);
    } catch (_) {
      liveData = {};
    }
    final scorecard = liveData['scorecard'] is Map ? liveData['scorecard'] as Map<String, dynamic> : <String, dynamic>{};
    _currentScore = LiveScoreState(
      runs: scorecard['runs'] ?? _currentScore.runs,
      wickets: scorecard['wickets'] ?? _currentScore.wickets,
      overs: scorecard['overs']?.toString() ?? _currentScore.overs,
      runRate: double.tryParse(scorecard['runRate']?.toString() ?? '0.00') ?? _currentScore.runRate,
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
    notifyListeners();
  }

  Future<void> refreshLiveData() async {
    try {
      await _loadLiveData();
    } catch (e) {
      _error = 'Live refresh failed: $e';
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
      runRate: (innings['runRate'] as num?)?.toDouble() ?? _currentScore.runRate,
    );
    _legalBalls = _ballsFromOvers(_currentScore.overs);
    _refreshChaseProjection();
    final strikerId = _idFromDynamic(innings['currentStriker']);
    final nonStrikerId = _idFromDynamic(innings['currentNonStriker']);
    final bowlerId = _idFromDynamic(innings['currentBowler']);
    _currentStriker =
        strikerId == null ? null : (_findPlayerById(strikerId) ?? _currentStriker);
    _currentNonStriker = nonStrikerId == null
        ? null
        : (_findPlayerById(nonStrikerId) ?? _currentNonStriker);
    _currentBowler =
        bowlerId == null ? null : (_findPlayerById(bowlerId) ?? _currentBowler);
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

    _isTossSaving = true;
    _error = null;
    notifyListeners();
    try {
      final winnerId = _tossWinnerKey == 'team1' ? _match!.team1Id : _match!.team2Id;
      _match = await _matchService.updateToss(_matchId!, winnerId, _tossDecision!);
      _updateFlowStatus();
      _hydrateTossAndLineups();
    } catch (e) {
      await refreshMatchData();
      _error = tossDone ? null : 'Toss update failed: $e';
    } finally {
      _isTossSaving = false;
    }
    notifyListeners();
  }

  // XI Selection
  void toggleTeam1Player(Player player) {
    if (_selectedTeam1Players.any((p) => p.id == player.id)) {
      _selectedTeam1Players.removeWhere((p) => p.id == player.id);
      if (_team1CaptainId == player.id) _team1CaptainId = null;
      if (_team1ViceCaptainId == player.id) _team1ViceCaptainId = null;
    } else if (_selectedTeam1Players.length < 11) {
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
    } else if (_selectedTeam2Players.length < 11) {
      _selectedTeam2Players.add(player);
    }
    _ensureDefaultLeaders();
    notifyListeners();
  }

  void setTeamCaptain(int teamNumber, Player player) {
    final players = teamNumber == 1 ? _selectedTeam1Players : _selectedTeam2Players;
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
    final players = teamNumber == 1 ? _selectedTeam1Players : _selectedTeam2Players;
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
    final players = teamNumber == 1 ? _selectedTeam1Players : _selectedTeam2Players;
    final captainId = teamNumber == 1 ? _team1CaptainId : _team2CaptainId;
    final viceCaptainId = teamNumber == 1 ? _team1ViceCaptainId : _team2ViceCaptainId;

    if (captainId == null || viceCaptainId == null || captainId == viceCaptainId) {
      return false;
    }

    return players.any((player) => player.id == captainId) &&
        players.any((player) => player.id == viceCaptainId);
  }

  void _ensureDefaultLeaders() {
    void applyForTeam(int teamNumber, List<Player> players) {
      if (players.isEmpty) return;
      final captainId = teamNumber == 1 ? _team1CaptainId : _team2CaptainId;
      final viceCaptainId = teamNumber == 1 ? _team1ViceCaptainId : _team2ViceCaptainId;

      final validCaptain = captainId != null && players.any((player) => player.id == captainId);
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
      _selectedTeam1Players = _team1Players.take(11).toList();
    }
    if (_selectedTeam2Players.isEmpty && _team2Players.isNotEmpty) {
      _selectedTeam2Players = _team2Players.take(11).toList();
    }
    _ensureDefaultLeaders();
    if (!canInitialize) {
      _error = 'Select at least 2 players plus captain and vice-captain for both teams first';
      _isInitializing = false;
      notifyListeners();
      return;
    }
    try {
      final battingOrder = [
        {'team': _match!.team1Id, 'players': _selectedTeam1Players.map((p) => p.id).toList()},
        {'team': _match!.team2Id, 'players': _selectedTeam2Players.map((p) => p.id).toList()},
      ];
      await _matchService.initializeMatch(_matchId!, battingOrder);
      await refreshMatchData();
      _error = null;
    } catch (e) {
      _error = 'Match initialize failed: $e';
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
      _error = 'Match initialize failed: $e';
      rethrow;
    }
  }

  // Live Scoring
  Future<void> setStriker(Player player) async {
    if (battingStatFor(player).isOut) {
      _error = '${player.name} is already out';
      notifyListeners();
      return;
    }
    if (_currentNonStriker?.id == player.id) _currentNonStriker = null;
    _currentStriker = player;
    notifyListeners();
    try {
      await _ensureScoringReady();
      await _matchService.setStriker(_matchId!, player.id);
      _error = null;
    } catch (e) {
      _error = 'Striker saved locally. Server sync failed: $e';
    }
    notifyListeners();
  }

  Future<void> setNonStriker(Player player) async {
    if (battingStatFor(player).isOut) {
      _error = '${player.name} is already out';
      notifyListeners();
      return;
    }
    if (_currentStriker?.id == player.id) _currentStriker = null;
    _currentNonStriker = player;
    notifyListeners();
    try {
      await _ensureScoringReady();
      await _matchService.setNonStriker(_matchId!, player.id);
      _error = null;
    } catch (e) {
      _error = 'Non-striker saved locally. Server sync failed: $e';
    }
    notifyListeners();
  }

  Future<void> setBowler(Player player) async {
    _currentBowler = player;
    notifyListeners();
    try {
      await _ensureScoringReady();
      await _matchService.setBowler(_matchId!, player.id);
      _error = null;
    } catch (e) {
      _error = 'Bowler saved locally. Server sync failed: $e';
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
    };

    _applyLocalBall(runs: runs);
    try {
      await _matchService.addBall(_matchId!, ballData);
      await refreshMatchData();
      await _syncAutoResultIfNeeded();
    } catch (e) {
      _error = 'Score saved locally. Server sync failed: $e';
      notifyListeners();
    }
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

    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'runs': runs,
      'isFour': runs == 4,
      'isSix': runs == 6,
      'wagonZone': zone,
      'wagonLabel': label,
      'comment': '$runs run${runs == 1 ? '' : 's'} through $label',
    };

    _applyLocalBall(runs: runs, wagonLabel: label);
    try {
      await _matchService.addBall(_matchId!, ballData);
      await refreshMatchData();
      await _syncAutoResultIfNeeded();
    } catch (e) {
      _error = 'Shot saved locally. Server sync failed: $e';
      notifyListeners();
    }
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
    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'runs': runs,
      apiKey: true,
      'isFreeHit': _isFreeHit,
    };
    _applyLocalBall(runs: runs, extraType: type);
    try {
      await _matchService.addBall(_matchId!, ballData);
      await refreshMatchData();
      await _syncAutoResultIfNeeded();
    } catch (e) {
      _error = 'Extra saved locally. Server sync failed: $e';
      notifyListeners();
    }
  }

  Future<void> addWicket(String wicketType) async {
    await addWicketDetailed(wicketType: wicketType);
  }

  Future<void> addWicketDetailed({
    required String wicketType,
    Player? dismissedPlayer,
    int completedRuns = 0,
  }) async {
    if (isLocallyCompleted) return;
    if (_currentStriker == null || _currentBowler == null) {
      _error = 'Set striker and bowler first';
      notifyListeners();
      return;
    }
    final dismissed = dismissedPlayer ?? _currentStriker!;
    if (_isFreeHit && !_isFreeHitWicketAllowed(wicketType)) {
      _error = 'Free hit par $wicketType out allowed nahi hai';
      notifyListeners();
      return;
    }
    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'isWicket': true,
      'wicketType': wicketType,
      'runs': completedRuns,
      'dismissedBatsmanId': dismissed.id,
      'isFreeHit': _isFreeHit,
    };
    _applyLocalBall(
      runs: completedRuns,
      wicketType: wicketType,
      dismissedPlayer: dismissed,
    );
    try {
      await _matchService.addBall(_matchId!, ballData);
      await refreshMatchData();
      await _syncAutoResultIfNeeded();
    } catch (e) {
      _error = 'Wicket saved locally. Server sync failed: $e';
      notifyListeners();
    }
  }

  bool _isFreeHitWicketAllowed(String wicketType) {
    return const {
      'run_out',
      'runOut',
      'obstructing_field',
      'handled_ball',
      'hit_ball_twice',
    }.contains(wicketType);
  }

  Future<void> startMatch() async {
    _error = null;
    notifyListeners();
    try {
      await _ensureScoringReady();
      await refreshMatchData();
    } catch (e) {
      _error = 'Match start failed: $e';
    }
    notifyListeners();
  }

  Future<void> endInnings() async {
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
          ? 'First innings end failed: $e'
          : 'Match finish failed: $e';
      notifyListeners();
    }
  }

  Future<void> _syncAutoResultIfNeeded() async {
    if (_matchId == null || _autoCompletingMatch || _localResultMessage == null) return;
    if (currentStatus == 'completed') return;

    _autoCompletingMatch = true;
    try {
      await _matchService.updateMatchResult(_matchId!, {
        'winner': _localResultMessage!.startsWith('Match tied') ? null : _winnerNameFromMessage(),
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
      _error = 'Result ready locally. Server publish failed: $e';
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
      return (value['_id'] ?? value['id'] ?? value['batsman'] ?? value['bowler'])?.toString();
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
        _battingStats[id] = PlayerBattingStat(
          runs: (raw['runs'] as num?)?.toInt() ?? 0,
          balls: (raw['balls'] as num?)?.toInt() ?? 0,
          fours: (raw['fours'] as num?)?.toInt() ?? 0,
          sixes: (raw['sixes'] as num?)?.toInt() ?? 0,
          isOut: (raw['howOut'] ?? 'not_out') != 'not_out',
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
        'noBalls': (extras['noBalls'] as num?)?.toInt() ?? _extras['noBalls'] ?? 0,
        'byes': (extras['byes'] as num?)?.toInt() ?? _extras['byes'] ?? 0,
        'legByes': (extras['legByes'] as num?)?.toInt() ?? _extras['legByes'] ?? 0,
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
      final extra = isWide ? 'Wd' : isNoBall ? 'Nb' : isBye ? 'B' : isLegBye ? 'LB' : null;
      return {
        'runs': (ball['runs'] as num?)?.toInt() ?? 0,
        'wicket': ball['wicket'] == true || ball['isWicket'] == true,
        'extra': extra,
        'wagonLabel': ball['wagonLabel']?.toString(),
        'overNumber': ball['overNumber'],
        'ballNumber': ball['ballNumber'],
      };
    }).toList();
  }

  bool _freeHitFromRecentBalls(dynamic raw) {
    if (raw is! List || raw.isEmpty) return _isFreeHit;
    final last = raw.whereType<Map>().isEmpty ? null : raw.whereType<Map>().last;
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
    String? wagonLabel,
    Player? dismissedPlayer,
  }) {
    final striker = _currentStriker;
    final bowler = _currentBowler;
    if (striker == null || bowler == null) return;

    final isWide = extraType == 'wide';
    final isNoBall = extraType == 'noBall';
    final isLegal = !isWide && !isNoBall;
    final isBye = extraType == 'bye';
    final isLegBye = extraType == 'legBye';
    final extraRuns = extraType == null
        ? 0
        : (isWide || isNoBall)
            ? 1
            : runs;
    final batsmanRuns = (isBye || isLegBye) ? 0 : runs;
    final isWicket = wicketType != null;
    final isBowlerWicket = const {
      'bowled',
      'caught',
      'lbw',
      'stumped',
      'hit_wicket',
    }.contains(wicketType);
    final totalRuns = (isBye || isLegBye) ? extraRuns : runs + extraRuns;
    final nextBalls = _legalBalls + (isLegal ? 1 : 0);
    final wasFreeHit = _isFreeHit;

    _currentScore = LiveScoreState(
      runs: _currentScore.runs + totalRuns,
      wickets: _currentScore.wickets + (isWicket ? 1 : 0),
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
                  : 'legByes';
      _extras[key] = (_extras[key] ?? 0) + extraRuns;
    }

    if (isLegal) {
      final stat = _battingStats[striker.id] ?? const PlayerBattingStat();
      final updatedBatting = stat.copyWith(
        runs: stat.runs + batsmanRuns,
        balls: stat.balls + 1,
        fours: stat.fours + (batsmanRuns == 4 ? 1 : 0),
        sixes: stat.sixes + (batsmanRuns == 6 ? 1 : 0),
        isOut: (isWicket && (dismissedPlayer?.id ?? striker.id) == striker.id) || stat.isOut,
      );
      _battingStats[striker.id] = updatedBatting;
      _recordBattingMilestone(striker, stat.runs, updatedBatting.runs);
    }

    if (isWicket && dismissedPlayer != null && dismissedPlayer.id != striker.id) {
      final dismissedStat = _battingStats[dismissedPlayer.id] ?? const PlayerBattingStat();
      _battingStats[dismissedPlayer.id] = dismissedStat.copyWith(isOut: true);
    }

    final bowlerStat = _bowlingStats[bowler.id] ?? const PlayerBowlingStat();
    final updatedBowling = bowlerStat.copyWith(
      balls: bowlerStat.balls + (isLegal ? 1 : 0),
      runs: bowlerStat.runs + totalRuns,
      wickets: bowlerStat.wickets + (isBowlerWicket ? 1 : 0),
    );
    _bowlingStats[bowler.id] = updatedBowling;
    if (isLegal) {
      _recordBowlingMoment(bowler, isBowlerWicket, updatedBowling);
    }

    _legalBalls = nextBalls;
    _currentOverBalls.add({
      'runs': runs,
      'wicket': isWicket,
      'extra': extraType == 'wide'
          ? 'Wd'
          : extraType == 'noBall'
              ? 'Nb'
              : extraType == 'bye'
                  ? 'B'
                  : extraType == 'legBye'
                      ? 'LB'
                      : wasFreeHit
                          ? 'FH'
                          : null,
      'wagonLabel': wagonLabel,
      'overNumber': _currentOver,
      'ballNumber': _currentBall,
    });
    if (_currentOverBalls.length > 8) {
      _currentOverBalls = _currentOverBalls.sublist(_currentOverBalls.length - 8);
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
    } else if (isLegal && runs.isOdd) {
      swapStrike();
    }
    if (isLegal && _currentBall == 0) {
      swapStrike();
      _currentBowler = null;
      _currentOverBalls = [];
    }
    _refreshChaseProjection();
    _updateAutomaticResultIfFinished();
    _error = null;
    notifyListeners();
  }

  void _recordBattingMilestone(Player striker, int previousRuns, int currentRuns) {
    for (final mark in const [50, 100]) {
      if (previousRuns < mark && currentRuns >= mark) {
        final key = 'bat-${striker.id}-$mark';
        if (_announcedMilestones.add(key)) {
          _appreciations.insert(0, '${striker.name} gets a brilliant $mark. Great batting.');
        }
      }
    }
    if (_appreciations.length > 6) _appreciations.removeLast();
  }

  void _recordBowlingMoment(Player bowler, bool isWicket, PlayerBowlingStat stat) {
    if (!isWicket) {
      _consecutiveWickets[bowler.id] = 0;
      return;
    }
    final streak = (_consecutiveWickets[bowler.id] ?? 0) + 1;
    _consecutiveWickets[bowler.id] = streak;
    if (streak >= 3) {
      final key = 'hat-${bowler.id}-${stat.wickets}';
      if (_announcedMilestones.add(key)) {
        _appreciations.insert(0, '${bowler.name} takes a hat-trick. Outstanding bowling.');
      }
    } else {
      final key = 'wkt-${bowler.id}-${stat.wickets}';
      if (stat.wickets >= 3 && _announcedMilestones.add(key)) {
        _appreciations.insert(0, '${bowler.name} has ${stat.wickets} wickets. Match-changing spell.');
      }
    }
    if (_appreciations.length > 6) _appreciations.removeLast();
  }

  void _refreshChaseProjection() {
    if (!isSecondInnings) return;
    final chaseTarget = target;
    if (chaseTarget == null) return;
    _localTarget = chaseTarget;
    final ballsLeft = (_maxBalls - _legalBalls).clamp(0, _maxBalls);
    final runsLeft = (chaseTarget - _currentScore.runs).clamp(0, 9999);
    final rrr = ballsLeft == 0 ? null : ((runsLeft * 6) / ballsLeft).toStringAsFixed(2);
    _currentScore = LiveScoreState(
      runs: _currentScore.runs,
      wickets: _currentScore.wickets,
      overs: _currentScore.overs,
      runRate: _currentScore.runRate,
      requiredRR: rrr,
    );
  }

  void _updateAutomaticResultIfFinished() {
    if (!isSecondInnings || _localResultMessage != null) return;
    final chaseTarget = target;
    if (chaseTarget == null) return;

    final chasingTeam = _secondInningsBattingTeamName;
    final defendingTeam = _firstInningsBattingTeamName;
    if (_currentScore.runs >= chaseTarget) {
      final wicketsLeft = (10 - _currentScore.wickets).clamp(0, 10);
      _localResultMessage = '$chasingTeam won by $wicketsLeft wicket${wicketsLeft == 1 ? '' : 's'}';
    } else if (_currentScore.wickets >= 10 || _legalBalls >= _maxBalls) {
      final firstInningsRuns = chaseTarget - 1;
      if (_currentScore.runs == firstInningsRuns) {
        _localResultMessage = 'Match tied';
      } else {
        final margin = firstInningsRuns - _currentScore.runs;
        _localResultMessage = '$defendingTeam won by $margin run${margin == 1 ? '' : 's'}';
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
      final score = bat.runs + (bat.fours * 2) + (bat.sixes * 3) + (bowl.wickets * 25) - (bowl.runs ~/ 10);
      if (score > bestScore) {
        bestScore = score;
        bestPlayer = player;
      }
    }
    return bestPlayer?.name;
  }

  void swapStrike() {
    final oldStriker = _currentStriker;
    _currentStriker = _currentNonStriker;
    _currentNonStriker = oldStriker;
  }

  String _formatOvers(int balls) => '${balls ~/ 6}.${balls % 6}';

  double _calculateRunRate(int runs, int balls) {
    if (balls <= 0) return 0;
    return runs / (balls / 6);
  }
}
