import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  UserModel? _user;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  /// Check if user is already authenticated (call on app start)
  Future<void> checkAuth() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        // Verify token and fetch user profile
        final profileResult = await _userService.getProfile();
        if (profileResult['success']) {
          final data = jsonDecode(profileResult['data']);
          _user = UserModel.fromJson(data);
          _status = AuthStatus.authenticated;
        } else {
          await logout();
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.login(identifier, password);
      
      if (response['success'] == true) {
        // Store token
        await _storage.write(key: 'auth_token', value: response['data']['token']);
        
        // Fetch complete user profile
        final profileResult = await _userService.getProfile();
        if (profileResult['success']) {
          final data = jsonDecode(profileResult['data']);
          _user = UserModel.fromJson(data);
        } else {
          _user = UserModel.fromJson(response['data']['user']);
        }
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Login failed';
        _status = AuthStatus.error;
        notifyListeners();
        _status = AuthStatus.unauthenticated;
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      _status = AuthStatus.unauthenticated;
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
        // Store token
        await _storage.write(key: 'auth_token', value: response['data']['token']);
        
        // Fetch complete user profile
        final profileResult = await _userService.getProfile();
        if (profileResult['success']) {
          final data = jsonDecode(profileResult['data']);
          _user = UserModel.fromJson(data);
        } else {
          _user = UserModel.fromJson(response['data']['user']);
        }
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Registration failed';
        _status = AuthStatus.error;
        notifyListeners();
        _status = AuthStatus.unauthenticated;
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      _status = AuthStatus.unauthenticated;
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
        // Store token and fetch profile
        await _storage.write(key: 'auth_token', value: response['data']['token']);
        final profileResult = await _userService.getProfile();
        if (profileResult['success']) {
          final data = jsonDecode(profileResult['data']);
          _user = UserModel.fromJson(data);
        }
        _status = AuthStatus.authenticated;
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
      await _storage.delete(key: 'auth_token');
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

