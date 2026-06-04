import '../../domain/entities/zone_entity.dart';

class ZoneModel extends ZoneEntity {
  const ZoneModel({
    required super.id,
    required super.placeId,
    required super.name,
    required super.lat,
    required super.lng,
    required super.geohash,
    super.warlordId,
    super.warlordUsername,
    super.warlordAvatarUrl,
    super.customTitle,
    required super.customColour,
    required super.customIcon,
    required super.totalRaids,
    required super.warlordRaids,
    required super.status,
    required super.updatedAt,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    final placeId = (json['place_id'] as String?) ?? '';
    final backendId = (json['id'] as String?) ?? '';
    // The backend sometimes returns identical placeholder UUIDs for every zone
    // (e.g. "temp-zone-uuid-mock-pla"). place_id is the canonical Google Places
    // unique identifier and is always unique per venue, so prefer it as the
    // entity key. This prevents marker collisions on the map.
    final id = placeId.isNotEmpty ? placeId : backendId;
    return ZoneModel(
      id: id,
      placeId: id,
      name: (json['name'] as String?) ?? 'Unknown Place',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      geohash: (json['geohash'] as String?) ?? '',
      warlordId: json['warlord_id'] as String?,
      warlordUsername: json['warlord_username'] as String?,
      warlordAvatarUrl: json['warlord_avatar_url'] as String?,
      customTitle: json['custom_title'] as String?,
      customColour: (json['custom_colour'] as String?) ?? '#4CAF50',
      customIcon: (json['custom_icon'] as String?) ?? 'fork',
      totalRaids: (json['total_raids'] as num?)?.toInt() ?? 0,
      warlordRaids: (json['warlord_raids'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'uncaptured',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_id': placeId,
      'name': name,
      'lat': lat,
      'lng': lng,
      'geohash': geohash,
      'warlord_id': warlordId,
      'warlord_username': warlordUsername,
      'warlord_avatar_url': warlordAvatarUrl,
      'custom_title': customTitle,
      'custom_colour': customColour,
      'custom_icon': customIcon,
      'total_raids': totalRaids,
      'warlord_raids': warlordRaids,
      'status': status,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
