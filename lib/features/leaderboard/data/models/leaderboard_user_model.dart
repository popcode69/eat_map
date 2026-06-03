import '../../domain/entities/leaderboard_user_entity.dart';

class LeaderboardUserModel extends LeaderboardUserEntity {
  const LeaderboardUserModel({
    required super.rank,
    required super.username,
    super.displayName,
    super.avatarUrl,
    required super.totalPoints,
    required super.warlordCount,
    super.squadName,
  });

  factory LeaderboardUserModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardUserModel(
      rank: json['rank'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      totalPoints: json['total_points'] as int,
      warlordCount: json['warlord_count'] as int,
      squadName: json['squad_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'total_points': totalPoints,
      'warlord_count': warlordCount,
      'squad_name': squadName,
    };
  }
}
