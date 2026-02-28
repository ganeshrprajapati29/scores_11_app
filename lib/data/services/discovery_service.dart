import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class DiscoveryService {
  final String baseUrl = ApiConfig.baseUrl;

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
      final queryParams = <String, String>{
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

      final uri = Uri.parse('$baseUrl/discovery/items').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load discovery items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get discovery item by ID
  Future<Map<String, dynamic>> getDiscoveryItemById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/discovery/items/$id'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load discovery item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Create discovery item
  Future<Map<String, dynamic>> createDiscoveryItem(Map<String, dynamic> data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/discovery/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create discovery item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Update discovery item
  Future<Map<String, dynamic>> updateDiscoveryItem(String id, Map<String, dynamic> data, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/discovery/items/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update discovery item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Delete discovery item
  Future<bool> deleteDiscoveryItem(String id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/discovery/items/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
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
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      };
      if (type != null && type != 'all') queryParams['type'] = type;

      final uri = Uri.parse('$baseUrl/discovery/nearby').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load nearby items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get popular discovery items
  Future<Map<String, dynamic>> getPopularItems({int limit = 10, String? type}) async {
    try {
      final queryParams = <String, String>{'limit': limit.toString()};
      if (type != null && type != 'all') queryParams['type'] = type;

      final uri = Uri.parse('$baseUrl/discovery/popular').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load popular items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get featured PRO items
  Future<Map<String, dynamic>> getFeaturedProItems({int limit = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/discovery/featured').replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load featured items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get unique locations
  Future<List<String>> getLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/discovery/locations'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get my discovery items
  Future<Map<String, dynamic>> getMyDiscoveryItems(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/discovery/my-items'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load my items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
