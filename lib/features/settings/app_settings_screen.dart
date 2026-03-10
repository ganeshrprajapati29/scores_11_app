import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _darkMode = false;
  bool _locationServices = true;
  bool _dataSync = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'John Doe',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'john.doe@email.com',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/edit-profile');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            
            const SizedBox(height: 16),
            
            // Account Section
            _buildSectionTitle('Account'),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () => Navigator.pushNamed(context, '/edit-profile'),
            ),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () => Navigator.pushNamed(context, '/change-password'),
            ),
            _buildSettingsTile(
              icon: Icons.security,
              title: 'Privacy & Security',
              subtitle: 'Manage your privacy settings',
              onTap: () {},
            ),
            
            const SizedBox(height: 16),
            
            // Notifications Section
            _buildSectionTitle('Notifications'),
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications',
              value: _notifications,
              onChanged: (value) => setState(() => _notifications = value),
            ),
            _buildSwitchTile(
              icon: Icons.email_outlined,
              title: 'Email Notifications',
              subtitle: 'Receive email updates',
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
            ),
            _buildSwitchTile(
              icon: Icons.sms_outlined,
              title: 'SMS Notifications',
              subtitle: 'Receive SMS updates',
              value: _smsNotifications,
              onChanged: (value) => setState(() => _smsNotifications = value),
            ),
            
            const SizedBox(height: 16),
            
            // Preferences Section
            _buildSectionTitle('Preferences'),
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Enable dark theme',
              value: _darkMode,
              onChanged: (value) => setState(() => _darkMode = value),
            ),
            _buildSwitchTile(
              icon: Icons.location_on_outlined,
              title: 'Location Services',
              subtitle: 'Allow location access',
              value: _locationServices,
              onChanged: (value) => setState(() => _locationServices = value),
            ),
            _buildSwitchTile(
              icon: Icons.sync,
              title: 'Data Sync',
              subtitle: 'Auto sync data with cloud',
              value: _dataSync,
              onChanged: (value) => setState(() => _dataSync = value),
            ),
            _buildSettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              onTap: () {},
            ),
            
            const SizedBox(height: 16),
            
            // Support Section
            _buildSectionTitle('Support'),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              subtitle: 'Get help and answers',
              onTap: () => Navigator.pushNamed(context, '/support'),
            ),
            _buildSettingsTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Help us improve',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App version 1.0.0',
              onTap: () => _showAboutDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {},
            ),
            
            const SizedBox(height: 16),
            
            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ).animate().fadeIn();
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ),
    ).animate().fadeIn();
  }

  void _showLogoutDialog() {
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
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sports_cricket, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cric11'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text(
              'Cric11 is your ultimate cricket companion. Play matches, create teams, join tournaments, and connect with cricket enthusiasts worldwide.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

