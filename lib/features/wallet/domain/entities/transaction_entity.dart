import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final double amount;

  /// Ledger entry type. The `amount` is **mixed-unit**:
  ///   • point rows → `amount` is points:  zone_capture, raid_earn, passive_earn
  ///   • cash  rows → `amount` is ₹:       warlord_payout, weekly_prize,
  ///                                        withdrawal, bonus, referral, challenge
  /// Render points vs ₹ distinctly — never sum them together.
  final String type;
  final String status; // 'success' | 'pending' | 'failed'
  final String title;
  final DateTime createdAt;
  final String? upiId;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.title,
    required this.createdAt,
    this.upiId,
  });

  /// Types whose `amount` is denominated in points (not rupees).
  static const Set<String> pointTypes = {
    'zone_capture',
    'raid_earn',
    'passive_earn',
  };

  /// True when this row's `amount` is points, false when it's cash (₹).
  bool get isPoints => pointTypes.contains(type);

  @override
  List<Object?> get props => [id, amount, type, status, title, createdAt, upiId];
}
