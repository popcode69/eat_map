import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/zone_raider_entity.dart';
import '../repositories/zone_repository.dart';

class GetZoneRaiders {
  final ZoneRepository _repository;

  GetZoneRaiders(this._repository);

  Future<Either<Failure, List<ZoneRaiderEntity>>> call({
    required String zoneId,
  }) async {
    return await _repository.getZoneRaiders(zoneId: zoneId);
  }
}
