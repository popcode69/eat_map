import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/captured_zone_entity.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../bloc/user_profile_bloc.dart';
import '../bloc/user_profile_event.dart';
import '../bloc/user_profile_state.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  /// Optional pre-filled display name shown while the API loads.
  final String? previewName;
  final String? previewAvatarUrl;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.previewName,
    this.previewAvatarUrl,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserProfileBloc>().add(LoadUserProfile(widget.userId));
  }

  // ── Level-based visuals ─────────────────────────────────────────

  Color _frameColor(int level) {
    if (level >= 21) return AppColors.gold;
    if (level >= 11) return const Color(0xFF9C27B0);
    if (level >= 6) return const Color(0xFF2196F3);
    return AppColors.raidGreen;
  }

  Color _parseColour(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primaryLight;
    }
  }

  IconData _iconFor(String slug) {
    switch (slug) {
      case 'hamburger':
        return Icons.restaurant;
      case 'pizza':
        return Icons.local_pizza;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.lunch_dining;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          return switch (state) {
            UserProfileLoading() => _buildLoading(),
            UserProfileLoaded(:final profile) => _buildProfile(profile),
            UserProfileError(:final message) => _buildError(message),
            UserProfileInitial() => _buildLoading(),
          };
        },
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          backgroundColor: AppColors.primaryLight,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primaryDarkerLight],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        iconTheme: const IconThemeData(color: AppColors.onSurfaceLight),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.onSurfaceMutedLight),
            const SizedBox(height: 12),
            Text('Could not load profile',
                style: AppTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message,
                style: AppTypography.caption
                    .copyWith(color: AppColors.onSurfaceMutedLight),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context
                  .read<UserProfileBloc>()
                  .add(LoadUserProfile(widget.userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Full profile ──────────────────────────────────────────────

  Widget _buildProfile(UserProfileEntity profile) {
    final frameColor = _frameColor(profile.level);
    final cities = profile.capturedZones
        .map((z) => z.city)
        .whereType<String>()
        .toSet()
        .toList();
    if (profile.city != null && !cities.contains(profile.city)) {
      cities.insert(0, profile.city!);
    }

    return CustomScrollView(
      slivers: [
        _buildAppBar(profile, frameColor),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsRow(profile),
              _buildStatusSection(profile, frameColor),
              if (cities.isNotEmpty) _buildCitiesSection(cities),
              _buildCapturedPlaces(profile),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  // ── App bar (hero) ────────────────────────────────────────────

  Widget _buildAppBar(UserProfileEntity profile, Color frameColor) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: frameColor,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [frameColor, frameColor.withAlpha(200)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Avatar with level frame
                  _buildAvatar(profile, frameColor),
                  const SizedBox(height: 12),

                  // Display name
                  Text(
                    profile.displayLabel,
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black38),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // @username
                  Text(
                    '@${profile.username}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Level label chip + city chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _headerChip(
                        icon: Icons.military_tech,
                        label: 'Lv.${profile.level}  ${profile.levelTitle}',
                        color: Colors.white,
                      ),
                      if (profile.city != null) ...[
                        const SizedBox(width: 8),
                        _headerChip(
                          icon: Icons.location_on_rounded,
                          label: profile.city!,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfileEntity profile, Color frameColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(30),
            border: Border.all(color: Colors.white.withAlpha(80), width: 3),
          ),
        ),
        // Avatar
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            color: frameColor.withAlpha(60),
          ),
          child: ClipOval(
            child: profile.avatarUrl != null
                ? Image.network(
                    profile.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _avatarInitial(profile, Colors.white),
                  )
                : _avatarInitial(profile, Colors.white),
          ),
        ),
        // Level badge bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: frameColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              '${profile.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarInitial(UserProfileEntity profile, Color textColor) {
    return Container(
      color: Colors.white.withAlpha(30),
      child: Center(
        child: Text(
          profile.displayLabel[0].toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.headingFont,
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _headerChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────

  Widget _buildStatsRow(UserProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
              child: _statTile(
                  label: 'Points',
                  value: _fmt(profile.totalPoints),
                  icon: Icons.stars_rounded)),
          _verticalDivider(),
          Expanded(
              child: _statTile(
                  label: 'Strongholds',
                  value: '${profile.warlordCount}',
                  icon: Icons.emoji_events_rounded)),
          _verticalDivider(),
          Expanded(
              child: _statTile(
                  label: 'Raids',
                  value: '${profile.totalRaids}',
                  icon: Icons.restaurant_rounded,
                  subValue: '${profile.validRaids} valid')),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    String? subValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryLight),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge
                .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            label,
            style: AppTypography.caption
                .copyWith(color: AppColors.onSurfaceMutedLight),
          ),
          if (subValue != null)
            Text(
              subValue,
              style: AppTypography.caption.copyWith(
                color: AppColors.successLight,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => const SizedBox(width: 8);

  // ── Status section (level progress + trust) ───────────────────

  Widget _buildStatusSection(UserProfileEntity profile, Color frameColor) {
    final trustColor = profile.trustScore >= 80
        ? AppColors.successLight
        : profile.trustScore >= 50
            ? AppColors.warningLight
            : AppColors.errorLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raider Status',
              style: AppTypography.labelLarge
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // Level progress
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: frameColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: frameColor.withAlpha(80), width: 1),
                  ),
                  child: Text(
                    'Level ${profile.level}',
                    style: TextStyle(
                      color: frameColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            profile.levelTitle,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_fmt(profile.pointsInCurrentLevel)} / ${_fmt(profile.pointsForNextLevel)} XP',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.onSurfaceMutedLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: profile.levelProgress,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceVariantLight,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(frameColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Trust score
            Row(
              children: [
                Icon(Icons.verified_user_rounded,
                    size: 18, color: trustColor),
                const SizedBox(width: 8),
                Text(
                  'Trust Score',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${profile.trustScore}%',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: trustColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: profile.trustScore / 100,
                minHeight: 6,
                backgroundColor: AppColors.surfaceVariantLight,
                valueColor: AlwaysStoppedAnimation<Color>(trustColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cities conquered ──────────────────────────────────────────

  Widget _buildCitiesSection(List<String> cities) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city_rounded,
                  size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                'Cities Conquered',
                style: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cities
                .map((city) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withAlpha(12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primaryLight.withAlpha(60),
                            width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_rounded,
                              size: 12, color: AppColors.primaryLight),
                          const SizedBox(width: 4),
                          Text(
                            city,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Captured places list ──────────────────────────────────────

  Widget _buildCapturedPlaces(UserProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'Captured Places',
                style: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.gold.withAlpha(80), width: 1),
                ),
                child: Text(
                  '${profile.capturedZones.length}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.capturedZones.isEmpty)
            _buildNoCapturedZones()
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.borderLight, width: 1.2),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profile.capturedZones.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, color: AppColors.borderLight, indent: 16),
                itemBuilder: (_, i) =>
                    _buildZoneTile(profile.capturedZones[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoneTile(CapturedZoneEntity zone) {
    final color = _parseColour(zone.customColour);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(60), width: 1.5),
            ),
            child: Icon(_iconFor(zone.customIcon), color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // Name + title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                if (zone.customTitle != null)
                  Text(
                    zone.customTitle!,
                    style: AppTypography.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (zone.city != null)
                  Text(
                    zone.city!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onSurfaceMutedLight,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Visit count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: color.withAlpha(50), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant_rounded,
                        size: 11, color: color),
                    const SizedBox(width: 3),
                    Text(
                      '${zone.warlordRaids}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${zone.totalRaids} total',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.onSurfaceMutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoCapturedZones() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        children: [
          const Icon(Icons.restaurant_outlined,
              size: 40, color: AppColors.onSurfaceMutedLight),
          const SizedBox(height: 8),
          Text(
            'No places captured yet',
            style: AppTypography.bodyLarge
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Start raiding to claim your first zone!',
            style: AppTypography.caption.copyWith(
              color: AppColors.onSurfaceMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
