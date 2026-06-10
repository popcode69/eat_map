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

  /// Presence-only verification. A raid is valid only after the user has
  /// physically stayed the required time (MIN_RAID_MINUTES) — there is no
  /// bill/spend/UPI flow anymore. [photoPath] is an optional presence photo.
  Future<Either<Failure, Map<String, dynamic>>> verifyRaid({
    required String raidId,
    String? photoPath,
  });
}
