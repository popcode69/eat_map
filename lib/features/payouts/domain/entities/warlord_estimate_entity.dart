import 'package:equatable/equatable.dart';

/// Live projection of the cash a Warlord would receive if the monthly pool
/// settled right now. Read-only — never represents an actual payout.
class WarlordEstimateEntity extends Equatable {
  /// Settlement period, e.g. "2026-06".
  final String period;

  /// My passive points so far this month.
  final double myShares;

  /// Everyone's passive points this month.
  final double totalShares;

  /// Total ₹ pool.
  final double pool;

  /// Estimated ₹ = pool × myShares / totalShares. Changes as others raid.
  final double projectedInr;

  const WarlordEstimateEntity({
    required this.period,
    required this.myShares,
    required this.totalShares,
    required this.pool,
    required this.projectedInr,
  });

  @override
  List<Object?> get props => [period, myShares, totalShares, pool, projectedInr];
}
