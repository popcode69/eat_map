import 'package:equatable/equatable.dart';

class RaidEntity extends Equatable {
  final String id;
  final String userId;
  final String zoneId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationMins;
  final double spendAmount;
  final String? verification;
  final double pointsEarned;
  final double earnRate;
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
    required this.spendAmount,
    this.verification,
    required this.pointsEarned,
    required this.earnRate,
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
        spendAmount,
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
