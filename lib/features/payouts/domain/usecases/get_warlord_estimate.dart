import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/warlord_estimate_entity.dart';
import '../repositories/payouts_repository.dart';

class GetWarlordEstimate {
  final PayoutsRepository _repository;

  GetWarlordEstimate(this._repository);

  Future<Either<Failure, WarlordEstimateEntity>> call() async {
    return await _repository.getWarlordEstimate();
  }
}
