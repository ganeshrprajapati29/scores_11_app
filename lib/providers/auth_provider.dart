import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../data/services/auth_service.dart';

import '../../core/services/user_service.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'dart:developer';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  UserModel? _user;
  Map<String, dynamic>? _userStats;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  Map<String, dynamic>? get userStats => _userStats;

  String? get userRole => _user?.role;

  /// Check if user is already authenticated (call on app start)
  Future<void> checkAuth() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        debugPrint('Auth token found, fetching real user profile...');
        try {
          _user = await _authService.getCurrentUser();
          await _loadUserStats(); // Load user stats after getting user
          _status = AuthStatus.authenticated;
        } catch (e) {
          debugPrint('Failed to get user profile, token might be invalid: $e');
          await _storage.delete(key: AppConstants.accessTokenKey);
          await _storage.delete(key: AppConstants.refreshTokenKey);
          _user = null;
          _userStats = null;
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('checkAuth error: $e');
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      _user = null;
      _userStats = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Safe method to load user stats with error handling
  Future<void> _loadUserStats() async {
    try {
      debugPrint('📊 Loading user stats...');
      final stats = await _authService.getUserStats();
      
      // Safe parsing for stats
      if (stats != null) {
        if (stats is Map<String, dynamic>) {
          _userStats = stats;
        } else if (stats is List) {
          // If stats is a list, convert to map or take first element
          _userStats = stats.isNotEmpty && stats.first is Map<String, dynamic> 
              ? stats.first as Map<String, dynamic>
              : {'data': stats};
        } else {
          _userStats = {'data': stats};
        }
        debugPrint('✅ User stats loaded successfully');
      } else {
        _userStats = null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading user stats: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't fail the whole auth process, just set stats to null
      _userStats = null;
    }
  }

  Future<bool> login(String identifier, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.login(identifier, password);
      
      if (response['success'] == true) {
        // Store tokens using ApiClient's keys
        final accessToken = response['data']['accessToken'];
        final refreshToken = response['data']['refreshToken'];
        
        if (accessToken != null) {
          await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
        }
        if (refreshToken != null) {
          await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
        }
        
        // Get user from response
        final userData = response['data']['user'];
        if (userData != null) {
          // ✅ FIXED: Safe parsing for List vs Map
          dynamic parsedData = userData;
          if (userData is List) {
            parsedData = userData.isNotEmpty ? userData.first : null;
          }
          if (parsedData is Map<String, dynamic>) {
            _user = UserModel.fromJson(parsedData);
          } else {
            // Fallback fetch
            try {
              _user = await _authService.getCurrentUser();
            } catch (e) {
              debugPrint('Failed to fetch user profile after login: $e');
            }
          }
        }
        
        // Load user stats after successful login
        await _loadUserStats();
        
        // ✅ Save to shared prefs for notifications
        if (_user != null) {
          await UserService.saveUserData(
            userId: _user!.id,
            userName: _user!.name,
            userEmail: _user!.email,
          );
        }
        
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Login failed';
        _status = AuthStatus.error;
        notifyListeners();
        // Reset status after error
        Future.delayed(const Duration(seconds: 2), () {
          if (_status == AuthStatus.error) {
            _status = AuthStatus.unauthenticated;
            notifyListeners();
          }
        });
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        if (_status == AuthStatus.error) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
      });
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'user',
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      
      if (response['success'] == true) {
        // Store tokens
        final accessToken = response['data']['accessToken'];
        final refreshToken = response['data']['refreshToken'];
        
        if (accessToken != null) {
          await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
        }
        if (refreshToken != null) {
          await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
        }
        
        // ✅ FIXED: Safe parsing for register too
        final userData = response['data']['user'];
        if (userData != null) {
          dynamic parsedData = userData;
          if (userData is List) {
            parsedData = userData.isNotEmpty ? userData.first : null;
          }
          if (parsedData is Map<String, dynamic>) {
            _user = UserModel.fromJson(parsedData);
          }
        }
        
        // Load user stats after successful registration
        await _loadUserStats();
        
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Registration failed';
        _status = AuthStatus.error;
        notifyListeners();
        Future.delayed(const Duration(seconds: 2), () {
          if (_status == AuthStatus.error) {
            _status = AuthStatus.unauthenticated;
            notifyListeners();
          }
        });
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        if (_status == AuthStatus.error) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
      });
      return false;
    }
  }

  Future<bool> sendOTP(String identifier) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.sendOTP(identifier);
      
      if (response['success'] == true) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to send OTP';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String identifier, String otp) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.verifyOTP(identifier, otp);
      
      if (response['success'] == true) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Invalid OTP';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String identifier) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.forgotPassword(identifier);
      
      if (response['success'] == true) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to process request';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String identifier, String otp, String newPassword) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.resetPassword(identifier, otp, newPassword);
      
      if (response['success'] == true) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to reset password';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      _user = null;
      _userStats = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Method to refresh user stats manually
  Future<void> refreshUserStats() async {
    await _loadUserStats();
    notifyListeners();
  }
}