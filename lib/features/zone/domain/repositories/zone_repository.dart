import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/zone_entity.dart';

abstract class ZoneRepository {
  Future<Either<Failure, List<ZoneEntity>>> getNearbyZones({
    required String geohash,
  });

  Future<Either<Failure, ZoneEntity>> getZoneDetail({
    required String zoneId,
  });

  Future<Either<Failure, ZoneEntity>> customizeZone({
    required String zoneId,
    required String title,
    required String colour,
    required String icon,
  });
}
