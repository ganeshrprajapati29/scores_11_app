import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/socket_config.dart';
import 'storage_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null) return;
    
    final token = await StorageService().getAccessToken();
    
    _socket = io.io(
      SocketConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token ?? ''})
          .enableReconnection()
          .setReconnectionAttempts(SocketConfig.reconnectionAttempts)
          .setReconnectionDelay(SocketConfig.reconnectionDelay)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('Socket disconnected');
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
  }

  // Match events
  void joinMatch(String matchId) {
    emit('joinMatch', matchId);
  }

  void leaveMatch(String matchId) {
    emit('leaveMatch', matchId);
  }

  // Live score listeners
  void onLiveScoreUpdate(Function(dynamic) callback) {
    on('liveScoreUpdate', callback);
  }

  void offLiveScoreUpdate() {
    off('liveScoreUpdate');
  }

  void authenticateUser(String userId) {
    if (userId.trim().isEmpty) return;
    emit('authenticate', userId);
  }

  void onNotification(Function(dynamic) callback) {
    on('notification', callback);
    on('notification:new', callback);
  }

  void offNotification() {
    off('notification');
    off('notification:new');
  }

  void onNotificationCount(Function(dynamic) callback) {
    on('notification:count', callback);
  }

  void offNotificationCount() {
    off('notification:count');
  }

  // Tournament events
  void joinTournamentRoom(String tournamentId) {
    emit('join_tournament', {'tournamentId': tournamentId});
  }

  void leaveTournamentRoom(String tournamentId) {
    emit('leave_tournament', {'tournamentId': tournamentId});
  }
}
