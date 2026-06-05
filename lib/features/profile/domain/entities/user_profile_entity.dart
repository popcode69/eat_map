import 'package:equatable/equatable.dart';
import 'captured_zone_entity.dart';

class UserProfileEntity extends Equatable {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? city;
  final int level;
  final int totalPoints;
  final int trustScore;
  final int warlordCount;
  final int totalRaids;
  final int validRaids;
  final List<CapturedZoneEntity> capturedZones;

  const UserProfileEntity({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.city,
    required this.level,
    required this.totalPoints,
    required this.trustScore,
    required this.warlordCount,
    required this.totalRaids,
    required this.validRaids,
    required this.capturedZones,
  });

  String get displayLabel => displayName ?? username;

  String get levelTitle {
    if (level >= 21) return 'Food Legend';
    if (level >= 11) return 'Zone Warlord';
    if (level >= 6) return 'Raid Commander';
    return 'Food Scout';
  }

  /// XP needed to advance one full level (simplified linear scale).
  int get pointsForNextLevel => (level + 1) * 500;

  /// XP accumulated within the current level.
  int get pointsInCurrentLevel => totalPoints % pointsForNextLevel;

  double get levelProgress =>
      (pointsInCurrentLevel / pointsForNextLevel).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [
        userId,
        username,
        displayName,
        avatarUrl,
        city,
        level,
        totalPoints,
        trustScore,
        warlordCount,
        totalRaids,
        validRaids,
        capturedZones,
      ];
}
