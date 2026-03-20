class AppConfig {
  // App Info
  static const String appName = 'Scores11';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
  
  // Environment
  static const bool isProduction = false;
  static const bool enableDebugLogs = true;
  
  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableSocketConnection = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  
  // Cache Config
  static const int cacheMaxAge = 7; // days
  static const int maxCacheSize = 100; // MB
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Upload
  static const int maxImageSize = 5; // MB
  static const int maxVideoSize = 50; // MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedVideoExtensions = ['mp4', 'mov', 'avi'];
  
  // Timeouts
  static const int connectionTimeout = 30000; // ms
  static const int receiveTimeout = 30000; // ms
  static const int sendTimeout = 30000; // ms
  
  // Match Update Interval
  static const int matchUpdateInterval = 10000; // ms (10 seconds)
  static const int scoreUpdateInterval = 5000; // ms (5 seconds)
}
