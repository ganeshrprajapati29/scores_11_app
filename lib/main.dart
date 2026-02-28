import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

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
          '/dashboard': (context) => const DashboardScreen(),
          '/register': (context) => const LoginScreen(), // Placeholder
          '/forgot-password': (context) => const LoginScreen(), // Placeholder
          '/create-team': (context) => const DashboardScreen(), // Placeholder
          '/create-match': (context) => const DashboardScreen(), // Placeholder
          '/create-tournament': (context) => const DashboardScreen(), // Placeholder
          '/team-detail': (context) => const DashboardScreen(), // Placeholder
          '/match-detail': (context) => const DashboardScreen(), // Placeholder
          '/tournament-detail': (context) => const DashboardScreen(), // Placeholder
          '/edit-profile': (context) => const DashboardScreen(), // Placeholder
          '/my-performance': (context) => const DashboardScreen(), // Placeholder
          '/wallet': (context) => const DashboardScreen(), // Placeholder
          '/my-teams': (context) => const DashboardScreen(), // Placeholder
          '/my-tournaments': (context) => const DashboardScreen(), // Placeholder
          '/subscription': (context) => const DashboardScreen(), // Placeholder
          '/notifications': (context) => const DashboardScreen(), // Placeholder
          '/settings': (context) => const DashboardScreen(), // Placeholder
        },
      ),
    );
  }
}
