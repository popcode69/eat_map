import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfile {
  final AuthRepository _repository;
  UpdateProfile(this._repository);

  Future<Either<Failure, UserEntity>> call({
    String? username,
    String? displayName,
    String? city,
    String? avatarUrl,
  }) =>
      _repository.updateProfile(
        username: username,
        displayName: displayName,
        city: city,
        avatarUrl: avatarUrl,
      );
}
