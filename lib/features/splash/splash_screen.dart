import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Check auth status and navigate accordingly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Auto-navigate after auth check
          if (authProvider.status != AuthStatus.initial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (authProvider.status == AuthStatus.authenticated && authProvider.user != null) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                }
              }
            });
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.primaryGradient,
              ),
            ),

            child: Stack(
              children: [

                /// Background glow
                Positioned(
                  top: -120,
                  left: -80,
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ).animate().scale(duration: 4.seconds),
                ),

                Positioned(
                  bottom: -100,
                  right: -80,
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ).animate().scale(duration: 4.seconds),
                ),

                /// Main Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      /// Logo Card
                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            )
                          ],
                        ),

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.sports_cricket,
                                size: 80,
                                color: AppColors.primary,
                              );
                            },
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .scale(begin: const Offset(0.6, 0.6))
                          .then()
                          .shake(duration: 600.ms),

                      const SizedBox(height: 28),

                      /// App Name
                      Text(
                        "Scores11",
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideY(begin: 0.4),

                      const SizedBox(height: 10),

                      /// Tagline
                      Text(
                        "Play • Compete • Win",
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1.5,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 700.ms),

                      const SizedBox(height: 50),

                      /// Loader
                      if (authProvider.status == AuthStatus.loading)
                        const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            .animate()
                            .fadeIn(delay: 900.ms)
                      else if (authProvider.status == AuthStatus.authenticated)
                        Icon(Icons.check_circle, color: Colors.green, size: 40)
                            .animate().fadeIn(delay: 900.ms)
                      else
                        const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            .animate()
                            .fadeIn(delay: 900.ms),

                    ],
                  ),
                ),

                /// Bottom Text
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Powered by Scores11",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ).animate().fadeIn(delay: 1.seconds),
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}

