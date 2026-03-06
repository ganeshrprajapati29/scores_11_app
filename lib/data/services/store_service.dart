import '../../core/services/api_client.dart';

class StoreService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getProducts({int page = 1, int limit = 20, String? category}) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (category != null) 'category': category,
    };
    final response = await _apiClient.get('/store/products', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getProductById(String id) async {
    final response = await _apiClient.get('/store/products/$id');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final response = await _apiClient.post('/store/products', productData);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    final response = await _apiClient.put('/store/products/$id', productData);
    return response['data'] ?? {};
  }

  Future<void> deleteProduct(String id) async {
    await _apiClient.delete('/store/products/$id');
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _apiClient.get('/store/categories');
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  // Cart operations
  Future<Map<String, dynamic>> getCart() async {
    final response = await _apiClient.get('/store/cart');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> addToCart(String productId, int quantity) async {
    final response = await _apiClient.post('/store/cart/add', {
      'productId': productId,
      'quantity': quantity,
    });
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateCartItem(String itemId, int quantity) async {
    final response = await _apiClient.put('/store/cart/item/$itemId', {
      'quantity': quantity,
    });
    return response['data'] ?? {};
  }

  Future<void> removeFromCart(String itemId) async {
    await _apiClient.delete('/store/cart/item/$itemId');
  }

  Future<void> clearCart() async {
    await _apiClient.delete('/store/cart/clear');
  }

  // Order operations
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> checkoutData) async {
    final response = await _apiClient.post('/store/checkout', checkoutData);
    return response['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getOrders({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/store/orders', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getOrderById(String id) async {
    final response = await _apiClient.get('/store/orders/$id');
    return response['data'] ?? {};
  }

  Future<void> cancelOrder(String id) async {
    await _apiClient.post('/store/orders/$id/cancel');
  }
}

