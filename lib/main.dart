import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/theme_config.dart';
import 'core/services/cache_service.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/scorecard_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/otp_verification_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/complete_profile_screen.dart';
import 'features/auth/phone_login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/goLive/go_live_screen.dart';
import 'features/tournaments/tournament_detail_screen.dart';
import 'features/tournaments/tournament_list_screen.dart';
import 'features/tournaments/points_table_screen.dart';
import 'features/tournaments/fixtures_screen.dart';
import 'features/tournaments/create_tournament_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/cricket_profile_screen.dart';
import 'features/matches/match_list_screen.dart';
import 'features/matches/match_detail_screen.dart';
import 'features/matches/live_match_screen.dart';
import 'features/matches/score_entry_screen.dart';
import 'features/matches/create_match_screen.dart';
import 'features/matches/scorecard_screen.dart';
import 'features/matches/team_selection_screen.dart';
import 'features/matches/wagon_wheel_screen.dart';
import 'features/matches/live_score_control_screen.dart';
import 'features/matches/toss_screen.dart';
import 'features/teams/team_list_screen.dart';
import 'features/teams/team_detail_screen.dart';
import 'features/teams/create_team_screen.dart';
import 'features/players/player_search_screen.dart';
import 'features/players/player_list_screen.dart';
import 'features/players/create_player_screen.dart';
import 'features/leaderboard/top_batsman_screen.dart';
import 'features/store/store_home_screen.dart';
import 'features/store/product_detail_screen.dart';
import 'features/store/cart_screen.dart';
import 'features/store/checkout_screen.dart';
import 'features/store/orders_screen.dart';
import 'features/community/community_feed_screen.dart';
import 'features/community/create_post_screen.dart';
import 'features/community/post_detail_screen.dart';
import 'features/settings/app_settings_screen.dart';
import 'features/settings/notification_settings_screen.dart';
import 'features/settings/privacy_settings_screen.dart';
import 'features/settings/preferences_screen.dart';
import 'features/settings/security_screen.dart';
import 'features/settings/privacy_policy_screen.dart';
import 'features/settings/help_support_screen.dart';
import 'features/dashboard/testing_screen.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/subscription/subscription_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/blogs/blogs_screen.dart';
import 'features/live_stream/live_player_screen.dart';
import 'features/profile/connections_screen.dart';
import 'features/chat/chat_list_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/players/player_profile_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Cric11App());
}

