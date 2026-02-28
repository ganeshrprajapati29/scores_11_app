import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: user?.avatar?.url != null
                        ? ClipOval(
                            child: Image.network(
                              user!.avatar!.url!,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role ?? 'USER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu Items
            _MenuItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
            ),
            _MenuItem(
              icon: Icons.sports_cricket,
              title: 'My Performance',
              onTap: () {
                Navigator.pushNamed(context, '/my-performance');
              },
            ),
            _MenuItem(
              icon: Icons.wallet_outlined,
              title: 'Wallet',
              onTap: () {
                Navigator.pushNamed(context, '/wallet');
              },
            ),
            _MenuItem(
              icon: Icons.people_outline,
              title: 'My Teams',
              onTap: () {
                Navigator.pushNamed(context, '/my-teams');
              },
            ),
            _MenuItem(
              icon: Icons.emoji_events_outlined,
              title: 'My Tournaments',
              onTap: () {
                Navigator.pushNamed(context, '/my-tournaments');
              },
            ),
            _MenuItem(
              icon: Icons.subscriptions_outlined,
              title: 'Subscription',
              onTap: () {
                Navigator.pushNamed(context, '/subscription');
              },
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            _MenuItem(
              icon: Icons.logout,
              title: 'Logout',
              color: AppColors.error,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          authProvider.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: color ?? AppColors.textHint,
        ),
        onTap: onTap,
      ),
    );
  }
}
