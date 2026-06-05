import 'package:equatable/equatable.dart';

class LeaderboardUserEntity extends Equatable {
  final String? userId;
  final int rank;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int totalPoints;
  final int warlordCount;
  final String? squadName;

  const LeaderboardUserEntity({
    this.userId,
    required this.rank,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.totalPoints,
    required this.warlordCount,
    this.squadName,
  });

  @override
  List<Object?> get props => [
        userId,
        rank,
        username,
        displayName,
        avatarUrl,
        totalPoints,
        warlordCount,
        squadName,
      ];
}
