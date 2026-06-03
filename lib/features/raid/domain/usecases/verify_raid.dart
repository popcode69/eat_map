import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/raid_repository.dart';

class VerifyRaid {
  final RaidRepository _repository;

  VerifyRaid(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String raidId,
    required double spendAmount,
    String? upiRef,
    String? billPhotoPath,
  }) async {
    return await _repository.verifyRaid(
      raidId: raidId,
      spendAmount: spendAmount,
      upiRef: upiRef,
      billPhotoPath: billPhotoPath,
    );
  }
}
