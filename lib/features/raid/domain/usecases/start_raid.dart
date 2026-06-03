import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/raid_entity.dart';
import '../repositories/raid_repository.dart';

class StartRaid {
  final RaidRepository _repository;

  StartRaid(this._repository);

  Future<Either<Failure, RaidEntity>> call({
    required String zoneId,
    required double lat,
    required double lng,
    required String deviceId,
  }) async {
    return await _repository.startRaid(
      zoneId: zoneId,
      lat: lat,
      lng: lng,
      deviceId: deviceId,
    );
  }
}
