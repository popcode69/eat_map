import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/transaction_entity.dart';

abstract class WalletRepository {
  Future<Either<Failure, double>> getWalletBalance();
  Future<Either<Failure, List<TransactionEntity>>> getTransactions();
  Future<Either<Failure, TransactionEntity>> requestWithdrawal(double amount, String upiId);
}