class Cric11App extends StatelessWidget {
  const Cric11App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ScorecardProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
      ],
      child: MaterialApp(
        title: 'Scores11',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
themeMode: ThemeMode.light,
onGenerateRoute: (RouteSettings settings) {
          // Handle dynamic player profile route: /player-profile/:id
          if (settings.name!.startsWith('/player-profile/')) {
            final parts = settings.name!.split('/');
            final playerId = parts.length > 2 ? parts[2] : '';
            return MaterialPageRoute(
              builder: (context) => PlayerProfileScreen(playerId: playerId),
              settings: settings,
            );
          }
          // Handle dynamic match route: /match/:id
          if (settings.name!.startsWith('/match/')) {
            final uri = Uri.parse(settings.name!);
            final pathSegments = uri.pathSegments;
            final matchId = pathSegments.isNotEmpty ? pathSegments.last : '';
            return MaterialPageRoute(
              builder: (context) => MatchDetailScreen(matchId: matchId),
              settings: settings,
            );
          }
          return null;
        },
        home: const SplashScreen(),
        routes: {
          // Auth Routes
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/otp-verification': (context) => OTPVerificationScreen(
            identifier: '',
            onVerify: (code) {},
            onResend: () {},
          ),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/complete-profile': (context) => const CompleteProfileScreen(),
          '/phone-login': (context) => const PhoneLoginScreen(),

          // Main Screens
          '/dashboard': (context) => const DashboardScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/cricket-profile': (context) => const CricketProfileScreen(),

// Match Routes
          '/matches': (context) => const MatchListScreen(),
          '/matches/live': (context) => const MatchListScreen(),
          '/match-detail': (context) {
            final matchId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
            return MatchDetailScreen(matchId: matchId);
          },
          '/create-match': (context) => const CreateMatchScreen(),
// '/create-match-enhanced': (context) => CreateMatchScreen(), // Temporarily disabled - class not found
          '/live-match': (context) => const LiveMatchScreen(matchId: ''),
          '/score-entry': (context) => const ScoreEntryScreen(matchId: ''),
          '/scorecard': (context) => ScorecardScreen(
            matchId: ModalRoute.of(context)!.settings.arguments as String? ?? '',
          ),
          
          // Live Control Routes (new)
          '/team-select': (context) {
            final matchId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
            return TeamSelectionScreen(matchId: matchId);
          },
          '/wagon-wheel': (context) {
            final matchId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
            return WagonWheelScreen(matchId: matchId);
          },
          '/live-control': (context) {
            final matchId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
            return LiveScoreControlScreen(matchId: matchId);
          },
          '/toss': (context) {
            final matchId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
            return TossScreen(matchId: matchId);
          },


          // Team Routes
          '/teams': (context) => const TeamListScreen(),
          '/team-detail': (context) => TeamDetailScreen(teamId: ModalRoute.of(context)!.settings.arguments as String),

          '/create-team': (context) => const CreateTeamScreen(),
          '/my-teams': (context) => const TeamListScreen(),

          // Tournament Routes
          '/tournaments': (context) => const TournamentListScreen(),
          '/tournament-detail': (context) => const TournamentDetailScreen(tournamentId: ''),
          '/create-tournament': (context) => const CreateTournamentScreen(),
          '/points-table': (context) => const PointsTableScreen(tournamentId: ''),
          '/fixtures': (context) => const FixturesScreen(tournamentId: ''),
          '/my-tournaments': (context) => const TournamentListScreen(),

          // Player Routes
          '/players': (context) => const PlayerListScreen(),
          '/players/search': (context) => const PlayerSearchScreen(),
          '/create-player': (context) => const CreatePlayerScreen(),
          '/players/list': (context) => const PlayerListScreen(),
          '/player-search': (context) => const PlayerSearchScreen(),
          '/player-profile': (context) {
  final routeName = ModalRoute.of(context)!.settings.name ?? '/player-profile';
  final playerId = routeName.split('/').last;
  return PlayerProfileScreen(playerId: playerId.isEmpty ? 'default' : playerId);
},
          '/compare-players': (context) => const PlayerSearchScreen(),

          // Leaderboard Routes
          '/leaderboards': (context) => const TopBatsmanScreen(),
          '/leaderboard': (context) => const TopBatsmanScreen(),
          '/top-batsman': (context) => const TopBatsmanScreen(),
          '/top-bowler': (context) => const TopBatsmanScreen(),
          '/mvp-rankings': (context) => const TopBatsmanScreen(),
          '/team-rankings': (context) => const TopBatsmanScreen(),

          // Community Routes
          '/community': (context) => const CommunityFeedScreen(),
          '/create-post': (context) => const CreatePostScreen(),
          '/post-detail': (context) => const PostDetailScreen(postId: ''),

          // Store Routes
          '/store': (context) => const StoreHomeScreen(),
          '/product-detail': (context) => const ProductDetailScreen(productId: ''),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/orders': (context) => const OrdersScreen(),

          // Wallet & Subscription
          '/wallet': (context) => const WalletScreen(),
          '/subscription': (context) => const SubscriptionScreen(),
          '/subscription-plans': (context) => const SubscriptionScreen(),
          '/payment': (context) => const CheckoutScreen(),

          // Other Routes
          '/go-live': (context) => const GoLiveScreen(),
          '/live-player': (context) => const LivePlayerScreen(streamId: ''),
          '/live-match': (context) => const LivePlayerScreen(streamId: ''),
          '/discover': (context) => const DiscoveryScreen(),
          '/stats': (context) => const HomeScreen(),
          '/history': (context) => const HomeScreen(),
          '/activity': (context) => const HomeScreen(),
          '/edit-profile': (context) => const ProfileScreen(),
          '/my-performance': (context) => const CricketProfileScreen(),
          '/settings': (context) => const AppSettingsScreen(),
          '/settings/notifications': (context) => const NotificationSettingsScreen(),
          '/settings/privacy': (context) => const PrivacySettingsScreen(),
          '/settings/preferences': (context) => const PreferencesScreen(),
          '/settings/security': (context) => const SecurityScreen(),
          '/privacy-policy': (context) => const PrivacyPolicyScreen(),
          '/help-support': (context) => const HelpSupportScreen(),
          '/testing': (context) => const TestingScreen(),
          '/change-password': (context) => const AppSettingsScreen(),
          '/support': (context) => const AppSettingsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/connections': (context) => const ConnectionsScreen(),
          '/chats': (context) => const ChatListScreen(),
'/chat': (context) => const ChatListScreen(),
          '/my-cricket': (context) => const HomeScreen(),
          '/blogs': (context) => const BlogsScreen(),
          '/discovery': (context) => const DiscoveryScreen(),
          
        },
      ),
    );
  }
}
