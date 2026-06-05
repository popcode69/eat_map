import 'package:equatable/equatable.dart';

class CapturedZoneEntity extends Equatable {
  final String zoneId;
  final String name;
  final String? customTitle;
  final String customColour;
  final String customIcon;
  final int warlordRaids;
  final int totalRaids;
  final String? city;

  const CapturedZoneEntity({
    required this.zoneId,
    required this.name,
    this.customTitle,
    required this.customColour,
    required this.customIcon,
    required this.warlordRaids,
    required this.totalRaids,
    this.city,
  });

  @override
  List<Object?> get props => [
        zoneId,
        name,
        customTitle,
        customColour,
        customIcon,
        warlordRaids,
        totalRaids,
        city,
      ];
}
