import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/theme_config.dart';
import 'core/services/cache_service.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/scorecard_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'data/models/match_model.dart';
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
import 'features/matches/scheduled_matches_screen.dart';
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
          '/login': (context) => const _AuthAwareLoginScreen(),
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
          '/matches': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final data = args is Map ? args : const {};
            final dynamic newMatchArg = data['newMatch'];
            Match? initialMatch;
            if (newMatchArg is Match) {
              initialMatch = newMatchArg;
            } else if (newMatchArg is Map<String, dynamic>) {
              try {
                initialMatch = Match.fromJson(newMatchArg);
              } catch (_) {
                initialMatch = null;
              }
            }
            return MatchListScreen(
              initialTabIndex: int.tryParse(data['initialTab']?.toString() ?? '0') ?? 0,
              initialMatch: initialMatch,
            );
          },
          '/matches/live': (context) => const MatchListScreen(initialTabIndex: 0),
          '/live-matches': (context) => const MatchListScreen(initialTabIndex: 0),
          '/all-matches': (context) => const MatchListScreen(initialTabIndex: 1),
          '/scheduled-matches': (context) => const ScheduledMatchesScreen(),
          '/completed-matches': (context) => const ScheduledMatchesScreen(initialTabIndex: 1),
          '/scorecards': (context) => const ScorecardScreen(matchId: ''),
          '/match-detail': (context) {
            final matchId = ModalRoute.of(context)!.settings.arguments as String? ?? '';
            return MatchDetailScreen(matchId: matchId);
          },
          '/create-match': (context) => const CreateMatchScreen(),
// '/create-match-enhanced': (context) => CreateMatchScreen(), // Temporarily disabled - class not found
          '/live-match': (context) => const LiveMatchScreen(matchId: ''),
          '/score-entry': (context) => const ScoreEntryScreen(matchId: ''),
          '/scorecard': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            String matchId = '';
            if (args is String) {
              matchId = args;
            } else if (args is Match) {
              matchId = args.id;
            } else if (args is Map) {
              matchId =
                  (args['_id'] ?? args['id'] ?? args['matchId'] ?? '').toString();
            }
            return ScorecardScreen(matchId: matchId);
          },
          
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
          '/tournament-detail': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final tournamentId = args is Map
                ? (args['tournamentId']?.toString() ?? args['id']?.toString() ?? '')
                : args?.toString() ?? '';
            return TournamentDetailScreen(tournamentId: tournamentId);
          },
          '/create-tournament': (context) => const CreateTournamentScreen(),
          '/points-table': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            return PointsTableScreen(tournamentId: args?.toString() ?? '');
          },
          '/fixtures': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            return FixturesScreen(tournamentId: args?.toString() ?? '');
          },
          '/my-tournaments': (context) => const TournamentListScreen(),

          // Player Routes
          '/players': (context) => const PlayerListScreen(),
          '/public-players': (context) => const PlayerSearchScreen(),
          '/players/search': (context) => const PlayerSearchScreen(),
          '/create-player': (context) => const CreatePlayerScreen(),
          '/players/list': (context) => const PlayerListScreen(),
          '/player-search': (context) => const PlayerSearchScreen(),
          '/player-profile': (context) {
            final settings = ModalRoute.of(context)!.settings;
            final args = settings.arguments;
            final playerId = args is Map
                ? (args['playerId']?.toString() ?? '')
                : args is String
                    ? args
                    : (settings.name ?? '').split('/').last;
            return PlayerProfileScreen(
              playerId: playerId.isEmpty || playerId == 'player-profile'
                  ? 'default'
                  : playerId,
            );
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

class _AuthAwareLoginScreen extends StatelessWidget {
  const _AuthAwareLoginScreen();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.authenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return const LoginScreen();
      },
    );
  }
}
