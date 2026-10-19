import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scores11/data/models/match_model.dart';
import 'package:scores11/data/models/player_model.dart';
import 'package:scores11/data/services/match_service.dart';
import 'package:scores11/data/services/player_service.dart';
import 'package:scores11/data/services/team_service.dart';
import 'package:scores11/providers/live_score_control_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A server that can be switched off, can lose a response, can refuse a
/// ball, and - like the real backend - ignores a re-sent clientBallId.
class FakeServer extends MatchService {
  bool online = true;
  bool loseNextResponse = false;
  String? rejectNextBall;
  int runs = 0;
  int legalBalls = 0;
  final Set<String> recorded = {};
  final List<Map<String, dynamic>> roleCalls = [];

  DioException _offline() => DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );

  Map<String, dynamic> _team(String id, String prefix) => {
        '_id': id,
        'name': prefix == 'A' ? 'Alpha' : 'Bravo',
        'players': [
          for (var i = 1; i <= 11; i++) {'_id': '$prefix$i', 'name': '$prefix$i', 'role': 'batsman'},
        ],
      };

  @override
  Future<Match> getMatchById(String id, {bool forceRefresh = false}) async {
    if (!online) throw _offline();
    return Match.fromJson({
      '_id': id,
      'team1': _team('t1', 'A'),
      'team2': _team('t2', 'B'),
      'status': 'live',
      'format': 't20',
      'overs': 20,
      'currentInnings': 1,
      'scheduledDate': DateTime(2026, 10, 16).toIso8601String(),
      'toss': {'winner': 't1', 'decision': 'bat'},
      'innings': [
        {'inningsNumber': 1, 'battingTeam': 't1', 'bowlingTeam': 't2', 'totalRuns': runs},
      ],
    });
  }

  @override
  Future<Map<String, dynamic>> getLiveScore(String matchId) async {
    if (!online) throw _offline();
    return {
      'scorecard': {
        'runs': runs,
        'wickets': 0,
        'overs': '${legalBalls ~/ 6}.${legalBalls % 6}',
        'runRate': '0.00',
        'battingScorecard': [],
        'bowlingScorecard': [],
      },
      'currentStriker': 'A1',
      'currentNonStriker': 'A2',
      'currentBowler': 'B11',
      'recentBalls': [],
    };
  }

  @override
  Future<Map<String, dynamic>> addBall(String matchId, Map<String, dynamic> ballData) async {
    if (!online) throw _offline();
    if (rejectNextBall != null) {
      final message = rejectNextBall!;
      rejectNextBall = null;
      throw DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: {'message': message},
        ),
      );
    }
    final id = ballData['clientBallId']?.toString();
    if (id == null || !recorded.contains(id)) {
      if (id != null) recorded.add(id);
      runs += (ballData['runs'] as num).toInt();
      legalBalls += 1;
    }
    if (loseNextResponse) {
      loseNextResponse = false;
      throw DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      );
    }
    return {};
  }

  @override
  Future<void> sendScoringRoleRaw(String matchId, String role, String playerId) async {
    if (!online) throw _offline();
    roleCalls.add({'role': role, 'playerId': playerId});
  }
}

class NoNetworkPlayers extends PlayerService {
  @override
  Future<List<Player>> getPlayersByTeam(String teamId) async => [];
}

class NoNetworkTeams extends TeamService {
  @override
  Future<Map<String, dynamic>> getTeamWithPlayers(String id) async => {};
}

LiveScoreControlProvider makeProvider(FakeServer server) => LiveScoreControlProvider(
      matchService: server,
      playerService: NoNetworkPlayers(),
      teamService: NoNetworkTeams(),
      realtime: false,
    );

Future<void> setRoles(LiveScoreControlProvider p) async {
  Player byId(String id) => p.team1Players.followedBy(p.team2Players).firstWhere((x) => x.id == id);
  await p.setStriker(byId('A1'));
  await p.setNonStriker(byId('A2'));
  await p.setBowler(byId('B11'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('scores online, keeps scoring offline, survives a restart and syncs once', () async {
    final server = FakeServer();
    final p = makeProvider(server);
    await p.initialize('m1', null);
    await setRoles(p);

    await p.addRuns(4);
    expect(server.runs, 4);
    expect(p.currentScore.runs, 4);
    expect(p.pendingSyncCount, 0);

    // Internet drops: balls stay on the phone and on screen.
    server.online = false;
    await p.addRuns(1);
    await p.addRuns(2);
    expect(p.currentScore.runs, 7);
    expect(p.pendingBallCount, 2);
    expect(p.isOffline, isTrue);
    expect(server.runs, 4);
    p.dispose();

    // Phone restarts while still offline: same score, same queue.
    final restarted = makeProvider(server);
    await restarted.initialize('m1', null);
    expect(restarted.error, isNull);
    expect(restarted.currentScore.runs, 7);
    expect(restarted.pendingBallCount, 2);

    // Connection back, but the reply to the first ball is lost.
    server.online = true;
    server.loseNextResponse = true;
    await restarted.retrySync();
    expect(server.runs, 5, reason: 'first queued ball reached the server');
    expect(restarted.pendingBallCount, 2, reason: 'without a reply it is sent again');

    await restarted.retrySync();
    expect(server.runs, 7, reason: 'the re-send is not counted twice');
    expect(restarted.pendingSyncCount, 0);
    expect(restarted.currentScore.runs, 7);
    restarted.dispose();
  });

  test('undo of an unsynced ball happens on the phone', () async {
    final server = FakeServer();
    final p = makeProvider(server);
    await p.initialize('m2', null);
    await setRoles(p);
    await p.addRuns(4);

    server.online = false;
    await p.addRuns(6);
    expect(p.currentScore.runs, 10);
    final undone = await p.undoLastBall();
    expect(undone, isTrue);
    expect(p.currentScore.runs, 4);
    expect(p.pendingBallCount, 0);
    expect(server.runs, 4);
    p.dispose();
  });

  test('a ball the server refuses is reported, not silently lost', () async {
    final server = FakeServer();
    final p = makeProvider(server);
    await p.initialize('m3', null);
    await setRoles(p);
    await p.addRuns(2);

    server.rejectNextBall = 'Select a new bowler for the next over';
    await p.addRuns(4);
    expect(p.error, contains('Select a new bowler'));
    expect(server.runs, 2);
    expect(p.currentScore.runs, 2, reason: 'screen goes back to the server score');
    expect(p.pendingSyncCount, 0);

    // Offline balls queued after a refused one wait for the scorer.
    server.online = false;
    await p.addRuns(1);
    await p.addRuns(1);
    server.online = true;
    server.rejectNextBall = 'Batter already out';
    await p.retrySync();
    expect(p.rejectedAction, isNotNull);
    expect(p.pendingBallCount, 2);
    await p.discardRejectedAction();
    expect(server.runs, 3, reason: 'remaining ball synced after discarding the refused one');
    expect(p.pendingSyncCount, 0);
    p.dispose();
  });

  test('server-only actions wait while balls are unsynced', () async {
    final server = FakeServer();
    final p = makeProvider(server);
    await p.initialize('m4', null);
    await setRoles(p);
    server.online = false;
    await p.addRuns(1);
    await p.endInnings();
    expect(p.error, contains('saved only on this phone'));
    p.dispose();
  });
}
