import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';

class DiscoveryService {
  final ApiClient _apiClient = ApiClient();

  /// Get all discovery items with filters
  Future<Map<String, dynamic>> getAllDiscoveryItems({
    String? type,
    String? location,
    String? search,
    String? isPro,
    double? latitude,
    double? longitude,
    int? radius,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (type != null && type != 'all') queryParams['type'] = type;
      if (location != null && location != 'All Locations') queryParams['location'] = location;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (isPro != null) queryParams['isPro'] = isPro;
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (radius != null) queryParams['radius'] = radius.toString();
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final response = await _apiClient.get('${ApiConfig.discovery}/items', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load discovery items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get discovery item by ID
  Future<Map<String, dynamic>> getDiscoveryItemById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.discovery}/items/$id');
      
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      } else {
        throw Exception('Failed to load discovery item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Create discovery item
  Future<Map<String, dynamic>> createDiscoveryItem(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('${ApiConfig.discovery}/items', data: data);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to create discovery item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Update discovery item
  Future<Map<String, dynamic>> updateDiscoveryItem(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('${ApiConfig.discovery}/items/$id', data: data);
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update discovery item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Delete discovery item
  Future<bool> deleteDiscoveryItem(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.discovery}/items/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get nearby discovery items
  Future<Map<String, dynamic>> getNearbyItems({
    required double latitude,
    required double longitude,
    int radius = 10,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      };
      if (type != null && type != 'all') queryParams['type'] = type;

      final response = await _apiClient.get('${ApiConfig.discovery}/nearby', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load nearby items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get popular discovery items
  Future<Map<String, dynamic>> getPopularItems({int limit = 10, String? type}) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit.toString()};
      if (type != null && type != 'all') queryParams['type'] = type;

      final response = await _apiClient.get('${ApiConfig.discovery}/popular', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load popular items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get featured PRO items
  Future<Map<String, dynamic>> getFeaturedProItems({int limit = 10}) async {
    try {
      final response = await _apiClient.get('${ApiConfig.discovery}/featured', queryParameters: {'limit': limit.toString()});
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load featured items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get unique locations
  Future<List<String>> getLocations() async {
    try {
      final response = await _apiClient.get('${ApiConfig.discovery}/locations');
      
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];
        return List<String>.from(data);
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get my discovery items
  Future<Map<String, dynamic>> getMyDiscoveryItems() async {
    try {
      final response = await _apiClient.get('${ApiConfig.discovery}/my-items');
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load my items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout';
      case DioExceptionType.badResponse:
        return e.response?.data['message'] ?? 'Server error (${e.response?.statusCode})';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      default:
        return e.message ?? 'Unknown error';
    }
  }
}
