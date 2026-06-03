import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_animations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final DateTime _startTime;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Check the current auth state in case it resolved prior to building the splash screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AuthBloc>().state;
      if (state is Authenticated || state is Unauthenticated || state is AuthFailure) {
        _navigateBasedOnState(state);
      }
    });
  }

  void _navigateBasedOnState(AuthState state) {
    if (_isNavigated) return;

    final elapsed = DateTime.now().difference(_startTime);
    final remaining = const Duration(seconds: 2) - elapsed;

    if (remaining.isNegative) {
      _doNavigate(state);
    } else {
      Future.delayed(remaining, () {
        _doNavigate(state);
      });
    }
  }

  void _doNavigate(AuthState state) {
    if (_isNavigated || !mounted) return;
    _isNavigated = true;

    if (state is Authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = AppColors.getPrimary(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated || state is Unauthenticated || state is AuthFailure) {
            _navigateBasedOnState(state);
          }
        },
        child: Stack(
          children: [
            // Ambient glowing radial backdrop
            Container(
              decoration: BoxDecoration(
                color: AppColors.getBackground(context),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    primary.withOpacity(isDark ? 0.08 : 0.04),
                    primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            
            // Center Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cyberpunk Pulsing Brand Logo
                  PulseAnimation(
                    duration: const Duration(milliseconds: 1500),
                    minScale: 0.92,
                    maxScale: 1.08,
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.getPrimaryLight(context),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(isDark ? 0.4 : 0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Brand Name Reveal
                  FadeSlideIn(
                    duration: const Duration(milliseconds: 600),
                    offset: const Offset(0, 16),
                    child: Text(
                      'EatMap',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.getOnSurface(context),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Gamified Tagline Reveal
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 600),
                    offset: const Offset(0, 12),
                    child: Text(
                      'CONQUER ZONES · CLAIM BOUNTIES',
                      style: AppTypography.caption.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Sleek Linear Loader & Tactical Status
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 600),
                    offset: const Offset(0, 8),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: AppColors.getBorder(context),
                              valueColor: AlwaysStoppedAnimation<Color>(primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'INITIALIZING CONQUEST ENGINE...',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.getOnSurfaceMuted(context).withOpacity(0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 600),
                offset: const Offset(0, 8),
                child: Text(
                  'v1.0.0 · SECURED BY SUPABASE',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.getOnSurfaceMuted(context).withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
