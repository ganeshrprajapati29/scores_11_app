import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/otp_verification_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/goLive/go_live_screen.dart';
import 'features/tournaments/tournament_detail_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/cricket_profile_screen.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'Cric11',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/otp-verification': (context) => const OTPVerificationScreen(
            identifier: '',
            onVerify: (_) {},
            onResend: () {},
          ),
          '/dashboard': (context) => const DashboardScreen(),
          '/create-team': (context) => const DashboardScreen(),
          '/create-match': (context) => const DashboardScreen(),
          '/create-tournament': (context) => const DashboardScreen(),
          '/team-detail': (context) => const DashboardScreen(),
          '/match-detail': (context) => const DashboardScreen(),
          '/tournament-detail': (context) => TournamentDetailScreen(
            tournamentId: '',
          ),
          '/edit-profile': (context) => const DashboardScreen(),
          '/my-performance': (context) => const DashboardScreen(),
          '/wallet': (context) => const DashboardScreen(),
          '/my-teams': (context) => const DashboardScreen(),
          '/my-tournaments': (context) => const DashboardScreen(),
          '/subscription': (context) => const DashboardScreen(),
          '/notifications': (context) => const DashboardScreen(),
          '/settings': (context) => const DashboardScreen(),
          '/go-live': (context) => const GoLiveScreen(),
          '/home': (context) => const HomeScreen(),
          '/stats': (context) => const DashboardScreen(),
          '/history': (context) => const DashboardScreen(),
          '/discover': (context) => const DashboardScreen(),
          '/activity': (context) => const DashboardScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/cricket-profile': (context) => const CricketProfileScreen(),
        },
      ),
    );
  }
}
