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

class PlayerSelection {
  final String id;
  final String name;
  final int? jerseyNumber;
  final String? role;

  PlayerSelection({
    required this.id,
    required this.name,
    this.jerseyNumber,
    this.role,
  });

  factory PlayerSelection.fromPlayer(Player player) => PlayerSelection(
    id: player.id,
    name: player.name,
    jerseyNumber: player.jerseyNumber,
    role: player.role,
  );
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
  String? _tossWinner;
  String? _tossDecision;
  bool get tossDone => _tossWinner != null && _tossDecision != null;

  // Playing XI
  List<Player> _team1Players = [];
  List<Player> _team2Players = [];
  List<PlayerSelection> _selectedTeam1Players = [];
  List<PlayerSelection> _selectedTeam2Players = [];

  // Live state
  LiveScoreState _currentScore = const LiveScoreState();
  PlayerSelection? _currentStriker;
  PlayerSelection? _currentNonStriker;
  PlayerSelection? _currentBowler;
  List<Map<String, dynamic>> _currentOverBalls = [];
  int _currentOver = 1;
  int _currentBall = 1;
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
  List<PlayerSelection> get selectedTeam1Players => _selectedTeam1Players;
  List<PlayerSelection> get selectedTeam2Players => _selectedTeam2Players;
  PlayerSelection? get currentStriker => _currentStriker;
  PlayerSelection? get currentNonStriker => _currentNonStriker;
  PlayerSelection? get currentBowler => _currentBowler;
  List<Map<String, dynamic>> get currentOverBalls => _currentOverBalls;
  String get currentOver => '$_currentOver.$_currentBall';
  int get team1SelectedCount => _selectedTeam1Players.length;
  int get team2SelectedCount => _selectedTeam2Players.length;
  Map<String, int> get extras => _extras;
  String? get tossWinnerName => _match?.team1.id == _tossWinner ? _match?.team1.name : _match?.team2.name;
  String get tossDecisionDisplay => _tossDecision == 'bat' ? 'Bat First' : 'Bowl First';
  List<Player> get battingTeamPlayers => _match?.team1.id == _tossWinner && _tossDecision == 'bat' || _match?.team2.id == _tossWinner && _tossDecision == 'bowl' 
      ? _team1Players : _team2Players; // Simplified
  double? get requiredRR => _currentScore.requiredRR != null ? double.tryParse(_currentScore.requiredRR!) : null;
  bool get canRefresh => !_isLoading;

  LiveScoreControlProvider();

  void setUserRole(String? role) {
    _userRole = role;
    if (role != 'admin' && role != 'umpire') {
      _error = 'Admin/Umpire role required for live scoring';
    }
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

    final team1Players = await _playerService.getPlayersByTeam(_match!.team1.id);
    final team2Players = await _playerService.getPlayersByTeam(_match!.team2.id);
    
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
      final striker = _team1Players.firstWhere((p) => p.id == strikerId, orElse: () => _team2Players.firstWhere((p) => p.id == strikerId));
      _currentStriker = PlayerSelection.fromPlayer(striker);
    }
    // Similar for non-striker, bowler

    _currentOverBalls = List<Map<String, dynamic>>.from(liveData['recentBalls'] ?? []);
    notifyListeners();
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
    );
    notifyListeners();
  }

  // Toss Methods
  void setTossWinner(String winner) {
    _tossWinner = winner == 'team1' ? _match!.team1.id : _match!.team2.id;
    notifyListeners();
  }

  void setTossDecision(String decision) {
    _tossDecision = decision;
    notifyListeners();
  }

  Future<void> submitToss() async {
    if (_tossWinner == null || _tossDecision == null) return;

    try {
      await _matchService.updateToss(_matchId!, _tossWinner!, _tossDecision!);
      // Socket will update UI
    } catch (e) {
      _error = 'Toss update failed: $e';
    }
    notifyListeners();
  }

  // XI Selection
  void toggleTeam1Player(Player player) {
    final selection = PlayerSelection.fromPlayer(player);
    if (_selectedTeam1Players.any((p) => p.id == player.id)) {
      _selectedTeam1Players.removeWhere((p) => p.id == player.id);
    } else if (_selectedTeam1Players.length < 11) {
      _selectedTeam1Players.add(selection);
    }
    notifyListeners();
  }

  void toggleTeam2Player(Player player) {
    final selection = PlayerSelection.fromPlayer(player);
    if (_selectedTeam2Players.any((p) => p.id == player.id)) {
      _selectedTeam2Players.removeWhere((p) => p.id == player.id);
    } else if (_selectedTeam2Players.length < 11) {
      _selectedTeam2Players.add(selection);
    }
    notifyListeners();
  }

  Future<void> initializeMatch() async {
    final battingOrder = [
      {'team': _match!.team1.id, 'players': _selectedTeam1Players.map((p) => p.id).toList()},
      {'team': _match!.team2.id, 'players': _selectedTeam2Players.map((p) => p.id).toList()},
    ];
    await _matchService.initializeMatch(_matchId!, battingOrder);
  }

  // Live Scoring
  Future<void> setStriker(Player player) {
    _currentStriker = PlayerSelection.fromPlayer(player);
    await _matchService.setStriker(_matchId!, player.id);
    notifyListeners();
  }

  Future<void> setNonStriker(Player player) async {
    _currentNonStriker = PlayerSelection.fromPlayer(player);
    await _matchService.setNonStriker(_matchId!, player.id);
    notifyListeners();
  }

  Future<void> setBowler(Player player) async {
    _currentBowler = PlayerSelection.fromPlayer(player);
    await _matchService.setBowler(_matchId!, player.id);
    notifyListeners();
  }

  Future<void> addRuns(int runs) async {
    if (_currentStriker == null || _currentBowler == null) {
      _error = 'Set striker and bowler first';
      return;
    }

    final ballData = {
      'batsmanId': _currentStriker!.id,
      'bowlerId': _currentBowler!.id,
      'runs': runs,
      'expectedVersion': _match?.version,
    };

    await _matchService.addBall(_matchId!, ballData);
  }

  Future<void> addExtra(String type) async {
    final ballData = {
      'batsmanId': _currentStriker?.id ?? '',
      'bowlerId': _currentBowler?.id ?? '',
      'runs': 1,
      ['is$type']: true,
    };
    await _matchService.addBall(_matchId!, ballData);
  }

  Future<void> addWicket(String wicketType) async {
    final ballData = {
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

