import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_modals.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../map/presentation/bloc/map_bloc.dart';
import '../bloc/raid_bloc.dart';
import '../bloc/raid_bloc.dart' as bloc_state;

class RaidTimerScreen extends StatefulWidget {
  final String zoneId;
  final String zoneName;
  final String colour;
  final double? userLat;
  final double? userLng;

  const RaidTimerScreen({
    super.key,
    required this.zoneId,
    required this.zoneName,
    required this.colour,
    this.userLat,
    this.userLng,
  });

  @override
  State<RaidTimerScreen> createState() => _RaidTimerScreenState();
}

class _RaidTimerScreenState extends State<RaidTimerScreen> {
  @override
  void initState() {
    super.initState();
    // Grab real user identity from AuthBloc
    final authState = context.read<AuthBloc>().state;
    final String userId = authState is Authenticated ? authState.user.id : 'unknown_user';
    final String username = authState is Authenticated
        ? (authState.user.displayName ?? authState.user.username)
        : 'Raider';

    // If the bloc already has an active timer (resumed from storage), do not
    // start a new raid — just let the existing state drive the UI.
    final currentState = context.read<RaidBloc>().state;
    if (currentState is RaidTimerActive || currentState is RaidTimerCompleted) {
      return;
    }

    context.read<RaidBloc>().add(RaidStartRequested(
          zoneId: widget.zoneId,
          zoneName: widget.zoneName,
          colour: widget.colour,
          lat: widget.userLat ?? 0.0,
          lng: widget.userLng ?? 0.0,
          deviceId: 'local_device_fingerprint',
          userId: userId,
          username: username,
        ));
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = AppColors.getPrimary(context);
    try {
      themeColor = Color(int.parse('FF${widget.colour.replaceAll('#', '')}', radix: 16));
    } catch (_) {}

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text(
          'Active Raid Session',
          style: TextStyle(fontFamily: AppTypography.headingFont, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<RaidBloc, RaidState>(
        listener: (context, state) {
          if (state is bloc_state.RaidTimerCompleted) {
            // Timer completed → auto-verify immediately, no bill required.
            HapticFeedback.heavyImpact();
            context.read<RaidBloc>().add(RaidVerificationSubmitted(
                  raidId: state.raidId,
                  spendAmount: 0,
                ));
          } else if (state is bloc_state.RaidSuccess) {
            AppModals.raidResult(
              context,
              points: state.points,
              rank: state.rank,
              isWarlord: state.isWarlord,
              zoneName: widget.zoneName,
            ).then((_) {
              if (!context.mounted) return;
              context.read<AuthBloc>().add(AuthCheckRequested());
              if (widget.userLat != null && widget.userLng != null) {
                context.read<MapBloc>().add(LoadNearbyZonesRequested(
                  'te7u6b',
                  lat: widget.userLat,
                  lng: widget.userLng,
                ));
              } else {
                context.read<MapBloc>().add(const LoadNearbyZonesRequested('te7u6b'));
              }
              context.go('/home');
            });
          } else if (state is RaidFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.getError(context)),
            );
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is RaidLoading) {
            return Center(
              child: CircularProgressIndicator(color: themeColor),
            );
          }

          // Timer completed or verifying — show spinner while auto-verify runs.
          if (state is bloc_state.RaidTimerCompleted ||
              state is bloc_state.RaidVerifying) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: themeColor, strokeWidth: 3),
                  const SizedBox(height: 24),
                  Text(
                    "Time's up! Verifying your visit…",
                    style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (state is bloc_state.RaidTimerActive) {
            final secondsRemaining = state.secondsRemaining;
            final progressPercent = state.totalSeconds > 0
                ? secondsRemaining / state.totalSeconds
                : 0.0;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.zoneName,
                      style: AppTypography.displayLarge.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'INFILTRATING STRONGHOLD RANGE',
                      style: AppTypography.caption.copyWith(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
  
                    const SizedBox(height: 60),
  
                    // Timer Dial widget
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Circular progress ring
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: CircularProgressIndicator(
                              value: progressPercent,
                              strokeWidth: 10,
                              backgroundColor: AppColors.getBorder(context),
                              color: themeColor,
                            ),
                          ),
                          
                          // Numeric timer readout
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatDuration(secondsRemaining),
                                style: AppTypography.displayLarge.copyWith(
                                  fontSize: 44,
                                  fontFamily: AppTypography.headingFont,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'MINUTES REMAINING',
                                style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
  
                    const SizedBox(height: 80),
  
                    // Verification CTAs
                    Card(
                      color: AppColors.getSurface(context),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Skip Timer — Upload Bill',
                              style: AppTypography.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Have a receipt or UPI ref? Upload it now to verify instantly without waiting.',
                              style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            
                            // VERIFY SUBMIT CTA
                            ElevatedButton(
                              onPressed: () {
                                _triggerHaptic();
                                context.push('/bill-upload', extra: {
                                  'raidId': state.raidId,
                                  'zoneName': widget.zoneName,
                                  'colour': widget.colour,
                                  'userLat': widget.userLat,
                                  'userLng': widget.userLng,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'UPLOAD BILL TO VERIFY NOW',
                                    style: TextStyle(
                                      fontFamily: AppTypography.headingFont,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
