import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : screenWidth > 800 ? 3 : 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
          children: const [
            // Row 1
            QuickActionCard(
              icon: Icons.group_add_rounded,
              title: 'Create Team',
              color: AppColors.primary,
              route: '/create-team',
            ),
            QuickActionCard(
              icon: Icons.emoji_events_rounded,
              title: 'Join Cup',
              color: Color(0xFFFF8F00),
              route: '/tournaments',
            ),
            QuickActionCard(
              icon: Icons.forum_outlined,
              title: 'Community',
              color: Color(0xFF1976D2),
              route: '/community',
            ),
            QuickActionCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chats',
              color: Color(0xFF00796B),
              route: '/chats',
            ),
            // Row 2
            QuickActionCard(
              icon: Icons.person_add_rounded,
              title: 'Create Player',
              color: Color(0xFF2E7D32),
              route: '/create-player',
            ),
            QuickActionCard(
              icon: Icons.group_rounded,
              title: 'Players',
              color: Color(0xFF1565C0),
              route: '/players',
            ),
            QuickActionCard(
              icon: Icons.groups_rounded,
              title: 'Teams',
              color: Color(0xFF2E7D32),
              route: '/teams',
            ),
            QuickActionCard(
              icon: Icons.leaderboard_rounded,
              title: 'Leaderboard',
              color: Color(0xFF1976D2),
              route: '/leaderboard',
            ),
            // Row 3
            QuickActionCard(
              icon: Icons.analytics_outlined,
              title: 'Scorecard',
              color: Colors.orange,
              route: '/scorecard',
            ),
            QuickActionCard(
              icon: Icons.emoji_events_rounded,
              title: 'Tournaments',
              color: Color(0xFFFF8F00),
              route: '/tournaments',
            ),
            QuickActionCard(
              icon: Icons.article_outlined,
              title: 'Live Matches',
              color: Color(0xFF00796B),
              route: '/live-matches',
            ),
            QuickActionCard(
              icon: Icons.live_tv_rounded,
              title: 'Go Live',
              color: Color(0xFF8E24AA),
              route: '/go-live',
            ),
            // Row 4
            QuickActionCard(
              icon: Icons.article_outlined,
              title: 'Blogs',
              color: Color(0xFF00897B),
              route: '/blogs',
            ),
            QuickActionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet',
              color: Color(0xFF388E3C),
              route: '/wallet',
            ),
            QuickActionCard(
              icon: Icons.sports_cricket,
              title: 'Create Match', 
              color: const Color(0xFFE91E63),
              route: '/create-match',
            ),
            QuickActionCard(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              color: Colors.deepPurple,
              route: '/notifications',
            ),
          ],
        );
      },
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String route;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF1A1A2E),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

