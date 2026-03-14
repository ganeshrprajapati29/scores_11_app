import '../models/settings_model.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';

class SettingsService {
  final ApiClient _apiClient = ApiClient();

  /// Get user settings
  Future<Settings?> getSettings() async {
    try {
      final response = await _apiClient.get(ApiConfig.settings);
      return Settings.fromJson(response.data['data']);
    } catch (e) {
      print('Error fetching settings: $e');
      return null;
    }
  }

  /// Update full settings
  Future<bool> updateSettings(Settings settings) async {
    try {
      await _apiClient.put(
        ApiConfig.settings,
        data: settings.toJson(),
      );
      return true;
    } catch (e) {
      print('Error updating settings: $e');
      return false;
    }
  }

  /// Update notifications only
  Future<bool> updateNotifications(Map<String, dynamic> notifications) async {
    try {
      await _apiClient.put(
        '${ApiConfig.settings}/notifications',
        data: notifications,
      );
      return true;
    } catch (e) {
      print('Error updating notifications: $e');
      return false;
    }
  }

  /// Update privacy settings
  Future<bool> updatePrivacy(Map<String, dynamic> privacy) async {
    try {
      await _apiClient.put(
        '${ApiConfig.settings}/privacy',
        data: privacy,
      );
      return true;
    } catch (e) {
      print('Error updating privacy: $e');
      return false;
    }
  }

  /// Update preferences
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await _apiClient.put(
        '${ApiConfig.settings}/preferences',
        data: preferences,
      );
      return true;
    } catch (e) {
      print('Error updating preferences: $e');
      return false;
    }
  }

  /// Toggle two-factor authentication
  Future<bool> toggleTwoFactor(bool enabled) async {
    try {
      await _apiClient.patch(
        '${ApiConfig.settings}/two-factor',
        data: {'enabled': enabled},
      );
      return true;
    } catch (e) {
      print('Error toggling 2FA: $e');
      return false;
    }
  }

  /// Reset settings to defaults
  Future<bool> resetSettings() async {
    try {
      await _apiClient.post(ApiConfig.settings + '/reset');
      return true;
    } catch (e) {
      print('Error resetting settings: $e');
      return false;
    }
  }
}
