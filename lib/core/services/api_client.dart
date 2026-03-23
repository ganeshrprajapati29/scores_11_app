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
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            final token = await _storage.read(key: AppConstants.accessTokenKey);
            opts.headers['Authorization'] = 'Bearer $token';
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
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
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