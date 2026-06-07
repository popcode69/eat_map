import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Immutable data for the shareable status card so it can be rendered
/// off-screen for image capture as well as on-screen for preview.
class StatusCardData {
  final String displayName;
  final String username;
  final String? avatarUrl;
  final int level;
  final String levelTitle;
  final int totalPoints;
  final int trustScore;
  final String? city;

  /// Optional richer stats — only rendered when non-null.
  final int? strongholds;
  final int? totalRaids;

  const StatusCardData({
    required this.displayName,
    required this.username,
    this.avatarUrl,
    required this.level,
    required this.levelTitle,
    required this.totalPoints,
    required this.trustScore,
    this.city,
    this.strongholds,
    this.totalRaids,
  });

  bool get _hasZones => (strongholds ?? 0) > 0;

  /// Big taunting headline driven by the real conquered count.
  String get challengeHeadline {
    if (_hasZones) {
      return 'I CONQUERED $strongholds FOOD ${strongholds == 1 ? 'ZONE' : 'ZONES'}';
    }
    return 'I\'M ON THE FOOD RAID';
  }

  /// Supporting dare under the headline.
  String get challengeSub {
    if (_hasZones) return 'Can you take my turf? 👑';
    return 'Can you outrank me? 🔥';
  }

  /// Caption used when sharing to a story / chat.
  String get shareCaption {
    final what = _hasZones
        ? 'I\'ve conquered $strongholds ${strongholds == 1 ? 'restaurant' : 'restaurants'} on EatMap 🏴'
        : 'I\'m raiding restaurants on EatMap 🍴';
    return '$what  Think you can take my turf? Download: ${ShareableStatusCard.downloadUrl}';
  }
}

/// A vertical 9:16 story-format card showcasing a raider's stats, designed
/// to be captured as a PNG and shared to social stories. Promotes the app
/// with a prominent download call-to-action footer.
class ShareableStatusCard extends StatelessWidget {
  final StatusCardData data;

  /// Download URL shown in the footer CTA.
  static const String downloadUrl = 'eatmap.app';

  const ShareableStatusCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Lock text scaling so the captured card lays out identically on every
    // device regardless of the user's system font-size setting (this also
    // prevents layout overflow from large accessibility font scales).
    return MediaQuery.withNoTextScaling(
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    // Fixed logical size — story ratio (9:16). Captured at high pixelRatio.
    return Container(
      width: 360,
      height: 640,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0202),
            Color(0xFF3D0A0A),
            Color(0xFF12100C),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative glow blobs
          Positioned(
            top: -60,
            right: -50,
            child: _glow(AppColors.primaryLight.withAlpha(90), 200),
          ),
          Positioned(
            bottom: 40,
            left: -70,
            child: _glow(AppColors.gold.withAlpha(60), 220),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildBrandHeader(),
                const SizedBox(height: 22),
                _buildAvatar(),
                const SizedBox(height: 14),
                _buildIdentity(),
                const SizedBox(height: 10),
                _buildLevelChip(),
                const SizedBox(height: 16),
                _buildChallengeBanner(),
                const SizedBox(height: 16),
                _buildStats(),
                const Spacer(),
                _buildDownloadCta(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Brand header ──────────────────────────────────────────────────

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'EatMap',
              style: AppTypography.displayLarge.copyWith(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'RAID · DINE · CONQUER',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  // ── Avatar with gold frame + level badge ──────────────────────────

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.gold, Color(0xFFB8860B)],
            ),
            boxShadow: [
              BoxShadow(color: AppColors.gold.withAlpha(120), blurRadius: 24),
            ],
          ),
        ),
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF2A0808),
          ),
          child: ClipOval(
            child: data.avatarUrl != null
                ? Image.network(
                    data.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarInitial(),
                  )
                : _avatarInitial(),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              'LV ${data.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarInitial() {
    final letter =
        (data.displayName.isNotEmpty ? data.displayName[0] : '?').toUpperCase();
    return Container(
      color: AppColors.primaryDarkerLight,
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontFamily: AppTypography.headingFont,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 40,
          ),
        ),
      ),
    );
  }

  // ── Identity ──────────────────────────────────────────────────────

  Widget _buildIdentity() {
    return Column(
      children: [
        Text(
          data.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.displayLarge.copyWith(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '@${data.username}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLevelChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech, color: AppColors.gold, size: 15),
          const SizedBox(width: 6),
          Text(
            data.levelTitle.toUpperCase(),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Challenge banner ──────────────────────────────────────────────

  Widget _buildChallengeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withAlpha(36),
            AppColors.primaryLight.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withAlpha(110), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            data.challengeHeadline,
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 18,
              height: 1.15,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.challengeSub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────

  Widget _buildStats() {
    final tiles = <Widget>[
      _statTile(Icons.stars_rounded, _fmt(data.totalPoints), 'POINTS'),
      _statTile(
          Icons.verified_user_rounded, '${data.trustScore}%', 'TRUST'),
    ];
    if (data.strongholds != null) {
      tiles.add(_statTile(
          Icons.emoji_events_rounded, '${data.strongholds}', 'ZONES'));
    } else if (data.totalRaids != null) {
      tiles.add(_statTile(
          Icons.restaurant_rounded, '${data.totalRaids}', 'RAIDS'));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tiles,
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(30), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Download CTA footer ───────────────────────────────────────────

  Widget _buildDownloadCta() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, Color(0xFFB71C1C)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primaryLight.withAlpha(110), blurRadius: 18),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.file_download_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Steal my zones 🏴',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Download EatMap · $downloadUrl',
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Capture real restaurants. Become the Warlord.',
          style: TextStyle(color: Colors.white38, fontSize: 9.5),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
      ),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
