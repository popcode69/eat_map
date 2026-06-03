import 'package:flutter/material.dart';

class AppColors {
  // ─────────────────────────────────────────────────────────────────
  // COMMON
  // ─────────────────────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Brand golds (used for warlord badges, my-zone markers)
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8960F);

  // Raid / Uncaptured greens
  static const Color raidGreen = Color(0xFF00E676);
  static const Color raidGreenDark = Color(0xFF00C853);

  // ─────────────────────────────────────────────────────────────────
  // LIGHT THEME TOKENS
  // ─────────────────────────────────────────────────────────────────
  static const Color primaryLight = Color(0xFFE53935);
  static const Color primaryDarkerLight = Color(0xFFB71C1C);
  static const Color primaryTintLight = Color(0xFFFFCDD2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF7F7F7);
  static const Color surfaceVariantLight = Color(0xFFF0F0F0);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1A1A1A);
  static const Color onSurfaceMutedLight = Color(0xFF757575);
  static const Color successLight = Color(0xFF2E7D32);
  static const Color warningLight = Color(0xFFF57F17);
  static const Color errorLight = Color(0xFFC62828);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Glass (light)
  static const Color glassLight = Color(0xCCFFFFFF); // 80% white
  static const Color glassBorderLight = Color(0x40FFFFFF);

  // Shadows (light)
  static const Color shadowLight = Color(0x1A000000); // 10%
  static const Color shadowMediumLight = Color(0x29000000); // 16%
  static const Color shadowHeavyLight = Color(0x40000000); // 25%

  // Shimmer (light)
  static const Color shimmerBaseLight = Color(0xFFEEEEEE);
  static const Color shimmerHighlightLight = Color(0xFFF5F5F5);

  // ─────────────────────────────────────────────────────────────────
  // DARK THEME TOKENS
  // ─────────────────────────────────────────────────────────────────
  static const Color primaryDark = Color(0xFFEF5350);
  static const Color primaryDarkerDark = Color(0xFFE53935);
  static const Color primaryTintDark = Color(0xFF4A1010);
  static const Color surfaceDark = Color(0xFF111111);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceVariantDark = Color(0xFF1C1C1C);
  static const Color onPrimaryDark = Color(0xFFFFFFFF);
  static const Color onSurfaceDark = Color(0xFFF5F5F5);
  static const Color onSurfaceMutedDark = Color(0xFF9E9E9E);
  static const Color successDark = Color(0xFF66BB6A);
  static const Color warningDark = Color(0xFFFFB300);
  static const Color errorDark = Color(0xFFEF5350);
  static const Color borderDark = Color(0xFF2A2A2A);

  // Glass (dark)
  static const Color glassDark = Color(0x99111111); // 60% dark
  static const Color glassBorderDark = Color(0x33FFFFFF);

  // Shadows (dark)
  static const Color shadowDark = Color(0x33000000);
  static const Color shadowMediumDark = Color(0x4D000000);
  static const Color shadowHeavyDark = Color(0x66000000);

  // Shimmer (dark)
  static const Color shimmerBaseDark = Color(0xFF1C1C1C);
  static const Color shimmerHighlightDark = Color(0xFF2A2A2A);

  // ─────────────────────────────────────────────────────────────────
  // GRADIENTS
  // ─────────────────────────────────────────────────────────────────

  static LinearGradient primaryGradient(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [primaryDark, const Color(0xFFFF7043)]
          : [primaryLight, const Color(0xFFFF5722)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient successGradient(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [const Color(0xFF66BB6A), const Color(0xFF26A69A)]
          : [const Color(0xFF2E7D32), const Color(0xFF00897B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient surfaceGradient(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [const Color(0xFF111111), const Color(0xFF1A1A2E)]
          : [const Color(0xFFFFFFFF), const Color(0xFFF5F5FA)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  // Map scrim gradients (transparent → surface)
  static LinearGradient mapTopScrim(BuildContext context) {
    final bg = getBackground(context);
    return LinearGradient(
      colors: [bg.withValues(alpha: 0.7), bg.withValues(alpha: 0.0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static LinearGradient mapBottomScrim(BuildContext context) {
    final bg = getBackground(context);
    return LinearGradient(
      colors: [bg.withValues(alpha: 0.0), bg.withValues(alpha: 0.7)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  // Medal colours
  static const Color medalGold = Color(0xFFFFD700);
  static const Color medalSilver = Color(0xFFC0C0C0);
  static const Color medalBronze = Color(0xFFCD7F32);

  // ─────────────────────────────────────────────────────────────────
  // THEME-AWARE HELPERS
  // ─────────────────────────────────────────────────────────────────

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getPrimary(BuildContext context) =>
      _isDark(context) ? primaryDark : primaryLight;

  // Kept for backward-compat: old callers used getPrimaryDark / getPrimaryLight
  static Color getPrimaryDark(BuildContext context) =>
      _isDark(context) ? primaryDarkerDark : primaryDarkerLight;

  static Color getPrimaryLight(BuildContext context) =>
      _isDark(context) ? primaryTintDark : primaryTintLight;

  static Color getSurface(BuildContext context) =>
      _isDark(context) ? surfaceDark : surfaceLight;

  static Color getBackground(BuildContext context) =>
      _isDark(context) ? backgroundDark : backgroundLight;

  static Color getSurfaceVariant(BuildContext context) =>
      _isDark(context) ? surfaceVariantDark : surfaceVariantLight;

  static Color getOnPrimary(BuildContext context) =>
      _isDark(context) ? onPrimaryDark : onPrimaryLight;

  static Color getOnSurface(BuildContext context) =>
      _isDark(context) ? onSurfaceDark : onSurfaceLight;

  static Color getOnSurfaceMuted(BuildContext context) =>
      _isDark(context) ? onSurfaceMutedDark : onSurfaceMutedLight;

  static Color getSuccess(BuildContext context) =>
      _isDark(context) ? successDark : successLight;

  static Color getWarning(BuildContext context) =>
      _isDark(context) ? warningDark : warningLight;

  static Color getError(BuildContext context) =>
      _isDark(context) ? errorDark : errorLight;

  static Color getBorder(BuildContext context) =>
      _isDark(context) ? borderDark : borderLight;

  static Color getGlass(BuildContext context) =>
      _isDark(context) ? glassDark : glassLight;

  static Color getGlassBorder(BuildContext context) =>
      _isDark(context) ? glassBorderDark : glassBorderLight;

  static Color getShadow(BuildContext context) =>
      _isDark(context) ? shadowDark : shadowLight;

  static Color getShadowMedium(BuildContext context) =>
      _isDark(context) ? shadowMediumDark : shadowMediumLight;

  static Color getShimmerBase(BuildContext context) =>
      _isDark(context) ? shimmerBaseDark : shimmerBaseLight;

  static Color getShimmerHighlight(BuildContext context) =>
      _isDark(context) ? shimmerHighlightDark : shimmerHighlightLight;
}
