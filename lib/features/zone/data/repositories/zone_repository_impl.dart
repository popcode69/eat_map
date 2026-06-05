import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/entities/zone_raider_entity.dart';
import '../../domain/repositories/zone_repository.dart';
import '../models/zone_model.dart';
import '../models/zone_raider_model.dart';

class ZoneRepositoryImpl implements ZoneRepository {
  final DioClient _dioClient;

  // Offline fallback mock zones (Jaipur area)
  final List<ZoneModel> _localMockZones = [
    ZoneModel(
      id: '27db225d-ef37-4d92-bf4f-561bcfc234a9',
      placeId: 'ChIJ531L2-v5zjsR1t119ff0856',
      name: 'The Burger Bastion',
      lat: 26.9626,
      lng: 75.7377,
      geohash: 'te7u6b',
      warlordId: 'd3b07384-d113-4ec5-a55d-3d4c6d6c6e7f',
      warlordUsername: 'BurgerKing99',
      // PNG (not SVG) so NetworkImage can decode it onto the marker.
      warlordAvatarUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=BurgerKing99',
      customTitle: 'Burger Warlord',
      customColour: '#E53935',
      customIcon: 'hamburger',
      totalRaids: 42,
      warlordRaids: 15,
      status: 'active',
      updatedAt: DateTime.now(),
    ),
    ZoneModel(
      id: 'b45c225d-ef37-4d92-bf4f-561bcfc234b2',
      placeId: 'ChIJ531L2-v5zjsR1t119ff0857',
      name: 'Sushi Slayer Dojo',
      lat: 26.9650,
      lng: 75.7410,
      geohash: 'te7u6b',
      warlordId: '8d7fcdbb-2b81-4202-a8c6-b37119ff0856',
      warlordUsername: 'SushiMaster',
      warlordAvatarUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=SushiMaster',
      customTitle: 'Wasabi Master',
      customColour: '#4CAF50',
      customIcon: 'fork',
      totalRaids: 18,
      warlordRaids: 10,
      status: 'active',
      updatedAt: DateTime.now(),
    ),
    ZoneModel(
      id: 'c89c225d-ef37-4d92-bf4f-561bcfc234c9',
      placeId: 'ChIJ531L2-v5zjsR1t119ff0858',
      name: 'Pizza Stronghold',
      lat: 26.9600,
      lng: 75.7350,
      geohash: 'te7u6b',
      customColour: '#FF9800',
      customIcon: 'pizza',
      totalRaids: 0,
      warlordRaids: 0,
      status: 'uncaptured',
      updatedAt: DateTime.now(),
    ),
    ZoneModel(
      id: 'd12e225d-ef37-4d92-bf4f-561bcfc234d1',
      placeId: 'ChIJ531L2-v5zjsR1t119ff0859',
      name: 'Dhaba 56',
      lat: 26.9580,
      lng: 75.7390,
      geohash: 'te7u6b',
      customColour: '#607D8B',
      customIcon: 'fork',
      totalRaids: 0,
      warlordRaids: 0,
      status: 'uncaptured',
      updatedAt: DateTime.now(),
    ),
    ZoneModel(
      id: 'e34f225d-ef37-4d92-bf4f-561bcfc234e2',
      placeId: 'ChIJ531L2-v5zjsR1t119ff0860',
      name: 'Café Royale',
      lat: 26.9670,
      lng: 75.7360,
      geohash: 'te7u6b',
      customColour: '#607D8B',
      customIcon: 'pizza',
      totalRaids: 0,
      warlordRaids: 0,
      status: 'uncaptured',
      updatedAt: DateTime.now(),
    ),
    ZoneModel(
      id: 'f56a225d-ef37-4d92-bf4f-561bcfc234f3',
      placeId: 'ChIJ531L2-v5zjsR1t119ff0861',
      name: 'Hotel Grand Bar',
      lat: 26.9640,
      lng: 75.7430,
      geohash: 'te7u6b',
      customColour: '#607D8B',
      customIcon: 'hamburger',
      totalRaids: 0,
      warlordRaids: 0,
      status: 'uncaptured',
      updatedAt: DateTime.now(),
    ),
    ZoneModel(
      id: 'a78b225d-ef37-4d92-bf4f-561bcfc234a4',
      placeId: 'ChIJ531L2-v5zjsR1t119ff0862',
      name: 'Spice Garden Restaurant',
      lat: 26.9610,
      lng: 75.7420,
      geohash: 'te7u6b',
      customColour: '#607D8B',
      customIcon: 'fork',
      totalRaids: 0,
      warlordRaids: 0,
      status: 'uncaptured',
      updatedAt: DateTime.now(),
    ),
    ZoneModel(
      id: 'b90c225d-ef37-4d92-bf4f-561bcfc234b5',
      placeId: 'ChIJ531L2-v5zjsR1t119ff0863',
      name: 'Midnight Bar & Grill',
      lat: 26.9655,
      lng: 75.7340,
      geohash: 'te7u6b',
      customColour: '#607D8B',
      customIcon: 'hamburger',
      totalRaids: 0,
      warlordRaids: 0,
      status: 'uncaptured',
      updatedAt: DateTime.now(),
    ),
  ];

  ZoneRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Either<Failure, List<ZoneEntity>>> getNearbyZones({
    required String geohash,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.nearbyZones,
        queryParameters: {'geohash': geohash},
      );
      final dataList = response.data as List;
      final zones = dataList
          .map((json) => ZoneModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(zones);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown ||
          e.response?.statusCode == 422) {
        return Right(_localMockZones);
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, ZoneEntity>> getZoneDetail({
    required String zoneId,
  }) async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.zoneDetail(zoneId));
      final zone = ZoneModel.fromJson(response.data as Map<String, dynamic>);
      return Right(zone);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        final mockZone = _localMockZones.firstWhere(
          (z) => z.id == zoneId,
          orElse: () => _localMockZones.first,
        );
        return Right(mockZone);
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, ZoneEntity>> customizeZone({
    required String zoneId,
    required String title,
    required String colour,
    required String icon,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'colour': colour,
        'icon': icon,
      });
      final response = await _dioClient.dio.patch(
        ApiEndpoints.customizeZone(zoneId),
        data: formData,
      );
      final zone = ZoneModel.fromJson(response.data as Map<String, dynamic>);
      return Right(zone);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        final index = _localMockZones.indexWhere((z) => z.id == zoneId);
        if (index != -1) {
          final old = _localMockZones[index];
          final updated = ZoneModel(
            id: old.id,
            placeId: old.placeId,
            name: old.name,
            lat: old.lat,
            lng: old.lng,
            geohash: old.geohash,
            warlordId: old.warlordId,
            customTitle: title,
            customColour: colour,
            customIcon: icon,
            totalRaids: old.totalRaids,
            warlordRaids: old.warlordRaids,
            status: old.status,
            updatedAt: DateTime.now(),
          );
          _localMockZones[index] = updated;
          return Right(updated);
        }
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, List<ZoneRaiderEntity>>> getZoneRaiders({
    required String zoneId,
  }) async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.zoneRaiders(zoneId));
      final dataList = response.data as List;
      final raiders = dataList
          .map((json) => ZoneRaiderModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(raiders);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        return Right(_mockRaidersFor(zoneId));
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  List<ZoneRaiderEntity> _mockRaidersFor(String zoneId) {
    final zone = _localMockZones.firstWhere(
      (z) => z.id == zoneId,
      orElse: () => _localMockZones.first,
    );
    final raiders = <ZoneRaiderEntity>[];
    if (zone.warlordId != null) {
      raiders.add(ZoneRaiderModel(
        userId: zone.warlordId!,
        username: zone.warlordUsername ?? 'Champion',
        avatarUrl: zone.warlordAvatarUrl,
        raidCount: zone.warlordRaids,
      ));
    }
    if (zone.totalRaids > zone.warlordRaids) {
      raiders.add(const ZoneRaiderModel(
        userId: 'mock-user-2',
        username: 'FoodExplorer',
        raidCount: 5,
      ));
      raiders.add(const ZoneRaiderModel(
        userId: 'mock-user-3',
        username: 'DineDrifter',
        raidCount: 3,
      ));
      raiders.add(const ZoneRaiderModel(
        userId: 'mock-user-4',
        username: 'GrillHunter',
        raidCount: 1,
      ));
    }
    return raiders;
  }

  void mockCaptureZone(String zoneId, String warlordId, String warlordUsername) {
    final index = _localMockZones.indexWhere((z) => z.id == zoneId);
    if (index != -1) {
      final old = _localMockZones[index];
      _localMockZones[index] = ZoneModel(
        id: old.id,
        placeId: old.placeId,
        name: old.name,
        lat: old.lat,
        lng: old.lng,
        geohash: old.geohash,
        warlordId: warlordId,
        warlordUsername: warlordUsername,
        customTitle: old.customTitle ?? 'Tactical Raider Stronghold',
        // Newly captured self-zones default to yellow (Task 3); the user can
        // recolour later via zone customization.
        customColour: '#FFD700',
        customIcon: old.customIcon,
        totalRaids: old.totalRaids + 1,
        warlordRaids: old.warlordRaids + 1,
        status: 'active',
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Fetch nearby food zones from the backend using real GPS coordinates.
  /// Falls back to local mock zones on any network error.
  Future<List<ZoneEntity>> getNearbyFoodPlaces({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.nearbyZones,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final dataList = response.data as List;
      return dataList
          .map((json) => ZoneModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown ||
          e.response?.statusCode == 422) {
        return List<ZoneEntity>.from(_localMockZones);
      }
      return List<ZoneEntity>.from(_localMockZones);
    } catch (_) {
      return List<ZoneEntity>.from(_localMockZones);
    }
  }
}
