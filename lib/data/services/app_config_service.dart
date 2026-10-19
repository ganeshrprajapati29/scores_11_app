import '../../core/services/api_client.dart';

/// Public app-wide settings from GET /settings/app (set in the backend .env).
class AppConfig {
  final String supportEmail;
  final String supportPhone;
  final String supportWhatsapp;
  final String website;
  final bool youtubeChannelConnectEnabled;

  const AppConfig({
    this.supportEmail = 'support@scores11.com',
    this.supportPhone = '',
    this.supportWhatsapp = '',
    this.website = 'https://scores11.com',
    this.youtubeChannelConnectEnabled = false,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final support = json['support'] is Map ? Map<String, dynamic>.from(json['support']) : const {};
    final youtube = json['youtube'] is Map ? Map<String, dynamic>.from(json['youtube']) : const {};
    String read(String key, String fallback) {
      final value = support[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    return AppConfig(
      supportEmail: read('email', 'support@scores11.com'),
      supportPhone: read('phone', ''),
      supportWhatsapp: read('whatsapp', '').replaceAll(RegExp(r'[^0-9]'), ''),
      website: read('website', 'https://scores11.com'),
      youtubeChannelConnectEnabled: youtube['channelConnectEnabled'] == true,
    );
  }
}

class AppConfigService {
  static AppConfig? _cached;

  static Future<AppConfig> load({bool refresh = false}) async {
    if (_cached != null && !refresh) return _cached!;
    try {
      final response = await ApiClient().get('/settings/app');
      final data = response.data is Map ? response.data['data'] : null;
      _cached = data is Map ? AppConfig.fromJson(Map<String, dynamic>.from(data)) : const AppConfig();
    } catch (_) {
      return _cached ?? const AppConfig();
    }
    return _cached!;
  }
}
