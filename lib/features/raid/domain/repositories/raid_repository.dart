import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/raid_entity.dart';

abstract class RaidRepository {
  Future<Either<Failure, RaidEntity>> startRaid({
    required String zoneId,
    required double lat,
    required double lng,
    required String deviceId,
  });

  Future<Either<Failure, Map<String, dynamic>>> verifyRaid({
    required String raidId,
    required double spendAmount,
    String? upiRef,
    String? billPhotoPath,
  });
}
