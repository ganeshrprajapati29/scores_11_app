import '../../core/services/api_client.dart';

class SubscriptionService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getPlans() async {
    final response = await _apiClient.get('/subscriptions/plans');
    final List<dynamic> data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getPlanDetails(String planId) async {
    final response = await _apiClient.get('/subscriptions/plans/$planId');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getCurrentSubscription() async {
    final response = await _apiClient.get('/subscriptions/current');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> subscribe(String planId, Map<String, dynamic> paymentData) async {
    final response = await _apiClient.post('/subscriptions', data: {
      'planId': planId,
      ...paymentData,
    });
    return response.data['data'] ?? {};
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    await _apiClient.post('/subscriptions/$subscriptionId/cancel');
  }

  Future<void> renewSubscription(String subscriptionId) async {
    await _apiClient.post('/subscriptions/$subscriptionId/renew');
  }

  Future<List<Map<String, dynamic>>> getSubscribers({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/subscriptions/subscribers', queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }
}

