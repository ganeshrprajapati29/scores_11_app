import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/theme_config.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/cache_service.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/settings_service.dart';
import '../../data/models/settings_model.dart';
import '../../providers/auth_provider.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'preferences_screen.dart';
import 'security_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  Settings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await _settingsService.getSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Reset all settings to defaults?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirm == true) {
      final success = await _settingsService.resetSettings();
      if (success && mounted) {
        _loadSettings();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings reset')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: CustomAppBar(title: 'Settings'),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadSettings,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.user?.name ?? 'User',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                authProvider.user?.email ?? '',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadSettings,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 20),

                  // Account Settings
                  _buildSection('Account', Icons.person),
                  _buildSettingsTile(Icons.person_outline, 'Edit Profile', 'Update personal info', () => Navigator.pushNamed(context, AppRoutes.editProfile)),
                  _buildSettingsTile(Icons.lock_outline, 'Security', 'Manage security settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()))),

                  const SizedBox(height: 16),

                  // Notifications
                  _buildSection('Notifications', Icons.notifications),
                  _buildSettingsTile(Icons.notifications_outlined, 'Notification Preferences', 'Customize notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()))),

                  const SizedBox(height: 16),

                  // Privacy
                  _buildSection('Privacy', Icons.privacy_tip),
                  _buildSettingsTile(Icons.security, 'Privacy Settings', 'Control profile visibility', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()))),

                  const SizedBox(height: 16),

                  // Preferences
                  _buildSection('Preferences', Icons.tune),
                  _buildSettingsTile(Icons.palette_outlined, 'App Preferences', 'Language, theme & more', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesScreen()))),

                  const SizedBox(height: 16),

                  // Support
                  _buildSection('Support', Icons.help),
                  _buildSettingsTile(Icons.help_outline, 'Help & FAQ', 'Get help and answers', () {}),
                  _buildSettingsTile(Icons.feedback_outlined, 'Send Feedback', 'Help us improve', () {}),
                  _buildSettingsTile(Icons.info_outline, 'About', 'App version 1.0.0', () => _showAboutDialog()),
                  _buildSettingsTile(Icons.description_outlined, 'Terms & Conditions', 'Read our terms', () {}),
                  _buildSettingsTile(Icons.privacy_tip_outlined, 'Privacy Policy', 'Read our privacy policy', () => Share.share('Privacy Policy link')),

                  const SizedBox(height: 16),

                  // Reset & Logout
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'Reset All Settings',
                          variant: ButtonVariant.outlined,
                          onPressed: _resetSettings,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text('Logout', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey[600]),
        onTap: onTap,
      ),
    ).animate().fadeIn();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
            },
            child: const Text('Logout'),
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
            Text('Your ultimate cricket companion.'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
