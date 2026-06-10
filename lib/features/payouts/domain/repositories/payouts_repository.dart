import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/warlord_estimate_entity.dart';

abstract class PayoutsRepository {
  /// GET /payouts/warlord/estimate — live projection of the user's monthly
  /// Warlord pool share. Read-only, no payout is triggered.
  Future<Either<Failure, WarlordEstimateEntity>> getWarlordEstimate();
}
