import '../../domain/entities/captured_zone_entity.dart';

class CapturedZoneModel extends CapturedZoneEntity {
  const CapturedZoneModel({
    required super.zoneId,
    required super.name,
    super.customTitle,
    required super.customColour,
    required super.customIcon,
    required super.warlordRaids,
    required super.totalRaids,
    super.city,
  });

  factory CapturedZoneModel.fromJson(Map<String, dynamic> json) {
    return CapturedZoneModel(
      zoneId: (json['zone_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Unknown Place',
      customTitle: json['custom_title'] as String?,
      customColour: (json['custom_colour'] as String?) ?? '#4CAF50',
      customIcon: (json['custom_icon'] as String?) ?? 'fork',
      warlordRaids: (json['warlord_raids'] as num?)?.toInt() ?? 0,
      totalRaids: (json['total_raids'] as num?)?.toInt() ?? 0,
      city: json['city'] as String?,
    );
  }
}
