import 'package:json_annotation/json_annotation.dart';
part 'settings_model.g.dart';

@JsonSerializable()
class Settings {
  final Map<String, dynamic>? notifications;
  final Map<String, dynamic>? privacy;
  final Map<String, dynamic>? preferences;
  @JsonKey(name: 'twoFactorEnabled')
  final bool? twoFactorEnabled;

  Settings({
    this.notifications,
    this.privacy,
    this.preferences,
    this.twoFactorEnabled,
  });

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  // Helper methods
  Map<String, dynamic> get notificationPrefs => notifications ?? {};
  Map<String, dynamic> get privacyPrefs => privacy ?? {};
  Map<String, dynamic> get userPrefs => preferences ?? {};

  bool get emailNotifications => notificationPrefs['email'] ?? true;
  bool get pushNotifications => notificationPrefs['push'] ?? true;
  // Add more getters as needed
}

@JsonSerializable()
class NotificationSettings {
  final bool email;
  final bool push;
  final bool matchUpdates;
  final bool tournamentUpdates;
  final bool teamUpdates;
  final bool promotions;

  NotificationSettings({
    required this.email,
    required this.push,
    required this.matchUpdates,
    required this.tournamentUpdates,
    required this.teamUpdates,
    required this.promotions,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => 
    NotificationSettings(
      email: json['email'] ?? true,
      push: json['push'] ?? true,
      matchUpdates: json['matchUpdates'] ?? true,
      tournamentUpdates: json['tournamentUpdates'] ?? true,
      teamUpdates: json['teamUpdates'] ?? true,
      promotions: json['promotions'] ?? true,
    );

  Map<String, dynamic> toJson() => {
    'email': email,
    'push': push,
    'matchUpdates': matchUpdates,
    'tournamentUpdates': tournamentUpdates,
    'teamUpdates': teamUpdates,
    'promotions': promotions,
  };
}

// Similar for PrivacySettings, PreferenceSettings
@JsonSerializable()
class PrivacySettings {
  final String profileVisibility;
  final bool showStats;
  final bool showActivity;

  PrivacySettings({
    this.profileVisibility = 'public',
    this.showStats = true,
    this.showActivity = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => _$PrivacySettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);
}

@JsonSerializable()
class PreferenceSettings {
  final String language;
  final String timezone;
  final String theme;
  final String defaultFormat;

  PreferenceSettings({
    this.language = 'en',
    this.timezone = 'Asia/Kolkata',
    this.theme = 'system',
    this.defaultFormat = 'T20',
  });

  factory PreferenceSettings.fromJson(Map<String, dynamic> json) => _$PreferenceSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PreferenceSettingsToJson(this);
}
