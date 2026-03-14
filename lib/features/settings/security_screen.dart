import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../data/services/settings_service.dart';
import '../../../core/constants/app_routes.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _twoFactorEnabled = false;
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
        _twoFactorEnabled = settings?.twoFactorEnabled ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTwoFactor() async {
    final success = await _settingsService.toggleTwoFactor(!_twoFactorEnabled);
    if (success && mounted) {
      setState(() => _twoFactorEnabled = !_twoFactorEnabled);
      CustomSnackbar.show(context, '2FA ${_twoFactorEnabled ? 'enabled' : 'disabled'}');
    } else if (mounted) {
      CustomSnackbar.show(context, 'Failed to update 2FA', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Security'),
      body: _isLoading
        ? const Center(child: CustomLoader())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Account Security'),
                _buildSwitchTile('Two-Factor Authentication', Icons.security, _twoFactorEnabled, _toggleTwoFactor),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.lock, color: AppColors.error),
                  ),
                  title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Update your account password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                ),
                const SizedBox(height: 24),
                _buildSection('Reset'),
                CustomButton(
                  text: 'Reset All Settings',
                  variant: ButtonVariant.outlined,
                  onPressed: () async {
                    final confirm = await _showResetDialog();
                    if (confirm && mounted) {
                      final success = await _settingsService.resetSettings();
                      if (success) {
                        _loadSettings();
                        CustomSnackbar.show(context, 'Settings reset to defaults');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSection(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
      );

  Widget _buildSwitchTile(String title, IconData icon, bool value, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              Switch(value: value, onChanged: (_) => onTap()),
            ],
          ),
        ),
      );

  Future<bool> _showResetDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Settings'),
            content: const Text('This will reset all your settings to defaults. This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reset', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
