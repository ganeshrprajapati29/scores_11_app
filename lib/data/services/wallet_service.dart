import '../models/wallet_model.dart';
import '../../core/services/api_client.dart';

class WalletService {
  final ApiClient _apiClient = ApiClient();

  Future<Wallet> getWalletBalance() async {
    final response = await _apiClient.get('/wallet');
    return Wallet.fromJson(response['data']);
  }

  Future<List<Transaction>> getTransactions({int page = 1, int limit = 20, String? type}) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type,
    };
    
    final response = await _apiClient.get('/wallet/transactions', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<Wallet> addFunds(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/wallet/add-funds', data);
    return Wallet.fromJson(response['data']);
  }

  Future<Wallet> withdraw(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/wallet/withdraw', data);
    return Wallet.fromJson(response['data']);
  }

  Future<Map<String, dynamic>> getAdminOverview() async {
    final response = await _apiClient.get('/wallet/admin/overview');
    return response['data'] ?? {};
  }

  Future<List<Transaction>> getAllTransactions({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/wallet/admin/transactions', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Transaction.fromJson(json)).toList();
  }
}

