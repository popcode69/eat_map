import '../../domain/entities/warlord_estimate_entity.dart';

class WarlordEstimateModel extends WarlordEstimateEntity {
  const WarlordEstimateModel({
    required super.period,
    required super.myShares,
    required super.totalShares,
    required super.pool,
    required super.projectedInr,
  });

  factory WarlordEstimateModel.fromJson(Map<String, dynamic> json) {
    return WarlordEstimateModel(
      period: json['period'] as String? ?? '',
      myShares: (json['my_shares'] as num?)?.toDouble() ?? 0.0,
      totalShares: (json['total_shares'] as num?)?.toDouble() ?? 0.0,
      pool: (json['pool'] as num?)?.toDouble() ?? 0.0,
      projectedInr: (json['projected_inr'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
