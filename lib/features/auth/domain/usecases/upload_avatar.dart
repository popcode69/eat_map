import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UploadAvatar {
  final AuthRepository _repository;
  UploadAvatar(this._repository);

  Future<Either<Failure, UserEntity>> call({required String filePath}) {
    return _repository.uploadAvatar(filePath: filePath);
  }
}
