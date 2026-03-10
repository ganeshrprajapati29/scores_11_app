import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  UserModel? _user;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  Future<bool> login(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.login(email, password);
      
      if (response['success'] == true) {
        // Handle user data - ensure it's a proper Map
        final userData = response['data']['user'];
        _user = UserModel.fromJson(userData);
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
        _user = UserModel.fromJson(response['data']['user']);
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
