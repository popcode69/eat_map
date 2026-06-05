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
    super.category,
    super.rating,
    super.userRatingsTotal,
    super.priceLevel,
    super.photoUrl,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    final backendId = (json['id'] as String?) ?? '';
    final placeId = (json['place_id'] as String?) ?? '';
    // The backend's `id` field is now the Google Places ID used in API URLs
    // (e.g. "ChIJTZ9GZeG1bTkRjwWOpO2l29Q"). Prefer it as canonical so that
    // calls like GET /zones/{id}/raiders hit the correct endpoint. Fall back
    // to place_id only when id is absent.
    final id = backendId.isNotEmpty ? backendId : placeId;

    return ZoneModel(
      id: id,
      placeId: placeId.isNotEmpty ? placeId : id,
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
      category: json['category'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: (json['user_ratings_total'] as num?)?.toInt(),
      priceLevel: (json['price_level'] as num?)?.toInt(),
      photoUrl: json['photo_url'] as String?,
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
      'category': category,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'price_level': priceLevel,
      'photo_url': photoUrl,
    };
  }
}
