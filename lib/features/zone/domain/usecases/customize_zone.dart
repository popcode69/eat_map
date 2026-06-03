import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/zone_entity.dart';
import '../repositories/zone_repository.dart';

class CustomizeZone {
  final ZoneRepository _repository;

  CustomizeZone(this._repository);

  Future<Either<Failure, ZoneEntity>> call({
    required String zoneId,
    required String title,
    required String colour,
    required String icon,
  }) async {
    return await _repository.customizeZone(
      zoneId: zoneId,
      title: title,
      colour: colour,
      icon: icon,
    );
  }
}
