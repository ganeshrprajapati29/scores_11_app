import 'core/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/theme_config.dart';
import 'core/services/cache_service.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
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
import 'features/teams/team_list_screen.dart';
import 'features/teams/team_detail_screen.dart';
import 'features/teams/create_team_screen.dart';
import 'features/players/player_search_screen.dart';
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
import 'features/dashboard/testing_screen.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/subscription/subscription_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/blogs/blogs_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'Scores11',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
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
          '/match-detail': (context) => const MatchDetailScreen(matchId: ''),
          '/create-match': (context) => const CreateMatchScreen(),
          '/live-match': (context) => const LiveMatchScreen(matchId: ''),
          '/score-entry': (context) => const ScoreEntryScreen(matchId: ''),
          '/scorecard': (context) => const MatchDetailScreen(matchId: ''),
          
          // Team Routes
          '/teams': (context) => const TeamListScreen(),
          '/team-detail': (context) => const TeamDetailScreen(teamId: ''),
          '/create-team': (context) => const CreateTeamScreen(),
          '/my-teams': (context) => const TeamListScreen(),
          
          // Tournament Routes
          '/tournaments': (context) => const TournamentListScreen(),
          '/tournament-detail': (context) => const TournamentDetailScreen(tournamentId: ''),
          '/create-tournament': (context) => CreateTournamentScreen(),
          '/points-table': (context) => const PointsTableScreen(tournamentId: ''),
          '/fixtures': (context) => const FixturesScreen(tournamentId: ''),
          '/my-tournaments': (context) => const TournamentListScreen(),
          
          // Player Routes
          '/players': (context) => const PlayerSearchScreen(),
          '/player-search': (context) => const PlayerSearchScreen(),
          '/player-profile': (context) => const CricketProfileScreen(),
          '/compare-players': (context) => const PlayerSearchScreen(),
          
          // Leaderboard Routes
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
          '/testing': (context) => TestingScreen(),
          '/change-password': (context) => const AppSettingsScreen(),
          '/support': (context) => const AppSettingsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/my-cricket': (context) => const HomeScreen(),
          
          // Additional Routes from Drawer/Shortcuts
          '/my-teams': (context) => const TeamListScreen(),
          '/my-tournaments': (context) => const TournamentListScreen(),
          '/create-team': (context) => const CreateTeamScreen(),
          '/create-match': (context) => const CreateMatchScreen(),
          '/player-profile': (context) => const PlayerSearchScreen(),
          '/community': (context) => const CommunityFeedScreen(),
          '/store': (context) => const StoreHomeScreen(),
          '/messages': (context) => const HomeScreen(),
          '/chat': (context) => const HomeScreen(),
          '/blogs': (context) => const BlogsScreen(),
        },
      ),
    );
  }
}

