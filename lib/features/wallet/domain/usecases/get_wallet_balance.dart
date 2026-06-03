import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/wallet_repository.dart';

class GetWalletBalance {
  final WalletRepository repository;

  const GetWalletBalance(this.repository);

  Future<Either<Failure, double>> call() async {
    return await repository.getWalletBalance();
  }
}
