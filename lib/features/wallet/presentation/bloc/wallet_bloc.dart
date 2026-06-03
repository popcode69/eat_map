import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_wallet_balance.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/request_withdrawal.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletBalance getWalletBalance;
  final GetTransactions getTransactions;
  final RequestWithdrawal requestWithdrawal;

  double _cachedBalance = 0.0;
  var _cachedTransactions = const <dynamic>[];

  double get cachedBalance => _cachedBalance;
  List<dynamic> get cachedTransactions => _cachedTransactions;


  WalletBloc({
    required this.getWalletBalance,
    required this.getTransactions,
    required this.requestWithdrawal,
  }) : super(WalletInitial()) {
    on<LoadWalletRequested>(_onLoadWalletRequested);
    on<WithdrawFundsRequested>(_onWithdrawFundsRequested);
  }

  Future<void> _onLoadWalletRequested(
    LoadWalletRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    
    final balanceResult = await getWalletBalance();
    final txsResult = await getTransactions();

    await balanceResult.fold(
      (failure) async {
        emit(WalletError(failure.message));
      },
      (balance) async {
        _cachedBalance = balance;
        await txsResult.fold(
          (failure) async {
            emit(WalletError(failure.message));
          },
          (txs) async {
            _cachedTransactions = txs;
            emit(WalletLoaded(balance: balance, transactions: txs));
          },
        );
      },
    );
  }

  Future<void> _onWithdrawFundsRequested(
    WithdrawFundsRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(WithdrawalInProgress());

    final result = await requestWithdrawal(
      amount: event.amount,
      upiId: event.upiId,
    );

    await result.fold(
      (failure) async {
        emit(WithdrawalFailure(failure.message));
        // Re-emit loaded state with cached values
        emit(WalletLoaded(
          balance: _cachedBalance,
          transactions: List.from(_cachedTransactions),
        ));
      },
      (tx) async {
        emit(WithdrawalSuccess(
          transaction: tx,
          message: 'Withdrawal of ₹${event.amount.toStringAsFixed(0)} initiated successfully! 🚀',
        ));
        // Refresh entire wallet balance & history
        add(LoadWalletRequested());
      },
    );
  }
}
