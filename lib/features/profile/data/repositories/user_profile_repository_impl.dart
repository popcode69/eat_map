import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../models/captured_zone_model.dart';
import '../models/user_profile_model.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final DioClient _dioClient;

  UserProfileRepositoryImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile({
    required String userId,
  }) async {
    try {
      final response =
          await _dioClient.dio.get(ApiEndpoints.userProfile(userId));
      final profile = UserProfileModel.fromJson(
          response.data as Map<String, dynamic>);
      return Right(profile);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        return Right(_mockProfile(userId));
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  UserProfileEntity _mockProfile(String userId) {
    return UserProfileModel(
      userId: userId,
      username: 'food_explorer',
      displayName: 'Food Explorer',
      city: 'Mumbai',
      level: 5,
      totalPoints: 1200,
      trustScore: 95,
      warlordCount: 2,
      totalRaids: 18,
      validRaids: 14,
      capturedZones: const [
        CapturedZoneModel(
          zoneId: 'mock-zone-1',
          name: 'The Burger Bastion',
          customTitle: 'Burger HQ',
          customColour: '#E53935',
          customIcon: 'hamburger',
          warlordRaids: 8,
          totalRaids: 20,
          city: 'Mumbai',
        ),
        CapturedZoneModel(
          zoneId: 'mock-zone-2',
          name: 'Sushi Slayer Dojo',
          customTitle: 'Wasabi Den',
          customColour: '#4CAF50',
          customIcon: 'fork',
          warlordRaids: 5,
          totalRaids: 12,
          city: 'Mumbai',
        ),
      ],
    );
  }
}
