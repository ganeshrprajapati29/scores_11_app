import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../data/services/settings_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  Map<String, dynamic> _privacySettings = {};
  bool _isLoading = true;
  String _profileVisibility = 'public';

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
        _privacySettings = settings?.privacyPrefs ?? {};
        _profileVisibility = _privacySettings['profileVisibility'] ?? 'public';
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrivacy() async {
    final privacy = {
      'profileVisibility': _profileVisibility,
      'showStats': _privacySettings['showStats'] ?? true,
      'showActivity': _privacySettings['showActivity'] ?? true,
    };
    final success = await _settingsService.updatePrivacy(privacy);
    if (success && mounted) {
      CustomSnackbar.show(context, 'Privacy settings updated');
    } else if (mounted) {
      CustomSnackbar.show(context, 'Failed to update privacy', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Privacy & Security'),
      body: _isLoading
        ? const Center(child: CustomLoader())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Profile Visibility'),
                _buildDropdownTile(),
                _buildSwitchTile('Show Stats', Icons.bar_chart, _privacySettings['showStats'] ?? true, (value) {
                  setState(() {
                    _privacySettings['showStats'] = value;
                  });
                }),
                _buildSwitchTile('Show Activity', Icons.timeline, _privacySettings['showActivity'] ?? true, (value) {
                  setState(() {
                    _privacySettings['showActivity'] = value;
                  });
                }),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _updatePrivacy,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildSection(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
      );

  Widget _buildDropdownTile() => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Who can see your profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _profileVisibility,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: ['public', 'friends', 'private'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _profileVisibility = newValue!;
                });
              },
            ),
          ],
        ),
      );

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
            Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
          ],
        ),
      );
}
