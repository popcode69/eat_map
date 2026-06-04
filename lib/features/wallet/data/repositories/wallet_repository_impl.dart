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

  WalletRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Either<Failure, double>> getWalletBalance() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.walletBalance);
      final body = response.data as Map<String, dynamic>;
      // API returns both 'balance' and 'wallet_balance'; prefer 'balance'.
      final balance =
          ((body['balance'] ?? body['wallet_balance']) as num?)?.toDouble() ??
              0.0;
      return Right(balance);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        return const Right(0.0);
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
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(txs);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        return const Right([]);
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
      return Right(tx);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        return const Left(NetworkFailure('No connection — withdrawal requires internet.'));
      }
      // Surface the backend's error message if available.
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        final msg = (body['detail'] ?? body['message'])?.toString();
        if (msg != null && msg.isNotEmpty) {
          return Left(DomainFailure(msg));
        }
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
