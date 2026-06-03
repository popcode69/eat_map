import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/transaction_entity.dart';
import '../repositories/wallet_repository.dart';

class RequestWithdrawal {
  final WalletRepository repository;

  const RequestWithdrawal(this.repository);

  Future<Either<Failure, TransactionEntity>> call({
    required double amount,
    required String upiId,
  }) async {
    if (amount < 100.0) {
      return const Left(DomainFailure('Minimum withdrawal amount is ₹100.'));
    }
    
    // Basic UPI ID validation
    if (!upiId.contains('@') || upiId.length < 3) {
      return const Left(DomainFailure('Invalid UPI ID format.'));
    }

    return await repository.requestWithdrawal(amount, upiId);
  }
}
