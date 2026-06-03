import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object> get props => [];
}

class LoadWalletRequested extends WalletEvent {}

class WithdrawFundsRequested extends WalletEvent {
  final double amount;
  final String upiId;

  const WithdrawFundsRequested({
    required this.amount,
    required this.upiId,
  });

  @override
  List<Object> get props => [amount, upiId];
}
