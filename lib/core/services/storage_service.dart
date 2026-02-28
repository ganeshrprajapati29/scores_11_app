import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';

  // Token Methods
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }

  Future<void> saveUserData(String userData) async {
    await _storage.write(key: userKey, value: userData);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: userKey);
  }

  Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: themeKey, value: mode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: themeKey);
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await _storage.write(key: onboardingKey, value: complete.toString());
  }

  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: onboardingKey);
    return value == 'true';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
  }
}
