import '../config/api_config.dart';

class SocketConfig {
  static const String socketUrl = ApiConfig.socketUrl;
  
  // Socket events
  static const String connectEvent = 'connect';
  static const String disconnectEvent = 'disconnect';
  static const String matchUpdateEvent = 'match_update';
  static const String scoreUpdateEvent = 'score_update';
  static const String notificationEvent = 'notification';
  static const String chatMessageEvent = 'chat_message';
  
  // Connection config
  static const int connectionTimeout = 5000;
  static const bool autoConnect = true;
  static const bool reconnection = true;
  static const int reconnectionAttempts = 5;
  static const int reconnectionDelay = 3000;
}
