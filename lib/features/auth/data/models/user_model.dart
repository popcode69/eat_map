import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.supabaseUid,
    required super.username,
    super.displayName,
    super.avatarUrl,
    super.city,
    required super.trustScore,
    required super.level,
    required super.totalPoints,
    required super.walletBalance,
    super.deviceId,
    required super.accountAge,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      supabaseUid: (json['supabase_uid'] as String?) ?? '',
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      trustScore: (json['trust_score'] as num?)?.toInt() ?? 100,
      level: (json['level'] as num?)?.toInt() ?? 1,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      deviceId: json['device_id'] as String?,
      accountAge: (json['account_age'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supabase_uid': supabaseUid,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'city': city,
      'trust_score': trustScore,
      'level': level,
      'total_points': totalPoints,
      'wallet_balance': walletBalance,
      'device_id': deviceId,
      'account_age': accountAge,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
