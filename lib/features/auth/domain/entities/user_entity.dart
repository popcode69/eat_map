import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String supabaseUid;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? city;
  final int trustScore;
  final int level;
  final int totalPoints;
  final double walletBalance;
  final String? deviceId;
  final int accountAge;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.supabaseUid,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.city,
    required this.trustScore,
    required this.level,
    required this.totalPoints,
    required this.walletBalance,
    this.deviceId,
    required this.accountAge,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        supabaseUid,
        username,
        displayName,
        avatarUrl,
        city,
        trustScore,
        level,
        totalPoints,
        walletBalance,
        deviceId,
        accountAge,
        createdAt,
      ];
}
