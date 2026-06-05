import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repository;

  SignInWithGoogle(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String googleId,
    required String email,
    required String displayName,
    required String username,
    String? avatarUrl,
    required String deviceToken,
    required String deviceId,
  }) async {
    return await _repository.signInWithGoogle(
      googleId: googleId,
      email: email,
      displayName: displayName,
      username: username,
      avatarUrl: avatarUrl,
      deviceToken: deviceToken,
      deviceId: deviceId,
    );
  }
}
