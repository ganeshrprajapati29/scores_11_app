class AppRoutes {
  // Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  
  // Players
  static const String publicPlayers = '/public-players';
  
  // Matches
  static const String matches = '/matches';
  static const String matchDetail = '/match/:id';
  static const String createMatch = '/create-match';
  static const String createMatchEnhanced = '/create-match-enhanced';
  static const String liveMatch = '/live-match/:id';
  static const String scoreEntry = '/score-entry/:id';
  static const String scorecard = '/scorecard/:id';
  static const String toss = '/toss/:id';
  
// Tournaments
  static const String tournaments = '/tournaments';
  static const String tournamentDetail = '/tournament/:id';
  static const String createTournament = '/create-tournament';
  static const String pointsTable = '/points-table/:id';
  
  // Live Control
  static const String teamSelect = '/team-select/:id';
  static const String wagonWheel = '/wagon-wheel/:id';
  static const String initializeLive = '/initialize-live/:id';
  static const String lineups = '/lineups/:id';
  
  // Teams
  static const String teams = '/teams';
  static const String teamDetail = '/team/:id';
  static const String createTeam = '/create-team';
  
  // Profile
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String myPerformance = '/my-performance';
  static const String wallet = '/wallet';
  static const String subscription = '/subscription';
  
  // Community
  static const String community = '/community';
  static const String createPost = '/create-post';
  static const String postDetail = '/post/:id';
  // Blogs
  static const String blogs = '/blogs';
  static const String blogDetail = '/blog/:id';
  
  // Store
  static const String store = '/store';
  static const String productDetail = '/product/:id';
  static const String cart = '/cart';
  static const String orders = '/orders';
  
  // Settings
  static const String settings = '/settings';
  static const String changePassword = '/change-password';
  static const String privacyPolicy = '/privacy-policy';
  
  // Helper
  static String matchDetailRoute(String id) => '/match/$id';
  static String tournamentDetailRoute(String id) => '/tournament/$id';
  static String teamDetailRoute(String id) => '/team/$id';
  static String liveMatchRoute(String id) => '/live-match/$id';
  static String scoreEntryRoute(String id) => '/score-entry/$id';
  static String scorecardRoute(String id) => '/scorecard/$id';
  static const String liveScoreControl = '/live-control/:id';
  static String liveScoreControlRoute(String id) => '/live-control/$id';
  static String pointsTableRoute(String id) => '/points-table/$id';
  static String productDetailRoute(String id) => '/product/$id';
  static String postDetailRoute(String id) => '/post/$id';
  static String blogsRoute() => blogs;
static String blogDetailRoute(String id) => blogDetail.replaceAll(':id', id);
  
  // Live Control Helper Methods
  static String teamSelectRoute(String id) => '/team-select/$id';
  static String wagonWheelRoute(String id) => '/wagon-wheel/$id';
  static String initializeLiveRoute(String id) => '/initialize-live/$id';
  static String lineupsRoute(String id) => '/lineups/$id';
  static String tossRoute(String id) => '/toss/$id';
}
