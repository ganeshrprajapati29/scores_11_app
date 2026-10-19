import '../../core/services/api_client.dart';

/// Mirrors backend/src/modules/subscription/subscription.routes.js
class SubscriptionService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getPlans() async {
    final response = await _apiClient.get('/subscriptions/plans/list');
    final data = response.data['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Future<Map<String, dynamic>> getPlanDetails(String planId) async {
    final plans = await getPlans();
    return plans.firstWhere((p) => p['id'] == planId, orElse: () => {});
  }

  /// Active subscription, normalised so the screen can read planId/planName.
  Future<Map<String, dynamic>> getCurrentSubscription() async {
    final response = await _apiClient.get('/subscriptions/my');
    final data = response.data['data'];
    if (data is! Map) return {};
    return _normalise(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> subscribe(
    String planId,
    Map<String, dynamic> paymentData,
  ) async {
    final response = await _apiClient.post('/subscriptions/subscribe', data: {
      'plan': planId,
      'durationMonths': paymentData['durationMonths'] ?? 1,
    });
    final data = response.data['data'];
    return data is Map ? _normalise(Map<String, dynamic>.from(data)) : {};
  }

  Future<Map<String, dynamic>> upgrade(String planId) async {
    final response =
        await _apiClient.post('/subscriptions/upgrade', data: {'plan': planId});
    final data = response.data['data'];
    return data is Map ? _normalise(Map<String, dynamic>.from(data)) : {};
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    await _apiClient.patch('/subscriptions/cancel/$subscriptionId');
  }

  /// Renewing extends the active plan by a month (backend upgrade semantics).
  Future<void> renewSubscription(String planId) async {
    await upgrade(planId);
  }

  Map<String, dynamic> _normalise(Map<String, dynamic> sub) {
    final plan = sub['plan']?.toString() ?? '';
    final endDate = DateTime.tryParse(sub['endDate']?.toString() ?? '');
    return {
      ...sub,
      'id': sub['_id'] ?? sub['id'],
      'planId': plan,
      'planName': plan.isEmpty
          ? ''
          : plan[0] + plan.substring(1).toLowerCase(),
      if (endDate != null)
        'endDate':
            '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
    };
  }
}
