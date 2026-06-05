import '../../domain/entities/leaderboard_user_entity.dart';

class LeaderboardUserModel extends LeaderboardUserEntity {
  const LeaderboardUserModel({
    super.userId,
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
      userId: json['user_id'] as String?,
      rank: (json['rank'] as num).toInt(),
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      // backend sends 'points' (new) or 'total_points' (old mock)
      totalPoints: ((json['points'] ?? json['total_points']) as num?)?.toInt() ?? 0,
      // backend sends 'active_strongholds_count' (new) or 'warlord_count' (old mock)
      warlordCount: ((json['active_strongholds_count'] ?? json['warlord_count']) as num?)?.toInt() ?? 0,
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
