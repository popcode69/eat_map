import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Tab indices for the bottom navigation. Use these instead of magic numbers
/// when switching tabs via [MainShell.of].
class ShellTab {
  ShellTab._();
  static const int map = 0;
  static const int ranks = 1;
  static const int wallet = 2;
  static const int profile = 3;
}

/// Root scaffold that hosts the primary tabs behind a persistent bottom
/// navigation bar. The four destinations are kept alive via [IndexedStack] so
/// each tab retains its scroll position and bloc state when switched.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = ShellTab.map});

  /// Lets descendant widgets (e.g. the map drawer or a profile card) switch
  /// the active tab: `MainShell.of(context)?.goToTab(ShellTab.wallet)`.
  static MainShellController? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainShellState>();
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

/// Public surface exposed to descendants for tab switching.
abstract class MainShellController {
  void goToTab(int index);
}

class _MainShellState extends State<MainShell> implements MainShellController {
  late int _index = widget.initialIndex;

  static const List<Widget> _screens = [
    MapScreen(),
    LeaderboardScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  void goToTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = AppColors.getPrimary(context);
    final Color muted = AppColors.getOnSurfaceMuted(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          border: Border(
            top: BorderSide(color: AppColors.getBorder(context), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: primary.withValues(alpha: 0.14),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => AppTypography.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: states.contains(WidgetState.selected) ? primary : muted,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                size: 24,
                color: states.contains(WidgetState.selected) ? primary : muted,
              ),
            ),
          ),
          child: NavigationBar(
            height: 64,
            selectedIndex: _index,
            backgroundColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              HapticFeedback.selectionClick();
              goToTab(i);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_outlined),
                selectedIcon: Icon(Icons.leaderboard_rounded),
                label: 'Ranks',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Wallet',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
