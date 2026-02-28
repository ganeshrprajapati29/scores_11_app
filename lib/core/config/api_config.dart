class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Socket URL
  static const String socketUrl = 'http://localhost:3000';
  
  // Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String teams = '/teams';
  static const String players = '/players';
  static const String matches = '/matches';
  static const String scoring = '/scoring';
  static const String tournaments = '/tournaments';
  static const String contests = '/contests';
  static const String leaderboard = '/leaderboard';
  static const String wallet = '/wallet';
  static const String notifications = '/notifications';
  static const String profiles = '/profiles';
  static const String blogs = '/blogs';
  static const String news = '/news';
  static const String community = '/community';
  static const String store = '/store';
  static const String contact = '/contact';
  static const String reviews = '/reviews';
  static const String performance = '/performance';
  static const String clubs = '/clubs';
  static const String associations = '/associations';
  static const String awards = '/awards';
  static const String subscriptions = '/subscriptions';
  static const String settings = '/settings';
  
  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}
