import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../models/wallet_model.dart';
import '../../core/services/api_client.dart';

class WalletService {
  final ApiClient _apiClient = ApiClient();

  /// Get wallet balance
  Future<Wallet> getWalletBalance() async {
    try {
      final responseData = await _apiClient.executeWithRetry(
        () => _apiClient.get('${ApiConfig.wallet}'),
        maxRetries: 3
      );
      final data = responseData is Map<String, dynamic> ? responseData : (responseData['data'] as Map<String, dynamic>? ?? {});
      return Wallet.fromJson(data);
    } catch (e) {
      debugPrint('Wallet balance error (fallback): $e');
      // Safe empty wallet fallback
      return Wallet(
        id: '',
        userId: '',
        balance: 0.0,
        totalCredits: 0.0,
        totalDebits: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Get all transactions
  Future<List<Transaction>> getTransactions({int page = 1, int limit = 20, String? type}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };
      
      final responseData = await _apiClient.executeWithRetry(
        () => _apiClient.get('${ApiConfig.wallet}/transactions', queryParameters: queryParams),
        maxRetries: 3
      );
      final data = responseData is List ? responseData : (responseData['data'] as List? ?? []);
    return (data as List<Map<String, dynamic>>).map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Wallet transactions error (empty fallback): $e');
      return [];
    }
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
    return data.cast<Map<String, dynamic>>().map((json) => Transaction.fromJson(json)).toList();
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
    return data.cast<Map<String, dynamic>>().map((json) => Transaction.fromJson(json)).toList();
  }
}

