import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class UpdateLocation {
  final AuthRepository _repository;
  UpdateLocation(this._repository);

  Future<Either<Failure, Unit>> call({required double lat, required double lng}) {
    return _repository.updateLocation(lat: lat, lng: lng);
  }
}
