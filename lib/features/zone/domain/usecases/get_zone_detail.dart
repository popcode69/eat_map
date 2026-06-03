import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/zone_entity.dart';
import '../repositories/zone_repository.dart';

class GetZoneDetail {
  final ZoneRepository _repository;

  GetZoneDetail(this._repository);

  Future<Either<Failure, ZoneEntity>> call({
    required String zoneId,
  }) async {
    return await _repository.getZoneDetail(zoneId: zoneId);
  }
}
