import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FlutterSecureStorage _encryptedStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const List<String> _legacyAccessTokenKeys = [
    AppConstants.accessTokenKey,
    'token',
    'auth_token',
    'jwt',
  ];

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConfig.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null && token.trim().isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            final token = await getAccessToken();
            if (token != null && token.trim().isNotEmpty) {
              opts.headers['Authorization'] = 'Bearer $token';
            }
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
  }

  // Static method to get token (for backward compatibility)
  static Future<String?> getToken() async {
    final instance = ApiClient();
    return await instance.getAccessToken();
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '${ApiConfig.auth}/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {}),
      );

      if (response.statusCode == 200) {
        await _storage.write(
          key: AppConstants.accessTokenKey,
          value: response.data['data']['accessToken'],
        );
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: response.data['data']['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Generic HTTP methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    Function(int, int)? onSendProgress,
  }) async {
    return _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  // Token management
  Future<void> setTokens(String accessToken, String refreshToken) async {
    final normalizedAccessToken = _normalizeToken(accessToken);
    final normalizedRefreshToken = _normalizeToken(refreshToken);
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: normalizedAccessToken),
      _storage.write(key: 'token', value: normalizedAccessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: normalizedRefreshToken),
      _encryptedStorage.write(key: AppConstants.accessTokenKey, value: normalizedAccessToken),
      _encryptedStorage.write(key: 'token', value: normalizedAccessToken),
      _encryptedStorage.write(key: AppConstants.refreshTokenKey, value: normalizedRefreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: 'token'),
      _storage.delete(key: 'auth_token'),
      _storage.delete(key: 'jwt'),
      _storage.delete(key: AppConstants.refreshTokenKey),
      _encryptedStorage.delete(key: AppConstants.accessTokenKey),
      _encryptedStorage.delete(key: 'token'),
      _encryptedStorage.delete(key: 'auth_token'),
      _encryptedStorage.delete(key: 'jwt'),
      _encryptedStorage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }

  Future<String?> getAccessToken() async {
    for (final key in _legacyAccessTokenKeys) {
      final rawToken = await _readTokenFromAnyStore(key);
      final token = _normalizeToken(rawToken);
      if (token != null && token.isNotEmpty) {
        if (key != AppConstants.accessTokenKey) {
          await Future.wait([
            _storage.write(key: AppConstants.accessTokenKey, value: token),
            _encryptedStorage.write(key: AppConstants.accessTokenKey, value: token),
          ]);
        }
        return token;
      }
    }
    return null;
  }

Future<String?> _readTokenFromAnyStore(String key) async {
  final rawDefaultToken = await _storage.read(key: key);
  if (_normalizeToken(rawDefaultToken)?.isNotEmpty == true) return rawDefaultToken;

  try {
    return await _encryptedStorage.read(key: key);
  } catch (_) {
    return null;
  }
}

String? _normalizeToken(String? token) {
  final trimmed = token?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '').trim();
}

Future<Map<String, dynamic>> executeWithRetry(
  Future<Response> Function() request,
  {int maxRetries = 3}
) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      final response = await request();
      return _parseApiResponse(response);
    } on DioException catch (e) {
      if (attempt == maxRetries || 
          e.type != DioExceptionType.connectionTimeout && 
          e.type != DioExceptionType.receiveTimeout &&
          e.type != DioExceptionType.connectionError) {
        rethrow;
      }
      debugPrint('🔄 ApiClient retry $attempt/$maxRetries for ${e.type}');
      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }
  throw Exception('Max retries exceeded');
}

Map<String, dynamic> _parseApiResponse(Response response) {
  final data = response.data;
  if (data is Map<String, dynamic> && data['success'] == true) {
    return data['data'] ?? {};
  }
  return data ?? {};
}

String parseDioError(
    DioException e, {
    String defaultMessage = 'Something went wrong. Please try again.',
  }) {
    debugPrint('🔍 ApiClient parseDioError: type=${e.type}, error=${e.error}, status=${e.response?.statusCode}');
    if (e.response != null) {
      debugPrint('📡 Full response data: ${e.response!.data}');
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        debugPrint('🌐 ConnectionError detected - checking if truly offline');
        return 'Connection issue. Please check your internet connection and try again.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        String? extractedMessage;
        if (data is Map<String, dynamic>) {
          extractedMessage = data['message']?.toString() ??
              (data['error'] is Map<String, dynamic>
                  ? data['error']['message']?.toString()
                  : null);
        } else if (data is Map) {
          final mapped = Map<String, dynamic>.from(data);
          extractedMessage = mapped['message']?.toString();
        }

        if (extractedMessage != null && extractedMessage.trim().isNotEmpty) {
          if (extractedMessage.toLowerCase().contains('no token provided')) {
            return 'Login required. Please login again and retry.';
          }
          return extractedMessage;
        }

        if (statusCode == 400) return 'Invalid request.';
        if (statusCode == 401) return 'Unauthorized. Please login again.';
        if (statusCode == 403) return 'You do not have permission for this action.';
        if (statusCode == 404) return 'Requested resource not found.';
        if (statusCode == 409) return 'Conflict occurred. Please retry.';
        if (statusCode == 422) return 'Validation failed. Please check input.';
        if (statusCode != null && statusCode >= 500) {
          return 'Server error. Please try again later.';
        }
        return defaultMessage;
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          debugPrint('🔌 SocketException: ${(e.error as SocketException).address}');
          return 'No Internet Connection. Please check your network.';
        }
        return e.message ?? defaultMessage;
    }
  }
}
