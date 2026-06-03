import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'core/connectivity/connectivity_cubit.dart';

// Auth
import 'features/auth/domain/entities/user_entity.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

// Map & Zone
import 'features/map/presentation/bloc/map_bloc.dart';

// Shell (bottom navigation)
import 'features/shell/presentation/screens/main_shell.dart';

// Raid
import 'features/raid/presentation/bloc/raid_bloc.dart';
import 'features/raid/presentation/screens/raid_timer_screen.dart';
import 'features/raid/presentation/screens/bill_upload_screen.dart';

// Wallet
import 'features/wallet/presentation/bloc/wallet_bloc.dart';

// Leaderboard
import 'features/leaderboard/presentation/bloc/leaderboard_bloc.dart';

// Profile & Food Passport
import 'features/profile/presentation/screens/edit_profile_screen.dart';
import 'features/profile/presentation/screens/food_passport_screen.dart';

// Notifications
import 'features/notifications/presentation/screens/notifications_screen.dart';

// Onboarding
import 'features/onboarding/presentation/screens/onboarding_screen.dart';

import 'injection_container.dart' as di;

// ─────────────────────────────────────────────────────────────────
// CUSTOM PAGE TRANSITION — Slide + Fade
// ─────────────────────────────────────────────────────────────────
CustomTransitionPage<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class EatMapApp extends StatelessWidget {
  const EatMapApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildPage(const SplashScreen(), state),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPage(const LoginScreen(), state),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _buildPage(const OnboardingScreen(), state),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _buildPage(const MainShell(), state),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) {
          final user = state.extra as UserEntity;
          return _buildPage(EditProfileScreen(user: user), state);
        },
      ),
      GoRoute(
        path: '/profile/passport',
        pageBuilder: (context, state) =>
            _buildPage(const FoodPassportScreen(), state),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _buildPage(const NotificationsScreen(), state),
      ),
      GoRoute(
        path: '/raid-timer',
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return _buildPage(
            RaidTimerScreen(
              zoneId: params['zoneId'] as String,
              zoneName: params['zoneName'] as String,
              colour: params['colour'] as String,
            ),
            state,
          );
        },
      ),
      GoRoute(
        path: '/bill-upload',
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return _buildPage(
            BillUploadScreen(
              raidId: params['raidId'] as String,
              zoneName: params['zoneName'] as String,
              colour: params['colour'] as String,
            ),
            state,
          );
        },
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────
  // CENTRALIZED BUTTON THEMES
  // ─────────────────────────────────────────────────────────────────

  static ElevatedButtonThemeData _elevatedButtonTheme(bool isDark) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(bool isDark) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // CENTRALIZED INPUT THEME
  // ─────────────────────────────────────────────────────────────────

  static InputDecorationTheme _inputTheme(bool isDark) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surface = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final muted = isDark ? AppColors.onSurfaceMutedDark : AppColors.onSurfaceMutedLight;

    return InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppTypography.bodyMedium.copyWith(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.errorDark : AppColors.errorLight,
          width: 1.5,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityCubit>(
          create: (_) => di.sl<ConnectivityCubit>(),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<MapBloc>(
          create: (_) => di.sl<MapBloc>(),
        ),
        BlocProvider<RaidBloc>(
          create: (_) => di.sl<RaidBloc>(),
        ),
        BlocProvider<WalletBloc>(
          create: (_) => di.sl<WalletBloc>(),
        ),
        BlocProvider<LeaderboardBloc>(
          create: (_) => di.sl<LeaderboardBloc>(),
        ),
      ],
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connState) {
          return Column(
            children: [
              // ── Offline Banner ─────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: connState == ConnectivityState.offline ? 28 : 0,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.errorLight,
                      AppColors.errorLight.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: connState == ConnectivityState.offline
                    ? const Material(
                        color: Colors.transparent,
                        child: Text(
                          '⚡ No internet — showing cached data',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── App ────────────────────────────────────────────
              Expanded(
                child: MaterialApp.router(
                  title: 'EatMap',
                  debugShowCheckedModeBanner: false,
                  routerConfig: _router,
                  // App ships light-first; flip to ThemeMode.system to re-enable dark.
                  themeMode: ThemeMode.light,

                  // Keep text legible but layout-safe: clamp the device's font
                  // scale so very large/small system settings can't break UI.
                  builder: (context, child) {
                    final mq = MediaQuery.of(context);
                    return MediaQuery(
                      data: mq.copyWith(
                        textScaler: mq.textScaler.clamp(
                          minScaleFactor: 0.9,
                          maxScaleFactor: 1.15,
                        ),
                      ),
                      child: child!,
                    );
                  },

                  // ── LIGHT THEME ────────────────────────────────
                  theme: ThemeData(
                    useMaterial3: true,
                    brightness: Brightness.light,
                    scaffoldBackgroundColor: AppColors.backgroundLight,
                    primaryColor: AppColors.primaryLight,
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryLight,
                      surface: AppColors.surfaceLight,
                      onPrimary: AppColors.onPrimaryLight,
                      onSurface: AppColors.onSurfaceLight,
                      error: AppColors.errorLight,
                    ),
                    textTheme: AppTypography.createTextTheme(),
                    appBarTheme: const AppBarTheme(
                      backgroundColor: AppColors.surfaceLight,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      iconTheme: IconThemeData(color: AppColors.onSurfaceLight),
                    ),
                    cardTheme: const CardThemeData(
                      color: AppColors.surfaceLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                        side: BorderSide(color: AppColors.borderLight, width: 1),
                      ),
                    ),
                    elevatedButtonTheme: _elevatedButtonTheme(false),
                    outlinedButtonTheme: _outlinedButtonTheme(false),
                    inputDecorationTheme: _inputTheme(false),
                    splashColor: AppColors.primaryLight.withValues(alpha: 0.08),
                    highlightColor: AppColors.primaryLight.withValues(alpha: 0.05),
                  ),

                  // ── DARK THEME ─────────────────────────────────
                  darkTheme: ThemeData(
                    useMaterial3: true,
                    brightness: Brightness.dark,
                    scaffoldBackgroundColor: AppColors.backgroundDark,
                    primaryColor: AppColors.primaryDark,
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primaryDark,
                      surface: AppColors.surfaceDark,
                      onPrimary: AppColors.onPrimaryDark,
                      onSurface: AppColors.onSurfaceDark,
                      error: AppColors.errorDark,
                    ),
                    textTheme: AppTypography.createTextTheme(),
                    appBarTheme: const AppBarTheme(
                      backgroundColor: AppColors.surfaceDark,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      iconTheme: IconThemeData(color: AppColors.onSurfaceDark),
                    ),
                    cardTheme: const CardThemeData(
                      color: AppColors.surfaceDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                        side: BorderSide(color: AppColors.borderDark, width: 1),
                      ),
                    ),
                    elevatedButtonTheme: _elevatedButtonTheme(true),
                    outlinedButtonTheme: _outlinedButtonTheme(true),
                    inputDecorationTheme: _inputTheme(true),
                    splashColor: AppColors.primaryDark.withValues(alpha: 0.08),
                    highlightColor: AppColors.primaryDark.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
