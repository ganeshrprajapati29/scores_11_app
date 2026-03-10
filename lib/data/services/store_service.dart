import '../../core/services/api_client.dart';

/// Pagination response wrapper for products
class PaginatedProducts {
  final List<Map<String, dynamic>> products;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedProducts({
    required this.products,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

class StoreService {
  final ApiClient _apiClient = ApiClient();

  /// Get products with pagination support
  Future<PaginatedProducts> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    final queryParameters = {
      'page': page,
      'limit': limit,
      if (category != null) 'category': category,
    };
    final response = await _apiClient.get('/store/products', queryParameters: queryParameters);
    final List<dynamic> data = response.data['data'] ?? [];
    final pagination = response.data['pagination'] ?? {};
    
    final products = List<Map<String, dynamic>>.from(data);
    
    return PaginatedProducts(
      products: products,
      page: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
      total: pagination['total'] ?? data.length,
      totalPages: pagination['pages'] ?? 1,
      hasMore: page < (pagination['pages'] ?? 1),
    );
  }

  /// Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> getProductsList({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    final result = await getProducts(page: page, limit: limit, category: category);
    return result.products;
  }

  Future<Map<String, dynamic>> getProductById(String id) async {
    final response = await _apiClient.get('/store/products/$id');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final response = await _apiClient.post('/store/products', data: productData);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    final response = await _apiClient.put('/store/products/$id', data: productData);
    return response.data['data'] ?? {};
  }

  Future<void> deleteProduct(String id) async {
    await _apiClient.delete('/store/products/$id');
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _apiClient.get('/store/categories');
    final List<dynamic> data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  // Cart operations
  Future<Map<String, dynamic>> getCart() async {
    final response = await _apiClient.get('/store/cart');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> addToCart(String productId, int quantity) async {
    final response = await _apiClient.post('/store/cart/add', data: {
      'productId': productId,
      'quantity': quantity,
    });
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateCartItem(String itemId, int quantity) async {
    final response = await _apiClient.put('/store/cart/item/$itemId', data: {
      'quantity': quantity,
    });
    return response.data['data'] ?? {};
  }

  Future<void> removeFromCart(String itemId) async {
    await _apiClient.delete('/store/cart/item/$itemId');
  }

  Future<void> clearCart() async {
    await _apiClient.delete('/store/cart/clear');
  }

  // Order operations
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> checkoutData) async {
    final response = await _apiClient.post('/store/checkout', data: checkoutData);
    return response.data['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getOrders({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/store/orders', queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getOrderById(String id) async {
    final response = await _apiClient.get('/store/orders/$id');
    return response.data['data'] ?? {};
  }

  Future<void> cancelOrder(String id) async {
    await _apiClient.post('/store/orders/$id/cancel');
  }
}

