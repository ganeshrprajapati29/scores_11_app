import '../../core/config/api_config.dart';
import '../models/wallet_model.dart';
import '../../core/services/api_client.dart';

class WalletService {
  final ApiClient _apiClient = ApiClient();

  /// Get wallet balance
  Future<Wallet> getWalletBalance() async {
    final response = await _apiClient.get('${ApiConfig.wallet}');
    return Wallet.fromJson(response.data['data']);
  }

  /// Get all transactions
  Future<List<Transaction>> getTransactions({int page = 1, int limit = 20, String? type}) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type,
    };
    
    final response = await _apiClient.get('${ApiConfig.wallet}/transactions', queryParameters: queryParams);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => Transaction.fromJson(json)).toList();
  }

  /// Add funds to wallet
  Future<Wallet> addFunds(Map<String, dynamic> data) async {
    final response = await _apiClient.post('${ApiConfig.wallet}/deposit', data: data);
    return Wallet.fromJson(response.data['data']);
  }

  /// Withdraw funds from wallet
  Future<Wallet> withdraw(Map<String, dynamic> data) async {
    final response = await _apiClient.post('${ApiConfig.wallet}/withdraw', data: data);
    return Wallet.fromJson(response.data['data']);
  }

  /// Get admin overview
  Future<Map<String, dynamic>> getAdminOverview() async {
    final response = await _apiClient.get('${ApiConfig.wallet}/admin/overview');
    return response.data['data'] ?? {};
  }

  /// Get all transactions (admin)
  Future<List<Transaction>> getAllTransactions({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get(
      '${ApiConfig.wallet}/admin/transactions', 
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => Transaction.fromJson(json)).toList();
  }

  /// Get wallet statement
  Future<Map<String, dynamic>> getStatement({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get(
      '${ApiConfig.wallet}/statement', 
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return response.data['data'] ?? {};
  }

  /// Transfer funds to another user
  Future<Wallet> transfer(Map<String, dynamic> data) async {
    final response = await _apiClient.post('${ApiConfig.wallet}/transfer', data: data);
    return Wallet.fromJson(response.data['data']);
  }

  /// Enter a contest
  Future<Map<String, dynamic>> enterContest(String contestId) async {
    final response = await _apiClient.post(
      '${ApiConfig.wallet}/contest/enter', 
      data: {'contestId': contestId},
    );
    return response.data['data'] ?? {};
  }

  /// Get transaction by ID
  Future<Transaction> getTransactionById(String id) async {
    final response = await _apiClient.get('${ApiConfig.wallet}/transactions/$id');
    return Transaction.fromJson(response.data['data']);
  }

  /// Get contest transactions
  Future<List<Transaction>> getContestTransactions(String contestId) async {
    final response = await _apiClient.get('${ApiConfig.wallet}/transactions/contest/$contestId');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => Transaction.fromJson(json)).toList();
  }
}

