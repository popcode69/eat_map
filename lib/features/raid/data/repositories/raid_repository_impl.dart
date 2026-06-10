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
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        return Right(_getMockRaid(zoneId, deviceId, lat, lng));
      }
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        final nested = body['error'];
        final detail = body['detail'];
        String? msg;
        if (nested is Map<String, dynamic>) {
          msg = nested['message']?.toString();
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map<String, dynamic>) {
            final field = (first['loc'] as List?)?.last?.toString() ?? '';
            final reason = first['msg']?.toString() ?? '';
            msg = field.isNotEmpty ? '$field: $reason' : reason;
          }
        } else if (detail is String) {
          msg = detail;
        }
        if (msg != null && msg.isNotEmpty) {
          return Left(DomainFailure(msg));
        }
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyRaid({
    required String raidId,
    String? photoPath,
  }) async {
    try {
      // Presence-only verification. Backend expects multipart/form-data with a
      // single optional `photo` field (presence proof — not required). There is
      // no bill/spend/UPI flow anymore; validity is decided server-side from the
      // dwell time (>= MIN_RAID_MINUTES).
      final formMap = <String, dynamic>{};
      if (photoPath != null && photoPath.isNotEmpty) {
        final file = File(photoPath);
        if (await file.exists()) {
          formMap['photo'] = await MultipartFile.fromFile(
            file.path,
            filename: file.path.split(Platform.pathSeparator).last,
          );
        }
      }

      final response = await _dioClient.dio.post(
        ApiEndpoints.verifyRaid(raidId),
        data: FormData.fromMap(formMap),
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // No network → return mock success so dev flow completes.
      // Flat points: 100 (first capture) / 50 (raid on captured zone).
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        return const Right({
          'points_earned': 100,
          'earn_rate': null,
          'time_spent_mins': 5,
          'rank_at_zone': 1,
          'is_warlord': true,
          'message': 'Stronghold captured!',
        });
      }

      // Surface the backend's own error message. Two known formats:
      //   { "error": { "code": "...", "message": "..." } }
      //   { "detail": [ { "msg": "...", "loc": [...] } ] }  ← Pydantic validation
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        final nested = body['error'];
        final detail = body['detail'];
        String? msg;
        if (nested is Map<String, dynamic>) {
          msg = nested['message']?.toString();
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map<String, dynamic>) {
            final field = (first['loc'] as List?)?.last?.toString() ?? '';
            final reason = first['msg']?.toString() ?? '';
            msg = field.isNotEmpty ? '$field: $reason' : reason;
          }
        } else if (detail is String) {
          msg = detail;
        }
        if (msg != null && msg.isNotEmpty) {
          return Left(DomainFailure(msg));
        }
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
      durationMins: (json['duration_mins'] as num?)?.toInt() ?? 5,
      pointsEarned: 0.0,
      earnRate: null,
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
      durationMins: 5,
      pointsEarned: 0.0,
      earnRate: null,
      isValid: false,
      deviceId: deviceId,
      gpsLat: lat,
      gpsLng: lng,
      fraudFlags: const [],
    );
  }
}
