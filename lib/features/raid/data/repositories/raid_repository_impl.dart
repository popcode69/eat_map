import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/raid_entity.dart';
import '../../domain/repositories/raid_repository.dart';

class RaidRepositoryImpl implements RaidRepository {
  final DioClient _dioClient;

  RaidRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Either<Failure, RaidEntity>> startRaid({
    required String zoneId,
    required double lat,
    required double lng,
    required String deviceId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.startRaid,
        data: {
          'zone_id': zoneId,
          'lat': lat,
          'lng': lng,
          'device_id': deviceId,
        },
      );

      final raid = _mapJsonToRaid(response.data as Map<String, dynamic>, zoneId, deviceId, lat, lng);
      return Right(raid);
    } on DioException catch (e) {
      // Developer Offline Fallback: Start mock raid immediately
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return Right(_getMockRaid(zoneId, deviceId, lat, lng));
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyRaid({
    required String raidId,
    required double spendAmount,
    String? upiRef,
    String? billPhotoPath,
  }) async {
    try {
      // Build form-data for optimized multipart upload (as recommended!)
      final Map<String, dynamic> data = {
        'spend_amount': spendAmount,
      };

      if (upiRef != null && upiRef.isNotEmpty) {
        data['upi_ref'] = upiRef;
      }

      if (billPhotoPath != null && billPhotoPath.isNotEmpty) {
        final file = File(billPhotoPath);
        if (await file.exists()) {
          data['bill_photo'] = await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          );
        }
      }

      final response = await _dioClient.dio.post(
        ApiEndpoints.verifyRaid(raidId),
        data: FormData.fromMap(data),
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Developer Offline Fallback: Return successful mock takeover details!
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return const Right({
          'points': 25.0,
          'rank': 1,
          'is_warlord': true,
        });
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  RaidEntity _mapJsonToRaid(Map<String, dynamic> json, String zoneId, String deviceId, double lat, double lng) {
    return RaidEntity(
      id: json['raid_id'] as String,
      userId: 'd3b07384-d113-4ec5-a55d-3d4c6d6c6e7f',
      zoneId: zoneId,
      startedAt: DateTime.now(),
      durationMins: 2,
      spendAmount: 0.0,
      pointsEarned: 0.0,
      earnRate: 1.0,
      isValid: false,
      deviceId: deviceId,
      gpsLat: lat,
      gpsLng: lng,
      fraudFlags: const [],
    );
  }

  RaidEntity _getMockRaid(String zoneId, String deviceId, double lat, double lng) {
    return RaidEntity(
      id: '4d5d1c37-ef02-4bdf-87f5-d5cc9d35688c',
      userId: 'd3b07384-d113-4ec5-a55d-3d4c6d6c6e7f',
      zoneId: zoneId,
      startedAt: DateTime.now(),
      durationMins: 2,
      spendAmount: 0.0,
      pointsEarned: 0.0,
      earnRate: 1.0,
      isValid: false,
      deviceId: deviceId,
      gpsLat: lat,
      gpsLng: lng,
      fraudFlags: const [],
    );
  }
}
