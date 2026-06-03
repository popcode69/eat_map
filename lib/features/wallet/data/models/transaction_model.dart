import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.type,
    required super.status,
    required super.title,
    required super.createdAt,
    super.upiId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      upiId: json['upi_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'status': status,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      if (upiId != null) 'upi_id': upiId,
    };
  }
}
