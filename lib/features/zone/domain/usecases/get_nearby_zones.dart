import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/zone_entity.dart';
import '../repositories/zone_repository.dart';

class GetNearbyZones {
  final ZoneRepository _repository;

  GetNearbyZones(this._repository);

  Future<Either<Failure, List<ZoneEntity>>> call({
    required String geohash,
  }) async {
    return await _repository.getNearbyZones(geohash: geohash);
  }
}
