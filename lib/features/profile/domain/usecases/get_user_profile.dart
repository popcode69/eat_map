import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/user_profile_repository.dart';

class GetUserProfile {
  final UserProfileRepository _repository;

  GetUserProfile(this._repository);

  Future<Either<Failure, UserProfileEntity>> call({
    required String userId,
  }) async {
    return await _repository.getUserProfile(userId: userId);
  }
}
