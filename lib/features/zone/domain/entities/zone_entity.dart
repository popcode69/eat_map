import 'package:equatable/equatable.dart';

class ZoneEntity extends Equatable {
  final String id;
  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final String geohash;
  final String? warlordId;
  final String? warlordUsername;
  final String? warlordAvatarUrl;
  final String? customTitle;
  final String customColour;
  final String customIcon;
  final int totalRaids;
  final int warlordRaids;
  final String status;
  final DateTime updatedAt;

  const ZoneEntity({
    required this.id,
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.geohash,
    this.warlordId,
    this.warlordUsername,
    this.warlordAvatarUrl,
    this.customTitle,
    required this.customColour,
    required this.customIcon,
    required this.totalRaids,
    required this.warlordRaids,
    required this.status,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        placeId,
        name,
        lat,
        lng,
        geohash,
        warlordId,
        warlordUsername,
        warlordAvatarUrl,
        customTitle,
        customColour,
        customIcon,
        totalRaids,
        warlordRaids,
        status,
        updatedAt,
      ];
}
