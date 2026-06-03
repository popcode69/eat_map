import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final double balance;
  final List<TransactionEntity> transactions;

  const WalletLoaded({
    required this.balance,
    required this.transactions,
  });

  @override
  List<Object?> get props => [balance, transactions];
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object> get props => [message];
}

class WithdrawalInProgress extends WalletState {}

class WithdrawalSuccess extends WalletState {
  final TransactionEntity transaction;
  final String message;

  const WithdrawalSuccess({
    required this.transaction,
    required this.message,
  });

  @override
  List<Object?> get props => [transaction, message];
}

class WithdrawalFailure extends WalletState {
  final String message;

  const WithdrawalFailure(this.message);

  @override
  List<Object> get props => [message];
}
