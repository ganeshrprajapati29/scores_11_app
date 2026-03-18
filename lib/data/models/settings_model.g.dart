// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
  notifications: json['notifications'] as Map<String, dynamic>?,
  privacy: json['privacy'] as Map<String, dynamic>?,
  preferences: json['preferences'] as Map<String, dynamic>?,
  twoFactorEnabled: json['twoFactorEnabled'] as bool?,
);

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
  'notifications': instance.notifications,
  'privacy': instance.privacy,
  'preferences': instance.preferences,
  'twoFactorEnabled': instance.twoFactorEnabled,
};

NotificationSettings _$NotificationSettingsFromJson(
  Map<String, dynamic> json,
) => NotificationSettings(
  email: json['email'] as bool,
  push: json['push'] as bool,
  matchUpdates: json['matchUpdates'] as bool,
  tournamentUpdates: json['tournamentUpdates'] as bool,
  teamUpdates: json['teamUpdates'] as bool,
  promotions: json['promotions'] as bool,
);

Map<String, dynamic> _$NotificationSettingsToJson(
  NotificationSettings instance,
) => <String, dynamic>{
  'email': instance.email,
  'push': instance.push,
  'matchUpdates': instance.matchUpdates,
  'tournamentUpdates': instance.tournamentUpdates,
  'teamUpdates': instance.teamUpdates,
  'promotions': instance.promotions,
};

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) =>
    PrivacySettings(
      profileVisibility: json['profileVisibility'] as String? ?? 'public',
      showStats: json['showStats'] as bool? ?? true,
      showActivity: json['showActivity'] as bool? ?? true,
    );

Map<String, dynamic> _$PrivacySettingsToJson(PrivacySettings instance) =>
    <String, dynamic>{
      'profileVisibility': instance.profileVisibility,
      'showStats': instance.showStats,
      'showActivity': instance.showActivity,
    };

PreferenceSettings _$PreferenceSettingsFromJson(Map<String, dynamic> json) =>
    PreferenceSettings(
      language: json['language'] as String? ?? 'en',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      theme: json['theme'] as String? ?? 'system',
      defaultFormat: json['defaultFormat'] as String? ?? 'T20',
    );

Map<String, dynamic> _$PreferenceSettingsToJson(PreferenceSettings instance) =>
    <String, dynamic>{
      'language': instance.language,
      'timezone': instance.timezone,
      'theme': instance.theme,
      'defaultFormat': instance.defaultFormat,
    };
