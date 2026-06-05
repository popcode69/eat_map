import '../../domain/entities/user_profile_entity.dart';
import 'captured_zone_model.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.userId,
    required super.username,
    super.displayName,
    super.avatarUrl,
    super.city,
    required super.level,
    required super.totalPoints,
    required super.trustScore,
    required super.warlordCount,
    required super.totalRaids,
    required super.validRaids,
    required super.capturedZones,
  });

  /// Parses the response from GET /users/{userId}:
  /// { "user": {...}, "stats": {...}, "strongholds": [...] }
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? {};
    final stats = (json['stats'] as Map<String, dynamic>?) ?? {};
    final strongholdsJson = (json['strongholds'] as List?) ?? [];

    final zones = strongholdsJson
        .map((z) => CapturedZoneModel.fromJson(z as Map<String, dynamic>))
        .toList();

    return UserProfileModel(
      userId: (user['id'] as String?) ?? '',
      username: (user['username'] as String?) ?? 'unknown',
      displayName: user['display_name'] as String?,
      avatarUrl: user['avatar_url'] as String?,
      city: user['city'] as String?,
      // Prefer stats fields (more up-to-date) but fall back to user fields.
      level: (stats['level'] as num?)?.toInt() ??
          (user['level'] as num?)?.toInt() ?? 1,
      totalPoints: (stats['total_points'] as num?)?.toInt() ??
          (user['total_points'] as num?)?.toInt() ?? 0,
      trustScore: (stats['trust_score'] as num?)?.toInt() ??
          (user['trust_score'] as num?)?.toInt() ?? 100,
      warlordCount: (stats['strongholds_owned'] as num?)?.toInt() ?? 0,
      totalRaids: (stats['total_raids'] as num?)?.toInt() ?? 0,
      validRaids: (stats['valid_raids'] as num?)?.toInt() ?? 0,
      capturedZones: zones,
    );
  }
}
