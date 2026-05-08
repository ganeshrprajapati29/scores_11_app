import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Start after UI build (only once)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    // Skip if disposed or already navigated
    if (!mounted || _hasNavigated) return;

    final auth = context.read<AuthProvider>();

    try {
      // Auth check (ONLY ONCE)
      await auth.checkAuth();
    } catch (e) {
      debugPrint("Auth error: $e");
    }

    // NO artificial delay - navigate immediately after auth check
    // This prevents stale state issues in Release builds
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    // SAFE NAVIGATION - ensure we only navigate once
    final route = auth.status == AuthStatus.authenticated
        ? '/dashboard'
        : '/login';

    // Use pushReplacement to prevent back navigation to splash
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.sports_cricket,
                size: 50,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            // APP NAME
            const Text(
              'Scores11',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // LOADER
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}