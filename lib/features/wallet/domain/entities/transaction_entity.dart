import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final double amount;
  final String type; // 'reward' | 'withdrawal' | 'bonus'
  final String status; // 'success' | 'pending' | 'failed'
  final String title;
  final DateTime createdAt;
  final String? upiId;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.title,
    required this.createdAt,
    this.upiId,
  });

  @override
  List<Object?> get props => [id, amount, type, status, title, createdAt, upiId];
}
