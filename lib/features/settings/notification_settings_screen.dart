import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../data/models/settings_model.dart';
import '../../../data/services/settings_service.dart';
import '../../../providers/auth_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  Settings? _settings;
  bool _isLoading = true;
  late Map<String, bool> _notificationToggles;

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
        _notificationToggles = {
          'email': settings?.notificationPrefs['email'] ?? true,
          'push': settings?.notificationPrefs['push'] ?? true,
          'matchUpdates': settings?.notificationPrefs['matchUpdates'] ?? true,
          'tournamentUpdates': settings?.notificationPrefs['tournamentUpdates'] ?? true,
          'teamUpdates': settings?.notificationPrefs['teamUpdates'] ?? true,
          'promotions': settings?.notificationPrefs['promotions'] ?? true,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotifications() async {
    final success = await _settingsService.updateNotifications(_notificationToggles);
    if (success && mounted) {
      CustomSnackbar.show(context, 'Notification settings updated');
      _loadSettings();
    } else if (mounted) {
      CustomSnackbar.show(context, 'Failed to update settings', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Notification Settings'),
      body: _isLoading
        ? const Center(child: CustomLoader())
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildSection('General Notifications'),
                _buildSwitchTile(
                  'Email Notifications',
                  Icons.email_outlined,
                  _notificationToggles['email']!,
                  (value) => setState(() => _notificationToggles['email'] = value),
                ),
                _buildSwitchTile(
                  'Push Notifications',
                  Icons.notifications_outlined,
                  _notificationToggles['push']!,
                  (value) => setState(() => _notificationToggles['push'] = value),
                ),
                const SizedBox(height: 24),
                _buildSection('Match & Tournament'),
                _buildSwitchTile(
                  'Match Updates',
                  Icons.sports_cricket_outlined,
                  _notificationToggles['matchUpdates']!,
                  (value) => setState(() => _notificationToggles['matchUpdates'] = value),
                ),
                _buildSwitchTile(
                  'Tournament Updates',
                  Icons.emoji_events_outlined,
                  _notificationToggles['tournamentUpdates']!,
                  (value) => setState(() => _notificationToggles['tournamentUpdates'] = value),
                ),
                _buildSwitchTile(
                  'Team Updates',
                  Icons.group_outlined,
                  _notificationToggles['teamUpdates']!,
                  (value) => setState(() => _notificationToggles['teamUpdates'] = value),
                ),
                const SizedBox(height: 24),
                _buildSection('Promotions'),
                _buildSwitchTile(
                  'Promotional Offers',
                  Icons.campaign_outlined,
                  _notificationToggles['promotions']!,
                  (value) => setState(() => _notificationToggles['promotions'] = value),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _updateNotifications,
                ).animate().fadeIn().slideY(),
                const SizedBox(height: 20),
              ].map((child) => child.animate().fadeIn(delay: 100.ms * children.indexOf(child))).toList(),
            ),
          ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ),
    ).animate().slideX();
  }
}
