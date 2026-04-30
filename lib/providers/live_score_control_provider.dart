import 'package:flutter/foundation.dart';
import '../data/services/match_service.dart';
import '../data/services/team_service.dart';
import '../data/services/player_service.dart';
import '../data/models/match_model.dart';
import '../data/models/player_model.dart';
import '../core/services/socket_service.dart';
import 'scorecard_provider.dart';

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

class LiveScoreControlProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  final TeamService _teamService = TeamService();
  final PlayerService _playerService = PlayerService();
  final SocketService _socketService = SocketService();

  // State
  String? _matchId;
  Match? _match;
  String? _userRole;
  bool _isLoading = false;
  String? _error;

  // Toss
  String? _tossWinnerKey;
  String? get tossWinnerKey => _tossWinnerKey;
  String? _tossWinner;
  String? _tossDecision;
  bool get tossDone => _tossWinnerKey != null && _tossDecision != null;
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

  List<Map<String, dynamic>> _currentOverBalls = [];
  int _currentOver = 1;
  int _currentBall = 1;
  int get currentBall => _currentBall;
  Map<String, int> _extras = {'wides': 0, 'noBalls': 0, 'byes': 0, 'legByes': 0};

  // Getters
  String? get matchId => _matchId;
  Match? get match => _match;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LiveScoreState get currentScore => _currentScore;
  String get currentStatus => _match?.status ?? 'scheduled';
  bool get canStartMatch => currentStatus == 'ready' && _selectedTeam1Players.length == 11 && _selectedTeam2Players.length == 11 && tossDone;
  bool get canInitialize => _selectedTeam1Players.length == 11 && _selectedTeam2Players.length == 11;
  bool get canEndInnings => currentStatus == 'live';

  List<Player> get team1Players => _team1Players;
  List<Player> get team2Players => _team2Players;
  List<Player> get selectedTeam1Players => _selectedTeam1Players;
  List<Player> get selectedTeam2Players => _selectedTeam2Players;

  Player? get currentStriker => _currentStriker;
  Player? get currentNonStriker => _currentNonStriker;
  Player? get currentBowler => _currentBowler;
  List<Map<String, dynamic>> get currentOverBalls => _currentOverBalls;
  String get currentOver => '$_currentOver.$_currentBall';
  int get team1SelectedCount => _selectedTeam1Players.length;
  int get team2SelectedCount => _selectedTeam2Players.length;
  Map<String, int> get extras => _extras;
  String? get tossWinnerName => _tossWinnerKey == 'team1' ? _match?.team1 : _match?.team2;
  String get tossDecisionDisplay => _tossDecision == 'bat' ? 'Bat First' : 'Bowl First';
  List<Player> get battingTeamPlayers => _tossWinnerKey == 'team1' && _tossDecision == 'bat' || _tossWinnerKey == 'team2' && _tossDecision == 'bowl' ? _team1Players : _team2Players;
  double? get requiredRR => _currentScore.requiredRR != null ? double.tryParse(_currentScore.requiredRR!) : null;
  bool get canRefresh => !_isLoading;

  LiveScoreControlProvider();

  void setUserRole(String? role) {
    _userRole = role;
    notifyListeners();
  }

  Future<void> initialize(String matchId, Match? match) async {
    _matchId = matchId;
    _match = match;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadTeamPlayers(),
        _loadLiveData(),
        _setupSocketListeners(),
      ]);
    } catch (e) {
      _error = 'Failed to initialize: $e';
      debugPrint('❌ Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTeamPlayers() async {
    if (_match == null) return;

    final team1Players = await _playerService.getPlayersByTeam(_match!.team1);
    final team2Players = await _playerService.getPlayersByTeam(_match!.team2);
    
    _team1Players = team1Players.where((p) => ['batsman', 'allrounder', 'wicketkeeper'].contains(p.role?.toLowerCase())).toList();
    _team2Players = team2Players.where((p) => ['batsman', 'allrounder', 'wicketkeeper'].contains(p.role?.toLowerCase())).toList();
    notifyListeners();
  }

  Future<void> _loadLiveData() async {
    if (_matchId == null) return;

    final liveData = await _matchService.getLiveScore(_matchId!);
    _currentScore = LiveScoreState(
      runs: liveData['scorecard']['runs'] ?? 0,
      wickets: liveData['scorecard']['wickets'] ?? 0,
      overs: liveData['scorecard']['overs'] ?? '0.0',
      runRate: double.tryParse(liveData['scorecard']['runRate'] ?? '0.00') ?? 0.0,
      requiredRR: liveData['requiredRunRate'],
    );

    final strikerId = liveData['currentStriker'];
    final nonStrikerId = liveData['currentNonStriker'];
    final bowlerId = liveData['currentBowler'];

    if (strikerId != null) {
      final striker = _team1Players.firstWhere(
        (p) => p.id == strikerId, 
        orElse: () => _team2Players.firstWhere(
          (p) => p.id == strikerId, 
          orElse: () => _createDummyPlayer(strikerId, 'Unknown', 'batsman')
        )
      );
      _currentStriker = striker;
    }
    if (nonStrikerId != null) {
      final nonStriker = _team1Players.firstWhere(
        (p) => p.id == nonStrikerId, 
        orElse: () => _team2Players.firstWhere(
          (p) => p.id == nonStrikerId, 
          orElse: () => _createDummyPlayer(nonStrikerId, 'Unknown', 'batsman')
        )
      );
      _currentNonStriker = nonStriker;
    }
    if (bowlerId != null) {
      final bowler = _team1Players.firstWhere(
        (p) => p.id == bowlerId, 
        orElse: () => _team2Players.firstWhere(
          (p) => p.id == bowlerId, 
          orElse: () => _createDummyPlayer(bowlerId, 'Unknown', 'bowler')
        )
      );
      _currentBowler = bowler;
    }

    _currentOverBalls = List<Map<String, dynamic>>.from(liveData['recentBalls'] ?? []);
    notifyListeners();
  }
  
  // Helper method to create a dummy player when player not found
  Player _createDummyPlayer(String id, String name, String role) {
    return Player(
      id: id,
      name: name,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> refreshLiveData() async {
    await _loadLiveData();
  }

  Future<void> _setupSocketListeners() async {
    _socketService.onLiveScoreUpdate((data) {
      if (data['matchId'] == _matchId) {
        _updateFromSocket(data);
      }
    });
  }

  void _updateFromSocket(Map<String, dynamic> data) {
    _currentScore = LiveScoreState(
      runs: data['currentInnings']['totalRuns'] ?? _currentScore.runs,
      wickets: data['currentInnings']['totalWickets'] ?? _currentScore.wickets,
      overs: data['currentInnings']['overs'] ?? _currentScore.overs,
      runRate: data['currentInnings']['runRate']?.toDouble() ?? _currentScore.runRate,
    );
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
    if (_tossWinnerKey == null || _tossDecision == null) return;

    try {
      await _matchService.updateToss(_matchId!, _tossWinnerKey!, _tossDecision!);
    } catch (e) {
      _error = 'Toss update failed: $e';
    }
    notifyListeners();
  }

  // XI Selection
  void toggleTeam1Player(Player player) {
    if (_selectedTeam1Players.any((p) => p.id == player.id)) {
      _selectedTeam1Players.removeWhere((p) => p.id == player.id);
    } else if (_selectedTeam1Players.length < 11) {
      _selectedTeam1Players.add(player);
    }
    notifyListeners();
  }

  void toggleTeam2Player(Player player) {
    if (_selectedTeam2Players.any((p) => p.id == player.id)) {
      _selectedTeam2Players.removeWhere((p) => p.id == player.id);
    } else if (_selectedTeam2Players.length < 11) {
      _selectedTeam2Players.add(player);
    }
    notifyListeners();
  }

  Future<void> initializeMatch() async {
    final battingOrder = [
      {'team': _match!.team1, 'players': _selectedTeam1Players.map((p) => p.id).toList()},
      {'team': _match!.team2, 'players': _selectedTeam2Players.map((p) => p.id).toList()},
    ];
    await _matchService.initializeMatch(_matchId!, battingOrder);
  }

  // Live Scoring
  Future<void> setStriker(Player player) async {
    _currentStriker = player;
    await _matchService.setStriker(_matchId!, player.id);
    notifyListeners();
  }

  Future<void> setNonStriker(Player player) async {
    _currentNonStriker = player;
    await _matchService.setNonStriker(_matchId!, player.id);
    notifyListeners();
  }

  Future<void> setBowler(Player player) async {
    _currentBowler = player;
    await _matchService.setBowler(_matchId!, player.id);
    notifyListeners();
  }

  Future<void> addRuns(int runs) async {
    if (_currentStriker == null || _currentBowler == null) {
      _error = 'Set striker and bowler first';
      return;
    }

    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'runs': runs,
    };

    await _matchService.addBall(_matchId!, ballData);
  }

  Future<void> addExtra(String type) async {
    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker?.id ?? '',
      'bowlerId': _currentBowler?.id ?? '',
      'runs': 1,
      'is$type': true,
    };
    await _matchService.addBall(_matchId!, ballData);
  }

  Future<void> addWicket(String wicketType) async {
    final ballData = <String, dynamic>{
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'isWicket': true,
      'wicketType': wicketType,
      'runs': 0,
    };
    await _matchService.addBall(_matchId!, ballData);
  }

  Future<void> startMatch() async {
    await _matchService.updateMatchStatus(_matchId!, 'live');
  }

  Future<void> endInnings() async {
    await _matchService.endInnings(_matchId!);
  }

  @override
  void dispose() {
    _socketService.offLiveScoreUpdate();
    super.dispose();
  }
}