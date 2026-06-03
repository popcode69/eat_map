import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithPhone {
  final AuthRepository _repository;

  SignInWithPhone(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String phone,
    required String code,
  }) async {
    return await _repository.signInWithPhone(phone: phone, code: code);
  }
}
