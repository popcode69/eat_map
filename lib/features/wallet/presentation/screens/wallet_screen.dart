import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../payouts/presentation/widgets/passive_earnings_card.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(LoadWalletRequested());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _submitWithdrawal(double maxBalance, bool isOffline) {
    _triggerHaptic();
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot withdraw while offline 📡'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.parse(_amountController.text.trim());
      final upiId = _upiController.text.trim();

      if (amount > maxBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Insufficient wallet balance.'),
            backgroundColor: AppColors.errorLight,
          ),
        );
        return;
      }

      context.read<WalletBloc>().add(
            WithdrawFundsRequested(amount: amount, upiId: upiId),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connState = context.watch<ConnectivityCubit>().state;
    final bool isOffline = connState == ConnectivityState.offline;

    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WithdrawalSuccess) {
          HapticFeedback.vibrate();
          _amountController.clear();
          _upiController.clear();
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.getSurface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.getSuccess(context), width: 1.5),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.getSuccess(context), size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Success',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.getSuccess(context)),
                  ),
                ],
              ),
              content: Text(
                state.message,
                style: AppTypography.bodyLarge,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'DISMISS',
                    style: TextStyle(color: AppColors.getPrimary(context), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        } else if (state is WithdrawalFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorLight,
            ),
          );
        } else if (state is WalletError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorLight,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        appBar: AppBar(
          title: const Text(
            'WALLET & EARNINGS',
            style: TextStyle(
              fontFamily: AppTypography.headingFont,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state is WalletLoading && state is! WithdrawalInProgress) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.getPrimary(context)),
              );
            }

            double balance = 0.0;
            var transactions = <dynamic>[];

            if (state is WalletLoaded) {
              balance = state.balance;
              transactions = state.transactions;
            } else if (state is WithdrawalInProgress || state is WithdrawalSuccess || state is WithdrawalFailure) {
              // Retrieve from internal cached state or reload
              final bloc = context.read<WalletBloc>();
              balance = bloc.cachedBalance;
              transactions = bloc.cachedTransactions;
            }

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<WalletBloc>().add(LoadWalletRequested());
                },
                color: AppColors.getPrimary(context),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Cyberpunk-themed Balance Hero Card
                      _buildBalanceCard(balance),
                      const SizedBox(height: 24),

                      // 1b. Passive (Warlord) earnings projection
                      const PassiveEarningsCard(),

                      // 2. UPI Withdrawal Form
                      _buildWithdrawalForm(balance, state is WithdrawalInProgress, isOffline),
                      const SizedBox(height: 28),
  
                      // 3. Transactions Ledger title
                      Text(
                        'LEDGER HISTORY',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.getOnSurface(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
  
                      // 4. Transactions List
                      if (transactions.isEmpty)
                        _buildEmptyTransactions()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return _buildTransactionItem(tx);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getSuccess(context), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.getSuccess(context).withAlpha((255 * 0.08).toInt()),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AVAILABLE BALANCE',
                style: AppTypography.caption.copyWith(
                  color: AppColors.getOnSurfaceMuted(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.shield_outlined, color: AppColors.getSuccess(context), size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.getSuccess(context),
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.getSuccess(context).withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.getSuccess(context), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cash arrives on weekly & monthly settlements. Min withdrawal ₹100.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.getSuccess(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalForm(double balance, bool isInProgress, bool isOffline) {
    return Card(
      color: AppColors.getSurface(context),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPI WITHDRAWAL',
                style: AppTypography.titleLarge.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Amount Input Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                enabled: !isInProgress,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: TextStyle(color: AppColors.getOnSurfaceMuted(context)),
                  prefixIcon: Icon(Icons.currency_rupee, color: AppColors.getPrimary(context)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.getBorder(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.getPrimary(context), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount.';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number.';
                  }
                  if (amount < 100.0) {
                    return 'Minimum withdrawal is ₹100.';
                  }
                  if (amount > balance) {
                    return 'Insufficient balance.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // UPI ID Input Field
              TextFormField(
                controller: _upiController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isInProgress,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'UPI ID (e.g. user@upi)',
                  labelStyle: TextStyle(color: AppColors.getOnSurfaceMuted(context)),
                  prefixIcon: Icon(Icons.account_balance, color: AppColors.getPrimary(context)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.getBorder(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.getPrimary(context), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter UPI ID.';
                  }
                  if (!value.contains('@') || value.length < 3) {
                    return 'Please enter a valid UPI ID (must contain @).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // CTA Submit Button
              ElevatedButton(
                onPressed: isInProgress ? null : () => _submitWithdrawal(balance, isOffline),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(context),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.getBorder(context),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isInProgress
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isOffline ? 'OFFLINE — CANNOT WITHDRAW' : '⚡ WITHDRAW FUNDS',
                        style: const TextStyle(
                          fontFamily: AppTypography.headingFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Card(
      color: AppColors.getSurface(context),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 40, color: AppColors.getOnSurfaceMuted(context)),
              const SizedBox(height: 8),
              Text(
                'No transaction ledger entries.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.getOnSurfaceMuted(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Human-readable label for a ledger entry type.
  String _typeLabel(String type) {
    switch (type) {
      case 'zone_capture':
        return 'ZONE CAPTURE';
      case 'raid_earn':
        return 'RAID REWARD';
      case 'passive_earn':
        return 'PASSIVE (WARLORD)';
      case 'warlord_payout':
        return 'WARLORD PAYOUT';
      case 'weekly_prize':
        return 'WEEKLY PRIZE';
      default:
        return type.toUpperCase();
    }
  }

  Widget _buildTransactionItem(dynamic tx) {
    final bool isDebit = tx.type == 'withdrawal';
    // Point rows (zone_capture/raid_earn/passive_earn) carry points; everything
    // else carries ₹. They are rendered with distinct units and never summed.
    final bool isPoints = tx.isPoints as bool;
    final Color amountColor = isDebit
        ? AppColors.getError(context)
        : isPoints
            ? AppColors.getPrimary(context)
            : tx.type == 'bonus'
                ? AppColors.getWarning(context)
                : AppColors.getSuccess(context);

    final String sign = isDebit ? '-' : '+';
    final String amountString = isPoints
        ? '$sign${tx.amount.toStringAsFixed(0)} pts'
        : '$sign ₹${tx.amount.toStringAsFixed(0)}';
    final String dateString = DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _typeLabel(tx.type as String),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.getOnSurfaceMuted(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: AppColors.getBorder(context)),
                    const SizedBox(width: 8),
                    Text(
                      dateString,
                      style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                    ),
                  ],
                ),
                if (tx.upiId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'UPI: ${tx.upiId}',
                    style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountString,
            style: AppTypography.titleLarge.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
