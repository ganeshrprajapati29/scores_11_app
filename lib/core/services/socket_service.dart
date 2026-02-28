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
  void joinMatchRoom(String matchId) {
    emit('join_match', {'matchId': matchId});
  }

  void leaveMatchRoom(String matchId) {
    emit('leave_match', {'matchId': matchId});
  }

  // Tournament events
  void joinTournamentRoom(String tournamentId) {
    emit('join_tournament', {'tournamentId': tournamentId});
  }

  void leaveTournamentRoom(String tournamentId) {
    emit('leave_tournament', {'tournamentId': tournamentId});
  }
}
