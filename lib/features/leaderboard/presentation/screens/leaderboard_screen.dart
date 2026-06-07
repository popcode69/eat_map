import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/leaderboard_bloc.dart';
import '../bloc/leaderboard_event.dart';
import '../bloc/leaderboard_state.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initial load: City Rankings (pass user's city so the backend filters correctly)
    final authState = context.read<AuthBloc>().state;
    final city = authState is Authenticated ? authState.user.city : null;
    context.read<LeaderboardBloc>().add(LoadLeaderboardRequested('city', city: city));
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      HapticFeedback.lightImpact();
      final scopes = ['city', 'global'];
      final scope = scopes[_tabController.index];
      String? city;
      if (scope == 'city') {
        final authState = context.read<AuthBloc>().state;
        city = authState is Authenticated ? authState.user.city : null;
      }
      context.read<LeaderboardBloc>().add(LoadLeaderboardRequested(scope, city: city));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text(
          'CITY RANKINGS',
          style: TextStyle(
            fontFamily: AppTypography.headingFont,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.getPrimary(context),
          labelColor: AppColors.getPrimary(context),
          unselectedLabelColor: AppColors.getOnSurfaceMuted(context),
          labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'CITY'),
            Tab(text: 'GLOBAL'),
          ],
        ),
      ),
      body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) {
          if (state is LeaderboardLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.getPrimary(context)),
            );
          }

          if (state is LeaderboardError) {
            return Center(
              child: Text(
                'Failed to load ranks: ${state.message}',
                style: TextStyle(color: AppColors.getError(context)),
              ),
            );
          }

          if (state is LeaderboardLoaded) {
            final rankings = state.rankings;
            final scope = state.scope;

            final authState = context.read<AuthBloc>().state;
            final currentUserId =
                authState is Authenticated ? authState.user.id : null;
            final currentCity =
                authState is Authenticated ? authState.user.city : null;

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<LeaderboardBloc>().add(LoadLeaderboardRequested(scope));
                },
                color: AppColors.getPrimary(context),
                child: ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: rankings.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSpotlightHeader(scope, currentCity);
                    }

                    final rankItem = rankings[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildRankCard(rankItem, scope, currentUserId),
                    );
                  },
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSpotlightHeader(String scope, String? currentCity) {
    final cityName = (currentCity != null && currentCity.isNotEmpty)
        ? currentCity.toUpperCase()
        : 'YOUR CITY';
    String title = '$cityName TACTICAL SECTOR';
    String subtitle = 'All active raiders in $cityName';
    IconData icon = Icons.location_city_outlined;
    Color scopeColor = AppColors.getPrimary(context);

    if (scope == 'global') {
      title = 'GLOBAL COMMAND CONQUEST';
      subtitle = 'Warlords ranking across all operational cities';
      icon = Icons.language_outlined;
      scopeColor = AppColors.getWarning(context);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scopeColor.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scopeColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(dynamic rankItem, String scope, String? currentUserId) {
    final String? userId = rankItem.userId as String?;
    final int rank = rankItem.rank;
    // Identify the logged-in user by their ID (most reliable).
    // Fall back to username match when userId isn't in the leaderboard response.
    final bool isUser = currentUserId != null && userId != null
        ? userId == currentUserId
        : false;

    // Spotlight visual coloring for Top 3
    Color medalColor = Colors.transparent;
    bool isTop3 = rank <= 3;
    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
    }

    Color cardBorderColor = isUser
        ? AppColors.getPrimary(context)
        : AppColors.getBorder(context);

    double cardBorderWidth = isUser ? 1.8 : 1.2;

    return GestureDetector(
      onTap: userId != null
          ? () => context.push('/user-profile', extra: {
                'userId': userId,
                'previewName':
                    rankItem.displayName ?? rankItem.username,
                'previewAvatarUrl': rankItem.avatarUrl,
              })
          : null,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.getPrimary(context).withAlpha((255 * 0.05).toInt())
            : AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorderColor, width: cardBorderWidth),
      ),
      child: Row(
        children: [
          // 1. Rank / Medal Widget
          SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: isTop3
                  ? Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: medalColor.withAlpha((255 * 0.15).toInt()),
                        shape: BoxShape.circle,
                        border: Border.all(color: medalColor, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontFamily: AppTypography.headingFont,
                          fontWeight: FontWeight.bold,
                          color: medalColor,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : Text(
                      '$rank',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.getOnSurfaceMuted(context),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Avatar placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.getPrimaryLight(context).withAlpha((255 * 0.2).toInt())
                  : AppColors.getSurfaceVariant(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.getBorder(context), width: 1),
            ),
            child: Icon(
              Icons.person_outline,
              color: isUser ? AppColors.getPrimary(context) : AppColors.getOnSurfaceMuted(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // 3. Warlord Name / Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rankItem.displayName ?? rankItem.username,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUser ? AppColors.getPrimary(context) : AppColors.getOnSurface(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rankItem.warlordCount} active warlord claims',
                  style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                ),
              ],
            ),
          ),

          // 4. Points Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${rankItem.totalPoints}',
                style: AppTypography.titleLarge.copyWith(
                  fontFamily: AppTypography.headingFont,
                  fontWeight: FontWeight.bold,
                  color: isUser ? AppColors.getPrimary(context) : AppColors.getOnSurface(context),
                ),
              ),
              Text(
                'PTS',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  color: AppColors.getOnSurfaceMuted(context),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
