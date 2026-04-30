class ApiConfig {
// Production remote backend (currently unreachable)
// Change this to your backend URL
  // Production remote backend  
  static const String baseUrl = 'http://68.178.171.95:3000/api/v1';

  // ✅ LOCAL DEVELOPMENT - Backend runs on localhost:3000
  // static const String baseUrl = 'http://localhost:3000/api/v1';
  
  // To switch: Run `cd backend && npm start`, then uncomment localhost line above
  
  // Socket URL
  static const String socketUrl = 'http://68.178.171.95:3000';
  static const String agoraAppId = '5b430e042a88490eb9f292c4a05ab339';
  static const String agoraAppCertificate = 'd5d648b3f5b048eb830f921471c7e116';
  
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
  static const String upload = '/upload';
  static const String discovery = '/discovery';
  static const String liveStreams = '/live-streams';
  static const String search = '/search';
  static const String banners = '/banners';
  static const String featureToggles = '/feature-toggles';
  static const String admin = '/admin';
  static const String dashboard = '/dashboard';
  
  // Timeouts
  static const int connectionTimeout = 45000;
  static const int receiveTimeout = 45000;
}

