import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A single tappable row inside [AppModals.actionSheet].
class AppSheetAction<T> {
  final T value;
  final IconData icon;
  final String label;
  final String? subtitle;

  /// When true the row is tinted with the error colour (e.g. "Sign out").
  final bool destructive;

  const AppSheetAction({
    required this.value,
    required this.icon,
    required this.label,
    this.subtitle,
    this.destructive = false,
  });
}

/// Centralized, theme-aware dialogs & bottom sheets for EatMap.
///
/// Everything here respects [AppColors] / [AppTypography] and the light/dark
/// theme, so feature code never hand-rolls `AlertDialog`s or sheet chrome.
class AppModals {
  AppModals._();

  // ───────────────────────────────────────────────────────────────────
  // CONFIRMATION DIALOG
  // ───────────────────────────────────────────────────────────────────

  /// Branded yes/no confirmation. Returns `true` only if confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    bool destructive = false,
  }) async {
    HapticFeedback.lightImpact();
    final accent =
        destructive ? AppColors.getError(context) : AppColors.getPrimary(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogShell(
        icon: icon,
        accent: accent,
        title: title,
        message: message,
        actions: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                side: BorderSide(color: AppColors.getBorder(ctx)),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(cancelLabel,
                  style: TextStyle(color: AppColors.getOnSurface(ctx))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 48),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(confirmLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ───────────────────────────────────────────────────────────────────
  // INFO / ERROR DIALOG
  // ───────────────────────────────────────────────────────────────────

  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Got it',
    IconData icon = Icons.info_outline_rounded,
    bool isError = false,
  }) {
    final accent =
        isError ? AppColors.getError(context) : AppColors.getPrimary(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) => _DialogShell(
        icon: isError ? Icons.error_outline_rounded : icon,
        accent: accent,
        title: title,
        message: message,
        actions: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 48),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // RAID RESULT DIALOG (celebratory)
  // ───────────────────────────────────────────────────────────────────

  /// Shown after a successful raid verification. Highlights points earned and
  /// whether the user just became the Warlord of the zone.
  static Future<void> raidResult(
    BuildContext context, {
    required double points,
    int? rank,
    bool isWarlord = false,
    String? zoneName,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Raid result',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Transform.scale(
          scale: curved.value,
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: _RaidResultCard(
              points: points,
              rank: rank,
              isWarlord: isWarlord,
              zoneName: zoneName,
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // ACTION BOTTOM SHEET
  // ───────────────────────────────────────────────────────────────────

  /// A branded bottom sheet of tappable actions. Returns the selected value,
  /// or `null` if dismissed.
  static Future<T?> actionSheet<T>(
    BuildContext context, {
    String? title,
    String? subtitle,
    required List<AppSheetAction<T>> actions,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => sheetShell(
        ctx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: AppTypography.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.getOnSurfaceMuted(ctx))),
              ],
              const SizedBox(height: 16),
            ],
            ...actions.map((a) {
              final color = a.destructive
                  ? AppColors.getError(ctx)
                  : AppColors.getOnSurface(ctx);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(ctx, a.value);
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (a.destructive
                            ? AppColors.getError(ctx)
                            : AppColors.getPrimary(ctx))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(a.icon,
                      color: a.destructive
                          ? AppColors.getError(ctx)
                          : AppColors.getPrimary(ctx),
                      size: 22),
                ),
                title: Text(a.label,
                    style: AppTypography.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600, color: color)),
                subtitle: a.subtitle == null
                    ? null
                    : Text(a.subtitle!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.getOnSurfaceMuted(ctx))),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: AppColors.getOnSurfaceMuted(ctx)),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // SHEET SHELL (reusable chrome for any custom bottom sheet)
  // ───────────────────────────────────────────────────────────────────

  /// Wraps [child] in the standard EatMap bottom-sheet chrome: rounded top,
  /// drag handle, safe-area padding. Use this for any custom sheet content.
  static Widget sheetShell(BuildContext context, {required Widget child}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border:
            Border(top: BorderSide(color: AppColors.getBorder(context), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.getBorder(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PRIVATE — shared dialog chrome
// ─────────────────────────────────────────────────────────────────────

class _DialogShell extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final List<Widget> actions;

  const _DialogShell({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.getSurface(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.getBorder(context), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 32),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.getOnSurfaceMuted(context))),
            const SizedBox(height: 24),
            Row(children: actions),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PRIVATE — raid result card
// ─────────────────────────────────────────────────────────────────────

class _RaidResultCard extends StatelessWidget {
  final double points;
  final int? rank;
  final bool isWarlord;
  final String? zoneName;

  const _RaidResultCard({
    required this.points,
    this.rank,
    this.isWarlord = false,
    this.zoneName,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent =
        isWarlord ? AppColors.gold : AppColors.getSuccess(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: isWarlord
                        ? AppColors.goldGradient
                        : AppColors.successGradient(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWarlord ? Icons.military_tech_rounded : Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isWarlord ? 'STRONGHOLD CONQUERED! 👑' : 'RAID VERIFIED! ⚔️',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(color: accent),
                ),
                if (zoneName != null) ...[
                  const SizedBox(height: 4),
                  Text(zoneName!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.getOnSurfaceMuted(context))),
                ],
                const SizedBox(height: 20),
                // Points earned
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '+${points.toStringAsFixed(0)}',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.getOnSurface(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' PTS',
                      style: AppTypography.titleMedium
                          .copyWith(color: AppColors.getOnSurfaceMuted(context)),
                    ),
                  ]),
                ),
                if (rank != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Now ranked #$rank in this zone',
                        style: AppTypography.labelMedium.copyWith(color: accent)),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CLAIM REWARD',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
