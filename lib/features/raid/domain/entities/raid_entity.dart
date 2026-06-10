import 'package:equatable/equatable.dart';

class RaidEntity extends Equatable {
  final String id;
  final String userId;
  final String zoneId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationMins;
  final String? verification;
  final double pointsEarned;
  // Always null under the flat points model — kept for backwards compatibility
  // with any persisted/cached payloads. Do not display it.
  final double? earnRate;
  final bool isValid;
  final String? deviceId;
  final double? gpsLat;
  final double? gpsLng;
  final List<String> fraudFlags;

  const RaidEntity({
    required this.id,
    required this.userId,
    required this.zoneId,
    required this.startedAt,
    this.completedAt,
    required this.durationMins,
    this.verification,
    required this.pointsEarned,
    this.earnRate,
    required this.isValid,
    this.deviceId,
    this.gpsLat,
    this.gpsLng,
    required this.fraudFlags,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        zoneId,
        startedAt,
        completedAt,
        durationMins,
        verification,
        pointsEarned,
        earnRate,
        isValid,
        deviceId,
        gpsLat,
        gpsLng,
        fraudFlags,
      ];
}
