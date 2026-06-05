import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/entities/zone_raider_entity.dart';
import '../bloc/place_detail_bloc.dart';
import '../bloc/place_detail_event.dart';
import '../bloc/place_detail_state.dart';

class PlaceDetailScreen extends StatefulWidget {
  final ZoneEntity zone;

  const PlaceDetailScreen({super.key, required this.zone});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late ZoneEntity _zone;
  late Color _themeColor;
  // Photo URL is pinned to the original zone and never overwritten by the API
  // response — the detail endpoint may omit photo_url even when the nearby
  // endpoint included it, which would cause the image to disappear on reload.
  late String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _zone = widget.zone;
    _photoUrl = widget.zone.photoUrl;
    _themeColor = _parseColor(_zone.customColour);
    context.read<PlaceDetailBloc>().add(LoadZoneRaiders(widget.zone.id));
  }

  Color _parseColor(String hex) {
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
    final authState = context.read<AuthBloc>().state;
    final String? currentUserId =
        authState is Authenticated ? authState.user.id : null;
    final bool isChampion = _zone.warlordId == currentUserId;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocConsumer<PlaceDetailBloc, PlaceDetailState>(
        listener: (context, state) {
          if (state is PlaceDetailLoaded) {
            setState(() {
              _zone = state.zone;
              _themeColor = _parseColor(state.zone.customColour);
              // Keep the original photo — API detail may return null photo_url.
              _photoUrl = widget.zone.photoUrl ?? state.zone.photoUrl;
            });
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(isChampion),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWarlordCard(isChampion),
                    _buildMetaRow(),
                    const SizedBox(height: 8),
                    _buildRaidersSection(state),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────

  Widget _buildSliverAppBar(bool isChampion) {
    final photoUrl = _photoUrl;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _themeColor,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Photo background via DecorationImage (reliable in FlexibleSpaceBar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                color: _themeColor,
                image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),

            // Gradient scrim — darker when photo present for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(photoUrl != null ? 50 : 0),
                    Colors.black.withAlpha(photoUrl != null ? 180 : 0),
                  ],
                ),
              ),
            ),

            // Text content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        if (_zone.category != null)
                          _chip(
                            icon: _iconFor(_zone.customIcon),
                            label: _zone.category!,
                          ),
                        const Spacer(),
                        if (isChampion)
                          _chip(
                            icon: Icons.military_tech,
                            label: 'YOUR PLACE',
                            color: AppColors.gold,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _zone.name,
                      style: AppTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        shadows: const [
                          Shadow(blurRadius: 8, color: Colors.black54),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_zone.customTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _zone.customTitle!,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                    if (_zone.rating != null) ...[
                      const SizedBox(height: 8),
                      _buildRatingRow(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({required IconData icon, required String label, Color? color}) {
    final c = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    final rating = _zone.rating!;
    final stars = rating.clamp(0.0, 5.0);
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < stars.floor()) {
            return const Icon(Icons.star_rounded,
                color: AppColors.gold, size: 16);
          } else if (i < stars.ceil() && stars % 1 >= 0.5) {
            return const Icon(Icons.star_half_rounded,
                color: AppColors.gold, size: 16);
          } else {
            return const Icon(Icons.star_outline_rounded,
                color: Colors.white54, size: 16);
          }
        }),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        if (_zone.userRatingsTotal != null) ...[
          const SizedBox(width: 4),
          Text(
            '(${_formatCount(_zone.userRatingsTotal!)})',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
        if (_zone.priceLevel != null) ...[
          const SizedBox(width: 10),
          Text(
            _priceLabel(_zone.priceLevel!),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  // ── Meta strip ────────────────────────────────────────────────────

  Widget _buildMetaRow() {
    if (_zone.category == null && _zone.priceLevel == null) {
      return const SizedBox(height: 4);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (_zone.category != null) ...[
            Icon(Icons.category_outlined,
                size: 14, color: AppColors.onSurfaceMutedLight),
            const SizedBox(width: 4),
            Text(
              _capitalize(_zone.category!),
              style: AppTypography.caption
                  .copyWith(color: AppColors.onSurfaceMutedLight),
            ),
          ],
          if (_zone.category != null && _zone.priceLevel != null)
            const SizedBox(width: 16),
          if (_zone.priceLevel != null) ...[
            Icon(Icons.attach_money_rounded,
                size: 14, color: AppColors.onSurfaceMutedLight),
            Text(
              _priceLabel(_zone.priceLevel!),
              style: AppTypography.caption
                  .copyWith(color: AppColors.onSurfaceMutedLight),
            ),
          ],
        ],
      ),
    );
  }

  // ── Warlord card ──────────────────────────────────────────────────

  Widget _buildWarlordCard(bool isChampion) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(isChampion),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _zone.warlordId == null
                          ? 'UNCLAIMED SPOT'
                          : isChampion
                              ? 'YOUR PLACE'
                              : 'CLAIMED BY',
                      style: AppTypography.caption.copyWith(
                        color: _zone.warlordId == null
                            ? AppColors.onSurfaceMutedLight
                            : isChampion
                                ? AppColors.successLight
                                : _themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _zone.warlordId == null
                          ? 'Be the first to dine here!'
                          : isChampion
                              ? 'You are the champion'
                              : (_zone.warlordUsername ?? 'Food Champion'),
                      style: AppTypography.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_zone.warlordId != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_zone.warlordRaids} champion visits · ${_zone.totalRaids} total',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.onSurfaceMutedLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isChampion) {
    if (_zone.warlordId == null) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _themeColor.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(_iconFor(_zone.customIcon), color: _themeColor, size: 26),
      );
    }
    final borderColor = isChampion ? AppColors.successLight : _themeColor;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.5),
      ),
      child: ClipOval(
        child: _zone.warlordAvatarUrl != null
            ? Image.network(
                _zone.warlordAvatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _initialBox(_zone.warlordUsername ?? 'W', borderColor),
              )
            : _initialBox(_zone.warlordUsername ?? 'W', borderColor),
      ),
    );
  }

  Widget _initialBox(String name, Color color) {
    return Container(
      color: color.withAlpha(20),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.headingFont,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  // ── Raiders leaderboard ───────────────────────────────────────────

  Widget _buildRaidersSection(PlaceDetailState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: _themeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Raiders Leaderboard',
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Ranked by total visits',
            style: AppTypography.caption
                .copyWith(color: AppColors.onSurfaceMutedLight),
          ),
          const SizedBox(height: 12),
          switch (state) {
            PlaceDetailLoading() => _buildShimmer(),
            PlaceDetailLoaded(:final raiders) when raiders.isEmpty =>
              _buildEmpty(),
            PlaceDetailLoaded(:final raiders) => _buildRaidersList(raiders),
            PlaceDetailError(:final message) => _buildError(message),
            PlaceDetailInitial() => _buildShimmer(),
          },
        ],
      ),
    );
  }

  Widget _buildRaidersList(List<ZoneRaiderEntity> raiders) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: raiders.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: AppColors.borderLight,
          indent: 72,
        ),
        itemBuilder: (context, index) =>
            _buildRaiderTile(raiders[index], index + 1),
      ),
    );
  }

  Widget _buildRaiderTile(ZoneRaiderEntity raider, int rank) {
    void goToProfile() {
      if (raider.userId.isNotEmpty) {
        context.push('/user-profile', extra: {
          'userId': raider.userId,
          'previewName': raider.displayName ?? raider.username,
          'previewAvatarUrl': raider.avatarUrl,
        });
      }
    }
    Color rankColor;
    IconData? trophyIcon;
    switch (rank) {
      case 1:
        rankColor = AppColors.gold;
        trophyIcon = Icons.emoji_events;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        trophyIcon = Icons.emoji_events;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        trophyIcon = Icons.emoji_events;
      default:
        rankColor = AppColors.onSurfaceMutedLight;
        trophyIcon = null;
    }
    final isTop = rank == 1;

    return InkWell(
      onTap: goToProfile,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: trophyIcon != null
                ? Icon(trophyIcon, color: rankColor, size: 22)
                : Text(
                    '#$rank',
                    style: AppTypography.caption.copyWith(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isTop ? AppColors.gold : _themeColor.withAlpha(80),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: raider.avatarUrl != null
                  ? Image.network(
                      raider.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _raiderInitial(raider, isTop),
                    )
                  : _raiderInitial(raider, isTop),
            ),
          ),
          const SizedBox(width: 12),

          // Name + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        raider.displayLabel,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight:
                              isTop ? FontWeight.bold : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (raider.isStronghold) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.gold.withAlpha(120), width: 1),
                        ),
                        child: const Text(
                          'WARLORD',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '@${raider.username}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.onSurfaceMutedLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Visit count badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isTop
                      ? AppColors.gold.withAlpha(20)
                      : _themeColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isTop
                        ? AppColors.gold.withAlpha(80)
                        : _themeColor.withAlpha(40),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      size: 11,
                      color: isTop ? AppColors.gold : _themeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${raider.raidCount}',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isTop ? AppColors.gold : _themeColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (raider.validRaidCount > 0 &&
                  raider.validRaidCount != raider.raidCount)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${raider.validRaidCount} verified',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.onSurfaceMutedLight,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _raiderInitial(ZoneRaiderEntity raider, bool isTop) {
    return Container(
      color: (isTop ? AppColors.gold : _themeColor).withAlpha(20),
      child: Center(
        child: Text(
          raider.displayLabel[0].toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.headingFont,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isTop ? AppColors.gold : _themeColor,
          ),
        ),
      ),
    );
  }

  // ── Empty / loading / error ────────────────────────────────────────

  Widget _buildShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _shimmerBox(32, 32, radius: 6),
                const SizedBox(width: 12),
                _shimmerBox(40, 40, radius: 20),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBox(14, double.infinity, radius: 6)),
                const SizedBox(width: 12),
                _shimmerBox(14, 56, radius: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = 4}) {
    return Container(
      height: height,
      width: width == double.infinity ? null : width,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_outlined,
              size: 48, color: _themeColor.withAlpha(120)),
          const SizedBox(height: 12),
          Text(
            'No raiders yet',
            style:
                AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to dine here and claim this spot!',
            style: AppTypography.caption
                .copyWith(color: AppColors.onSurfaceMutedLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 36, color: AppColors.onSurfaceMutedLight),
          const SizedBox(height: 8),
          Text(
            'Could not load raiders',
            style:
                AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTypography.caption
                .copyWith(color: AppColors.onSurfaceMutedLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context
                .read<PlaceDetailBloc>()
                .add(LoadZoneRaiders(widget.zone.id)),
            child: Text('Retry', style: TextStyle(color: _themeColor)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  String _priceLabel(int level) => '\$' * level.clamp(1, 4);

  String _formatCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
