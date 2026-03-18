import '../../core/widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/enums.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../data/services/settings_service.dart';
import '../../core/theme/app_colors.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final SettingsService _settingsService = SettingsService();
  Map<String, dynamic> _preferences = {};
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
        _preferences = settings?.userPrefs ?? {};
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreferences() async {
    final success = await _settingsService.updatePreferences(_preferences);
    if (success && mounted) {
      CustomSnackbar.show(context, 'Preferences updated');
    } else if (mounted) {
      CustomSnackbar.show(context, 'Failed to update preferences', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Preferences'),
      body: _isLoading
        ? Center(
            child: Builder(
builder: (context) => CustomLoader(),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('App Preferences'),
                _buildDropdownTile('Language', ['en', 'hi'], 'language'),
                _buildDropdownTile('Timezone', ['Asia/Kolkata', 'UTC'], 'timezone'),
                _buildDropdownTile('Theme', ['light', 'dark', 'system'], 'theme'),
                _buildDropdownTile('Default Format', ['T20', 'ODI', 'TEST'], 'defaultFormat'),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _updatePreferences,
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

  Widget _buildDropdownTile(String label, List<String> options, String key) => Container(
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
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _preferences[key] ?? options.first,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: options.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _preferences[key] = newValue!;
                });
              },
            ),
          ],
        ),
      );
}



