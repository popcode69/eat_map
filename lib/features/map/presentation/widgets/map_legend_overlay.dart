import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Full-screen legend overlay shown once on first map visit.
/// Re-openable from Profile → "How it works".
///
/// Dismisses via the CTA button; calling code persists the seen flag.
class MapLegendOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const MapLegendOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(200),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight, width: 1.5),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      const Icon(Icons.map_rounded,
                          color: AppColors.primaryLight, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'How It Works',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'EatMap is a real-world food raiding game. Visit restaurants, claim zones, and become the Warlord.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onSurfaceMutedLight,
                    ),
                  ),
                  const Divider(height: 28, color: AppColors.borderLight),

                  // ── Map pins ────────────────────────────────────
                  _sectionTitle('Map Pins'),
                  const SizedBox(height: 12),
                  _pinRow(
                    color: AppColors.raidGreen,
                    label: 'Uncaptured',
                    description: 'No one owns this spot yet — be first!',
                  ),
                  const SizedBox(height: 10),
                  _pinRow(
                    color: AppColors.gold,
                    label: 'Your zone',
                    description: 'You are the current Warlord here.',
                  ),
                  const SizedBox(height: 10),
                  _pinRow(
                    color: AppColors.primaryLight,
                    label: 'Enemy zone',
                    description: 'Owned by another raider — raid to claim it.',
                  ),
                  const Divider(height: 28, color: AppColors.borderLight),

                  // ── Raid radius ─────────────────────────────────
                  _sectionTitle('Raid Radius'),
                  const SizedBox(height: 10),
                  _infoRow(
                    icon: Icons.radar_rounded,
                    color: AppColors.primaryLight,
                    text:
                        'You must be within 50 metres of a restaurant to start a raid. Walk there for real!',
                  ),
                  const SizedBox(height: 28),

                  // ── How to raid ─────────────────────────────────
                  _sectionTitle('How to Raid'),
                  const SizedBox(height: 12),
                  _step('1', 'Walk to a restaurant shown on the map.'),
                  const SizedBox(height: 8),
                  _step('2', 'Tap the pin → "Tap a pin to raid."'),
                  const SizedBox(height: 8),
                  _step('3', 'Dine for the required time (5 min minimum).'),
                  const SizedBox(height: 8),
                  _step('4',
                      'Upload your bill or UPI screenshot to verify. Earn points & claim the zone!'),
                  const SizedBox(height: 28),

                  // ── CTA ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "LET'S RAID!",
                        style: TextStyle(
                          fontFamily: AppTypography.headingFont,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: AppColors.onSurfaceMutedLight,
      ),
    );
  }

  Widget _pinRow({
    required Color color,
    required String label,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coloured dot simulating a map pin
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                description,
                style: AppTypography.caption
                    .copyWith(color: AppColors.onSurfaceMutedLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyLarge.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _step(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyLarge.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
