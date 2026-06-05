import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../shell/presentation/screens/main_shell.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingAvatar = false;

  void _triggerHaptic() => HapticFeedback.lightImpact();

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(context).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt_outlined, color: AppColors.getPrimary(context)),
              ),
              title: Text('Take Photo', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text('Use camera to capture', style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context))),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(context).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library_outlined, color: AppColors.getPrimary(context)),
              ),
              title: Text('Choose from Gallery', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text('Pick an existing image', style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context))),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    _triggerHaptic();
    final source = await _showImageSourceSheet();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    context.read<AuthBloc>().add(UploadAvatarRequested(filePath: picked.path));
  }

  Future<void> _handleSignOut(BuildContext context) async {
    _triggerHaptic();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.getOnSurface(context),
          ),
        ),
        content: Text(
          'Are you sure you want to sign out from EatMap? You will need to sign in again to access your account.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.getOnSurfaceMuted(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getOnSurfaceMuted(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getError(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Sign out from Google (clears cached Google session)
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Ignore — Google sign-out failure shouldn't block local sign-out
    }

    if (!mounted) return;

    // Clear local tokens and auth state
    context.read<AuthBloc>().add(SignOutRequested());
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated && _isUploadingAvatar) {
          setState(() => _isUploadingAvatar = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Avatar updated successfully!'),
              backgroundColor: AppColors.getSuccess(context),
            ),
          );
        } else if (state is AvatarUploadFailure) {
          setState(() => _isUploadingAvatar = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.getError(context),
            ),
          );
        } else if (state is Unauthenticated) {
          // Navigate to login when auth state becomes unauthenticated
          context.go('/login');
        }
      },
      builder: (context, state) {
        UserEntity? user;
        if (state is Authenticated) user = state.user;
        else if (state is AvatarUploadFailure) user = state.user;
        else if (state is ProfileUpdateFailure) user = state.user;

        final username = user?.username ?? 'Raider';
        final avatarUrl = user?.avatarUrl;
        final level = user?.level ?? 5;
        final points = user?.totalPoints ?? 6400;
        final trustScore = user?.trustScore ?? 98;
        final accountAge = user?.accountAge ?? 12;
        final joinedDate = user != null
            ? DateFormat('MMM dd, yyyy').format(user.createdAt)
            : 'May 20, 2026';

        Color trustColor = AppColors.getSuccess(context);
        String trustLabel = 'EXCELLENT';
        if (trustScore < 75) {
          trustColor = AppColors.getError(context);
          trustLabel = 'CRITICAL WARNING';
        } else if (trustScore < 90) {
          trustColor = AppColors.getWarning(context);
          trustLabel = 'RESTRICTED';
        }

        return Scaffold(
          backgroundColor: AppColors.getBackground(context),
          appBar: AppBar(
            title: const Text(
              'RAIDER PROFILE',
              style: TextStyle(
                fontFamily: AppTypography.headingFont,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileAvatar(avatarUrl, username, joinedDate, user),
                  const SizedBox(height: 24),
                  _buildTrustScoreCard(trustScore, trustColor, trustLabel),
                  const SizedBox(height: 16),
                  _buildLevelProgressBar(level, points),
                  const SizedBox(height: 24),
                  Text(
                    'COMMAND METRICS',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.getOnSurface(context),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricsGrid(trustScore, accountAge, points),
                  const SizedBox(height: 28),
                  _buildNavigationCTAs(),
                  const SizedBox(height: 28),
                  _buildSignOutButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(String? avatarUrl, String username, String joinedDate, UserEntity? user) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.getPrimaryLight(context).withAlpha(38),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.getPrimary(context), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.getPrimary(context).withAlpha(13),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          width: 84,
                          height: 84,
                          placeholder: (_, __) => Center(
                            child: CircularProgressIndicator(
                              color: AppColors.getPrimary(context),
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.shield_outlined,
                            color: AppColors.getPrimary(context),
                            size: 40,
                          ),
                        )
                      : Icon(
                          Icons.shield_outlined,
                          color: AppColors.getPrimary(context),
                          size: 40,
                        ),
                ),
              ),
              if (_isUploadingAvatar)
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    color: AppColors.getPrimary(context),
                    strokeWidth: 3,
                  ),
                ),
              if (!_isUploadingAvatar)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.getBackground(context), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          username.toUpperCase(),
          style: AppTypography.displayLarge.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          'Operational Raider since $joinedDate',
          style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
          child: Text(
            _isUploadingAvatar ? 'Uploading...' : 'Tap avatar to change',
            style: AppTypography.caption.copyWith(
              color: _isUploadingAvatar
                  ? AppColors.getOnSurfaceMuted(context)
                  : AppColors.getPrimary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: user == null
              ? null
              : () {
                  _triggerHaptic();
                  context.push('/profile/edit', extra: user);
                },
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('EDIT PROFILE'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: TextStyle(
              fontFamily: AppTypography.headingFont,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustScoreCard(int trustScore, Color trustColor, String trustLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trustColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: trustColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.gavel_outlined, color: trustColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VERIFICATION TRUST SCORE',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.getOnSurfaceMuted(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$trustScore%',
                      style: AppTypography.titleLarge.copyWith(color: trustColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'STATUS: $trustLabel',
                  style: AppTypography.caption.copyWith(
                    color: trustColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  trustScore < 90
                      ? 'Warning: Submit valid and clear bills. Avoid duplicate uploads to prevent bans.'
                      : 'Excellent trust rating! Enjoy instant cash withdrawal approvals.',
                  style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.getOnSurfaceMuted(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgressBar(int level, int points) {
    final currentXP = points % 10000;
    const nextLevelXP = 10000;
    final progress = currentXP / nextLevelXP;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LEVEL $level COMMANDER',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$currentXP / $nextLevelXP XP',
                style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.getSurfaceVariant(context),
              color: AppColors.getPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(int trustScore, int accountAge, int points) {
    return Row(
      children: [
        Expanded(child: _buildMetricItem('⚔️ Total Raids', '42 visits', 'verified checks')),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricItem('🛡️ Strongholds', '5 warlords', 'active control')),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, String subtext) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(context), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtext, style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context))),
        ],
      ),
    );
  }

  Widget _buildNavigationCTAs() {
    return Column(
      children: [
        _buildNavCard(
          icon: Icons.qr_code_2_outlined,
          title: 'FOOD PASSPORT',
          subtitle: 'Check operational strongholds & restaurant badges',
          color: AppColors.getPrimary(context),
          onTap: () {
            _triggerHaptic();
            context.push('/profile/passport');
          },
        ),
        const SizedBox(height: 12),
        _buildNavCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'WITHDRAWAL CENTER',
          subtitle: 'Manage earnings ledger & instant payouts',
          color: AppColors.getSuccess(context),
          onTap: () {
            _triggerHaptic();
            MainShell.of(context)?.goToTab(ShellTab.wallet);
          },
        ),
        const SizedBox(height: 12),
        _buildNavCard(
          icon: Icons.add_location_alt_rounded,
          title: 'SUGGEST A PLACE',
          subtitle: 'Request admin to add a new restaurant or café',
          color: const Color(0xFF7C4DFF),
          onTap: () {
            _triggerHaptic();
            context.push('/request-place');
          },
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getBorder(context), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.getOnSurfaceMuted(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.getOnSurfaceMuted(context), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return OutlinedButton(
      onPressed: () => _handleSignOut(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: AppColors.getError(context)),
      ),
      child: Text(
        '⚔️ SIGN OUT FROM SECTOR',
        style: TextStyle(
          fontFamily: AppTypography.headingFont,
          fontWeight: FontWeight.bold,
          color: AppColors.getError(context),
        ),
      ),
    );
  }
}
