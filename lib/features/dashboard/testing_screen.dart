
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/constants/app_colors.dart';

class TestingScreen extends StatelessWidget {
  const TestingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Test All Features',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/splash'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🏠 HOME & DASHBOARD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                      icon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/home'),
                      icon: Icon(Icons.home),
                      label: Text('Home Screen'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),
            
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚡ LIVE MATCH & SCORING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/live-match', arguments: 'test-match-1'),
                      icon: Icon(Icons.sports_cricket),
                      label: Text('Live Match (Test with socket)'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/score-entry', arguments: 'test-match-1'),
                      icon: Icon(Icons.add_circle),
                      label: Text('Score Entry (Add balls live)'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/scorecard'),
                      icon: Icon(Icons.analytics_outlined),
                      label: Text('Full Scorecard'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🏏 MATCHES & TOURNAMENTS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/matches'),
                      icon: Icon(Icons.sports_cricket),
                      label: Text('Matches List'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/match-detail'),
                      icon: Icon(Icons.info),
                      label: Text('Match Detail'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/tournaments'),
                      icon: Icon(Icons.emoji_events),
                      label: Text('Tournaments'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚽ TEAMS & PLAYERS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/teams'),
                      icon: Icon(Icons.group),
                      label: Text('Teams'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/players'),
                      icon: Icon(Icons.person_search),
                      label: Text('Player Search'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
            
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🏆 LEADERBOARD & RANKINGS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
                      icon: Icon(Icons.leaderboard),
                      label: Text('Leaderboard'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/top-batsman'),
                      icon: Icon(Icons.trending_up),
                      label: Text('Top Batsman'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 800.ms),
            
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🛒 STORE & WALLET', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/store'),
                      icon: Icon(Icons.store),
                      label: Text('Store'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/wallet'),
                      icon: Icon(Icons.account_balance_wallet),
                      label: Text('Wallet'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/subscription'),
                      icon: Icon(Icons.subscriptions),
                      label: Text('Subscription'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1000.ms),
            
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💬 COMMUNITY & SOCIAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/community'),
                      icon: Icon(Icons.groups),
                      label: Text('Community'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                      icon: Icon(Icons.notifications),
                      label: Text('Notifications'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1200.ms),
            
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎮 LIVE & DISCOVERY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/go-live'),
                      icon: Icon(Icons.videocam),
                      label: Text('Go Live'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/discover'),
                      icon: Icon(Icons.explore),
                      label: Text('Discovery'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1400.ms),
            
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚙️ SETTINGS & PROFILE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                      icon: Icon(Icons.person),
                      label: Text('Profile'),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1600.ms),
            
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Clear cache for testing
                // CacheService().clearAllCache();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('All pages accessible! Test Live Match + Score Entry first')),
                );
              },
              icon: Icon(Icons.play_arrow),
              label: Text('🚀 START TESTING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

