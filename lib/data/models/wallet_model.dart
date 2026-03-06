class Wallet {
  final String id;
  final String userId;
  final double balance;
  final double totalCredits;
  final double totalDebits;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.totalCredits,
    required this.totalDebits,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      totalCredits: (json['totalCredits'] ?? 0).toDouble(),
      totalDebits: (json['totalDebits'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'totalCredits': totalCredits,
      'totalDebits': totalDebits,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Transaction {
  final String id;
  final String userId;
  final String? walletId;
  final double amount;
  final String type; // credit, debit
  final String? description;
  final String? referenceId;
  final String? referenceType;
  final String status; // pending, completed, failed
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    this.walletId,
    required this.amount,
    required this.type,
    this.description,
    this.referenceId,
    this.referenceType,
    required this.status,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      walletId: json['walletId'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'debit',
      description: json['description'],
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      status: json['status'] ?? 'completed',
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'amount': amount,
      'type': type,
      'description': description,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

