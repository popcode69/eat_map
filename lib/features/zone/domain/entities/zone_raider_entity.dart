import 'package:equatable/equatable.dart';

class ZoneRaiderEntity extends Equatable {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int raidCount;
  final int validRaidCount;
  final bool isStronghold;

  const ZoneRaiderEntity({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.raidCount,
    this.validRaidCount = 0,
    this.isStronghold = false,
  });

  String get displayLabel => displayName ?? username;

  @override
  List<Object?> get props => [
        userId,
        username,
        displayName,
        avatarUrl,
        raidCount,
        validRaidCount,
        isStronghold,
      ];
}
