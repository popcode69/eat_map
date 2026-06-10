import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/warlord_estimate_entity.dart';
import '../bloc/payouts_bloc.dart';

/// "Your passive earnings this month" card, backed by
/// GET /payouts/warlord/estimate. Self-contained — creates and disposes its own
/// [PayoutsBloc], so callers just drop `const PassiveEarningsCard()` anywhere.
class PassiveEarningsCard extends StatelessWidget {
  const PassiveEarningsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PayoutsBloc>(
      create: (_) =>
          di.sl<PayoutsBloc>()..add(const WarlordEstimateRequested()),
      child: const _PassiveEarningsView(),
    );
  }
}

class _PassiveEarningsView extends StatelessWidget {
  const _PassiveEarningsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PayoutsBloc, PayoutsState>(
      builder: (context, state) {
        // Hide the card entirely on failure — it's a non-critical projection.
        if (state is PayoutsFailure) return const SizedBox.shrink();

        final bool isLoading = state is PayoutsLoading || state is PayoutsInitial;
        final WarlordEstimateEntity? estimate =
            state is WarlordEstimateLoaded ? state.estimate : null;

        // Nothing to show yet (no passive points this month) — keep it hidden
        // so warlords-only content doesn't clutter every wallet.
        if (estimate != null && estimate.myShares <= 0) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.10),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.military_tech_rounded,
                      color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PASSIVE EARNINGS THIS MONTH',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.getOnSurfaceMuted(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (estimate != null && estimate.period.isNotEmpty)
                    Text(
                      estimate.period,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.getOnSurfaceMuted(context),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading || estimate == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else ...[
                Text(
                  '≈ ₹${estimate.projectedInr.toStringAsFixed(2)}',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.gold,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Projected share of the ₹${estimate.pool.toStringAsFixed(0)} '
                  'Warlord pool. Estimate only — it changes as others raid.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.getOnSurfaceMuted(context),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _stat(context, 'Your points',
                        estimate.myShares.toStringAsFixed(0)),
                    const SizedBox(width: 12),
                    _stat(context, 'Total points',
                        estimate.totalShares.toStringAsFixed(0)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: AppColors.getOnSurfaceMuted(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
