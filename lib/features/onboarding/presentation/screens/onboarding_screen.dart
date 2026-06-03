import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/cache/secure_storage.dart';
import '../../../../injection_container.dart' as di;

/// Three-step tutorial shown to first-time raiders after sign-in
/// (PRD §8.1 — Raid / Conquer / Earn).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  final IconData icon;
  final String emoji;
  final String title;
  final String body;
  final Color accent;

  const _OnboardingPage({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.body,
    required this.accent,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.location_searching_rounded,
      emoji: '⚔️',
      title: 'RAID',
      body:
          'Walk up to any restaurant on the map. Get within 50m, tap the zone, '
          'and start a raid. Stay 15 minutes and prove your spend to lock it in.',
      accent: Color(0xFF00C853),
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      emoji: '🛡️',
      title: 'CONQUER',
      body:
          'Rack up the most visits at a spot to become its Warlord. Rename it, '
          'pick a banner colour, and fly your flag for the whole city to see.',
      accent: Color(0xFFE53935),
    ),
    _OnboardingPage(
      icon: Icons.account_balance_wallet_rounded,
      emoji: '💰',
      title: 'EARN',
      body:
          'Earn real rewards every time someone raids your stronghold — plus '
          'streak bonuses, weekly challenges, and referral payouts to your UPI.',
      accent: Color(0xFFFFA000),
    ),
  ];

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await di.sl<SecureStorage>().setOnboardingSeen();
    if (!mounted) return;
    context.go('/home');
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _index == _pages.length - 1;
    final Color accent = _pages[_index].accent;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ───────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: isLast ? null : _finish,
                  child: Text('Skip',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.getOnSurfaceMuted(context))),
                ),
              ),
            ),

            // ── Pages ──────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _buildPage(_pages[i]),
              ),
            ),

            // ── Dots ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final selected = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: selected ? 24 : 8,
                  decoration: BoxDecoration(
                    color: selected ? accent : AppColors.getBorder(context),
                    borderRadius: BorderRadius.circular(100),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // ── CTA ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isLast ? "LET'S CONQUER 🚀" : 'NEXT',
                  style: const TextStyle(
                    fontFamily: AppTypography.headingFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon medallion
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: page.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: page.accent, width: 2),
            ),
            child: Icon(page.icon, size: 64, color: page.accent),
          ),
          const SizedBox(height: 40),
          Text('${page.emoji}  ${page.title}',
              style: AppTypography.displayLarge
                  .copyWith(color: page.accent, letterSpacing: 1)),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.getOnSurfaceMuted(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
