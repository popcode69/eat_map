import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithPhone({
    required String phone,
    required String code,
  });

  Future<Either<Failure, UserEntity>> signInWithGoogle({
    required String googleId,
    required String email,
    required String displayName,
    required String username,
    String? avatarUrl,
    required String deviceToken,
    required String deviceId,
  });

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, UserEntity>> uploadAvatar({required String filePath});

  Future<Either<Failure, Unit>> updateLocation({
    required double lat,
    required double lng,
  });

  Future<Either<Failure, UserEntity>> updateProfile({
    String? username,
    String? displayName,
    String? city,
    String? avatarUrl,
  });
}
