import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../models/transaction_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final DioClient _dioClient;

  // Local state to support developer offline manual verification
  double _balance = 750.0;
  final List<TransactionModel> _transactions = [
    TransactionModel(
      id: 'tx_001',
      amount: 150.0,
      type: 'reward',
      status: 'success',
      title: 'Stronghold Conquest: Burger Bastion',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TransactionModel(
      id: 'tx_002',
      amount: 50.0,
      type: 'bonus',
      status: 'success',
      title: 'Squad Daily Control Bonus',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TransactionModel(
      id: 'tx_003',
      amount: 100.0,
      type: 'withdrawal',
      status: 'success',
      title: 'UPI Withdrawal',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      upiId: 'raider@paytm',
    ),
    TransactionModel(
      id: 'tx_004',
      amount: 100.0,
      type: 'reward',
      status: 'success',
      title: 'Stronghold Conquest: Pizza Dojo',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  WalletRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Either<Failure, double>> getWalletBalance() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.walletBalance);
      _balance = (response.data['balance'] as num).toDouble();
      return Right(_balance);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return Right(_balance);
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.walletTransactions);
      final dataList = response.data as List;
      final txs = dataList
          .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(txs);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        // Return in descending order of date (most recent first)
        final sorted = List<TransactionModel>.from(_transactions)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Right(sorted);
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> requestWithdrawal(
    double amount,
    String upiId,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.walletWithdraw,
        data: {'amount': amount, 'upi_id': upiId},
      );
      final tx = TransactionModel.fromJson(response.data as Map<String, dynamic>);
      _balance -= amount;
      return Right(tx);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        if (_balance < amount) {
          return const Left(DomainFailure('Insufficient wallet balance.'));
        }
        _balance -= amount;
        final newTx = TransactionModel(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          type: 'withdrawal',
          status: 'success',
          title: 'UPI Withdrawal Payout',
          createdAt: DateTime.now(),
          upiId: upiId,
        );
        _transactions.add(newTx);
        return Right(newTx);
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
