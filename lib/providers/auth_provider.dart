import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../data/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'dart:async';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static final Logger _logger = Logger();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  UserModel? _user;
  Map<String, dynamic>? _userStats;
  
  // Timer for debouncing
  Timer? _notifyTimer;
  bool _isDisposed = false;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  Map<String, dynamic>? get userStats => _userStats;
  String? get userRole => _user?.role;

/// FIXED: Direct notifyListeners without Timer-based batching
  /// This prevents stale state issues in Release APK builds
  /// Timer-based batching causes unpredictable timing in Release mode
  void _safeNotifyListeners() {
    if (_isDisposed) return;
    if (_status == AuthStatus.initial) return;
    
    // Always use direct addPostFrameCallback for reliability in both Debug and Release builds
    // DO NOT use Timer-based batching - it causes stale state in Release builds
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && _status != AuthStatus.initial) {
          notifyListeners();
        }
      });
    } catch (e) {
      // Ignore errors during notification
    }
  }

  /// Check if user is already authenticated (call on app start)
  Future<void> checkAuth() async {
    try {
      _status = AuthStatus.loading;
      _safeNotifyListeners();

      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        _logger.i('Auth token found, fetching real user profile...');
        try {
          _user = await _authService.getCurrentUser();
          _loadUserStatsAsync();
          _status = AuthStatus.authenticated;
        } catch (e) {
          _logger.w('Failed to get user profile, token might be invalid: $e');
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
      _logger.e('checkAuth error: $e');
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      _user = null;
      _userStats = null;
      _status = AuthStatus.unauthenticated;
    }
    _safeNotifyListeners();
  }

  /// Load user stats asynchronously without triggering immediate rebuild
  Future<void> _loadUserStatsAsync() async {
    try {
      final stats = await _authService.getUserStats();
      if (stats != null) {
        if (stats is Map<String, dynamic>) {
          _userStats = stats;
        } else if (stats is List) {
          _userStats = stats.isNotEmpty && stats.first is Map<String, dynamic> 
              ? stats.first as Map<String, dynamic>
              : {'data': stats};
        } else {
          _userStats = {'data': stats};
        }
        _logger.i('User stats loaded successfully');
      } else {
        _userStats = null;
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Error loading user stats: $e');
      } else {
        _logger.w('User stats unavailable');
      }
      _userStats = null;
    }
    // Only notify if user is still authenticated
    if (_status == AuthStatus.authenticated && !_isDisposed) {
      _safeNotifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _safeNotifyListeners();

      final response = await _authService.login(identifier, password);
      
      final isSuccess = response['success'];
      if (isSuccess == true) {
        final data = response['data'];
        if (data == null) {
          _errorMessage = 'Invalid server response';
          _status = AuthStatus.error;
          _safeNotifyListeners();
          return false;
        }
        
        final accessToken = data is Map ? data['accessToken'] ?? data['token'] : null;
        final refreshToken = data is Map ? data['refreshToken'] : null;
        
        if (accessToken != null) {
          await _storage.write(key: AppConstants.accessTokenKey, value: accessToken.toString());
        }
        if (refreshToken != null) {
          await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken.toString());
        }
        
        final userData = data is Map ? data['user'] : null;
        if (userData != null) {
          try {
            dynamic parsedData = userData;
            if (userData is List) {
              parsedData = userData.isNotEmpty ? userData.first : null;
            }
            if (parsedData is Map<String, dynamic>) {
              _user = UserModel.fromJson(parsedData);
            } else if (parsedData != null) {
              try {
                _user = await _authService.getCurrentUser();
              } catch (e) {
                _logger.w('Failed to fetch user profile after login: $e');
              }
            }
          } catch (e) {
            _logger.w('Failed to parse user data: $e');
            try {
              _user = await _authService.getCurrentUser();
            } catch (e2) {
              _logger.w('Failed to get current user: $e2');
            }
          }
        }
        
        _loadUserStatsAsync();
        
        if (_user != null) {
          await UserService.saveUserData(
            userId: _user!.id,
            userName: _user!.name,
            userEmail: _user!.email,
          );
        }
        
        _status = AuthStatus.authenticated;
        _safeNotifyListeners();
        return true;
      } else {
        _errorMessage = response['message']?.toString() ?? 'Login failed. Please check your credentials.';
        if (_errorMessage!.toLowerCase().contains('network') || _errorMessage!.toLowerCase().contains('connect')) {
          _errorMessage = 'Network error - Check connection/server';
        }
        _status = AuthStatus.error;
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (_errorMessage!.toLowerCase().contains('socket') || _errorMessage!.toLowerCase().contains('connect')) {
        _errorMessage = 'Network error - Check connection/server';
      }
      _status = AuthStatus.error;
      _safeNotifyListeners();
      return false;
    }
  }

Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'user',
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _safeNotifyListeners();

final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        playerRole: playerRole,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
      );
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data == null) {
          _errorMessage = 'Invalid server response';
          _status = AuthStatus.error;
          _safeNotifyListeners();
          return false;
        }
        
        final accessToken = data is Map ? data['accessToken'] : null;
        final refreshToken = data is Map ? data['refreshToken'] : null;
        
        if (accessToken != null) {
          await _storage.write(key: AppConstants.accessTokenKey, value: accessToken.toString());
        }
        if (refreshToken != null) {
          await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken.toString());
        }
        
        final userData = data is Map ? data['user'] : null;
        if (userData != null) {
          dynamic parsedData = userData;
          if (userData is List) {
            parsedData = userData.isNotEmpty ? userData.first : null;
          }
          if (parsedData is Map<String, dynamic>) {
            _user = UserModel.fromJson(parsedData);
          }
        }
        
        _loadUserStatsAsync();
        
        _status = AuthStatus.authenticated;
        _safeNotifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Registration failed';
        _status = AuthStatus.error;
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> sendOTP(String identifier) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _safeNotifyListeners();

      final response = await _authService.sendOTP(identifier);
      
      if (response['success'] == true) {
        _status = AuthStatus.unauthenticated;
        _safeNotifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to send OTP';
        _status = AuthStatus.error;
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String identifier, String otp) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _safeNotifyListeners();

      final response = await _authService.verifyOTP(identifier, otp);
      
      if (response['success'] == true) {
        _status = AuthStatus.unauthenticated;
        _safeNotifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Invalid OTP';
        _status = AuthStatus.error;
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String identifier) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _safeNotifyListeners();

      final response = await _authService.forgotPassword(identifier);
      
      if (response['success'] == true) {
        _status = AuthStatus.unauthenticated;
        _safeNotifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to process request';
        _status = AuthStatus.error;
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String identifier, String otp, String newPassword) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      _safeNotifyListeners();

      final response = await _authService.resetPassword(identifier, otp, newPassword);
      
      if (response['success'] == true) {
        _status = AuthStatus.unauthenticated;
        _safeNotifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to reset password';
        _status = AuthStatus.error;
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      _logger.w('Logout API error (ignored): $e');
    } finally {
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      _user = null;
      _userStats = null;
      _status = AuthStatus.unauthenticated;
      _safeNotifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }
  
  Future<void> refreshUserStats() async {
    await _loadUserStatsAsync();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _notifyTimer?.cancel();
    super.dispose();
  }
}