import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class FoodPassportScreen extends StatefulWidget {
  const FoodPassportScreen({super.key});

  @override
  State<FoodPassportScreen> createState() => _FoodPassportScreenState();
}

class _FoodPassportScreenState extends State<FoodPassportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _mockStrongholds = [
    {
      'name': 'The Burger Bastion',
      'location': 'Andheri West, Mumbai',
      'visits': 15,
      'title': 'Burger Warlord 🍔',
      'isWarlord': true,
      'colour': '#E53935',
      'icon': Icons.restaurant,
      'badgeName': 'Gold Burger Crown',
    },
    {
      'name': 'Sushi Slayer Dojo',
      'location': 'Bandra West, Mumbai',
      'visits': 10,
      'title': 'Wasabi Master 🍣',
      'isWarlord': true,
      'colour': '#4CAF50',
      'icon': Icons.lunch_dining,
      'badgeName': 'Silver Wasabi Blade',
    },
    {
      'name': 'Pizza Stronghold',
      'location': 'Powai, Mumbai',
      'visits': 3,
      'title': 'Slice Apprentice 🍕',
      'isWarlord': false,
      'colour': '#FF9800',
      'icon': Icons.local_pizza,
      'badgeName': 'Bronze Slice Shield',
    },
  ];

  final List<Map<String, dynamic>> _mockBadges = [
    {
      'name': 'Burger Commando',
      'description': 'Conquered 5+ burger raids in Mumbai sector.',
      'icon': '🍔',
      'rarity': 'COMMON',
      'unlockedAt': 'May 22, 2026',
    },
    {
      'name': 'Warlord Emperor',
      'description': 'Hold 2+ Warlord titles concurrently.',
      'icon': '👑',
      'rarity': 'MYTHIC',
      'unlockedAt': 'May 28, 2026',
    },
    {
      'name': 'Sushi Slayer',
      'description': 'Raided the Sushi Slayer Dojo 10 times.',
      'icon': '🥢',
      'rarity': 'RARE',
      'unlockedAt': 'May 29, 2026',
    },
    {
      'name': 'First Blood',
      'description': 'Successfully verified first raid bill.',
      'icon': '🔥',
      'rarity': 'COMMON',
      'unlockedAt': 'May 20, 2026',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text(
          'FOOD PASSPORT',
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
            Tab(text: 'STRONGHOLDS'),
            Tab(text: 'BADGES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStrongholdsTab(),
          _buildBadgesTab(),
        ],
      ),
    );
  }

  Widget _buildStrongholdsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: _mockStrongholds.length,
      itemBuilder: (context, index) {
        final stronghold = _mockStrongholds[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildStrongholdCard(stronghold),
        );
      },
    );
  }

  Widget _buildStrongholdCard(Map<String, dynamic> stronghold) {
    final bool isWarlord = stronghold['isWarlord'];
    Color customColor = AppColors.getPrimary(context);
    try {
      customColor = Color(int.parse('FF${stronghold['colour'].replaceAll('#', '')}', radix: 16));
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarlord ? customColor : AppColors.getBorder(context),
          width: isWarlord ? 1.8 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stronghold Custom Icon Circle
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: customColor.withAlpha((255 * 0.1).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(stronghold['icon'], color: customColor, size: 22),
              ),

              // Warlord Tag or Challenger Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isWarlord
                      ? customColor.withAlpha((255 * 0.15).toInt())
                      : AppColors.getSurfaceVariant(context),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isWarlord ? customColor : AppColors.getBorder(context),
                    width: 1,
                  ),
                ),
                child: Text(
                  isWarlord ? 'WARLORD HOLD' : 'CHALLENGER',
                  style: AppTypography.caption.copyWith(
                    color: isWarlord ? customColor : AppColors.getOnSurfaceMuted(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stronghold Details
          Text(
            stronghold['name'],
            style: AppTypography.displayLarge.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.getOnSurfaceMuted(context), size: 14),
              const SizedBox(width: 4),
              Text(
                stronghold['location'],
                style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
              ),
            ],
          ),
          const Divider(height: 24),

          // Visit counts, custom titles, & badge items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL VISITS',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.getOnSurfaceMuted(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stronghold['visits']} times',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'CUSTOM TITLE TAG',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.getOnSurfaceMuted(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stronghold['title'],
                    style: AppTypography.bodyLarge.copyWith(
                      color: customColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(20.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _mockBadges.length,
      itemBuilder: (context, index) {
        final badge = _mockBadges[index];
        return _buildBadgeCard(badge);
      },
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final rarity = badge['rarity'];
    Color rarityColor = AppColors.getOnSurfaceMuted(context);
    if (rarity == 'MYTHIC') {
      rarityColor = const Color(0xFF9C27B0); // Purple
    } else if (rarity == 'RARE') {
      rarityColor = AppColors.getPrimary(context); // Red/Orange
    } else if (rarity == 'COMMON') {
      rarityColor = AppColors.getSuccess(context); // Green
    }

    return GestureDetector(
      onTap: () {
        _triggerHaptic();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
              border: Border(top: BorderSide(color: AppColors.getBorder(context), width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 48,
                  color: AppColors.getBorder(context),
                ),
                Text(
                  badge['icon'],
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  badge['name'],
                  style: AppTypography.displayLarge.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rarityColor.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rarity,
                    style: AppTypography.caption.copyWith(color: rarityColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  badge['description'],
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'UNLOCKED AT: ${badge['unlockedAt']}',
                  style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(context), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge['icon'],
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 10),
            Text(
              badge['name'],
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              rarity,
              style: AppTypography.caption.copyWith(
                color: rarityColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
