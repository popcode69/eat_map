import '../../domain/entities/zone_raider_entity.dart';

class ZoneRaiderModel extends ZoneRaiderEntity {
  const ZoneRaiderModel({
    required super.userId,
    required super.username,
    super.displayName,
    super.avatarUrl,
    required super.raidCount,
    super.validRaidCount,
    super.isStronghold,
  });

  factory ZoneRaiderModel.fromJson(Map<String, dynamic> json) {
    return ZoneRaiderModel(
      userId: (json['user_id'] as String?) ?? '',
      username: (json['username'] as String?) ?? 'Unknown',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      raidCount: (json['raid_count'] as num?)?.toInt() ?? 0,
      validRaidCount: (json['valid_raid_count'] as num?)?.toInt() ?? 0,
      isStronghold: (json['is_stronghold'] as bool?) ?? false,
    );
  }
}
