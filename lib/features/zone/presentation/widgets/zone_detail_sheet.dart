import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/usecases/customize_zone.dart';
import '../../../../injection_container.dart' as di;

/// Max distance (metres) a raider may be from a zone to raid/capture it.
/// Matches the PRD §5.2 GPS geofence (within 50m).
const double kRaidRadiusMeters = 50;

class ZoneDetailSheet extends StatefulWidget {
  final ZoneEntity zone;
  final VoidCallback? onRaidStarted;
  final Function(ZoneEntity)? onZoneUpdated;

  /// Distance in metres from the user to this zone. `null` means location is
  /// unknown. Raid/capture is only allowed within [kRaidRadiusMeters].
  final double? distanceMeters;

  const ZoneDetailSheet({
    super.key,
    required this.zone,
    this.onRaidStarted,
    this.onZoneUpdated,
    this.distanceMeters,
  });

  @override
  State<ZoneDetailSheet> createState() => _ZoneDetailSheetState();
}

class _ZoneDetailSheetState extends State<ZoneDetailSheet> {
  late ZoneEntity _currentZone;
  bool _isEditing = false;

  final _titleController = TextEditingController();
  String _selectedColour = '#E53935';
  String _selectedIcon = 'fork';

  @override
  void initState() {
    super.initState();
    _currentZone = widget.zone;
    _titleController.text = _currentZone.customTitle ?? '';
    _selectedColour = _currentZone.customColour;
    _selectedIcon = _currentZone.customIcon;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  /// True only when the user is physically within the raid geofence.
  bool get _inRange =>
      widget.distanceMeters != null &&
      widget.distanceMeters! <= kRaidRadiusMeters;

  Future<void> _saveCustomization() async {
    _triggerHaptic();
    final customizer = di.sl<CustomizeZone>();
    
    final result = await customizer(
      zoneId: _currentZone.id,
      title: _titleController.text.trim(),
      colour: _selectedColour,
      icon: _selectedIcon,
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.errorLight,
          ),
        );
      },
      (updatedZone) {
        setState(() {
          _currentZone = updatedZone;
          _isEditing = false;
        });
        widget.onZoneUpdated?.call(updatedZone);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Place customized successfully! ✨'),
            backgroundColor: AppColors.successLight,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final String? currentUserId = authState is Authenticated ? authState.user.id : null;
    final bool isChampion = _currentZone.warlordId == currentUserId; // true = current user is the top diner here

    // Convert hex string to Flutter Color
    Color themeColor = AppColors.getPrimary(context);
    try {
      final hex = _currentZone.customColour.replaceAll('#', '');
      themeColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border(top: BorderSide(color: AppColors.getBorder(context), width: 1.5)),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: _isEditing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: _buildDetailView(isChampion, themeColor),
        secondChild: _buildCustomizeView(themeColor),
      ),
    );
  }

  Widget _buildDetailView(bool isChampion, Color themeColor) {
    final authState = context.read<AuthBloc>().state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top handle
        Center(
          child: Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.getBorder(context),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Header Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentZone.name,
                    style: AppTypography.displayLarge.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.stars, color: themeColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _currentZone.customTitle ?? 'Unclaimed Spot',
                        style: AppTypography.caption.copyWith(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Edit Customization Icon
            if (isChampion)
              IconButton(
                icon: Icon(Icons.palette_outlined, color: themeColor),
                onPressed: () {
                  _triggerHaptic();
                  setState(() => _isEditing = true);
                },
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Warlord Banner (Modern bordered card style)
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _currentZone.warlordId == null
                ? null
                : () {
                    _triggerHaptic();
                    Navigator.pop(context);
                    context.push('/user-profile', extra: {
                      'userId': _currentZone.warlordId!,
                      'previewName': _currentZone.warlordUsername,
                      'previewAvatarUrl': _currentZone.warlordAvatarUrl,
                    });
                  },
            child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar / Icon
                _currentZone.warlordId == null
                    ? Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _currentZone.customIcon == 'hamburger'
                              ? Icons.restaurant
                              : _currentZone.customIcon == 'pizza'
                                  ? Icons.local_pizza
                                  : Icons.lunch_dining,
                          color: themeColor,
                          size: 24,
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isChampion
                              ? AppColors.getSuccess(context).withAlpha(30)
                              : themeColor.withAlpha(20),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isChampion ? AppColors.getSuccess(context) : themeColor,
                            width: 2.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            // First letter of the warlord's username as avatar
                            (_currentZone.warlordUsername ?? 'W')[0].toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppTypography.headingFont,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: isChampion ? AppColors.getSuccess(context) : themeColor,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentZone.warlordId == null
                            ? 'UNCLAIMED SPOT 🍽️'
                            : isChampion
                                ? 'YOUR PLACE 👑'
                                : 'CLAIMED BY SOMEONE 🏆',
                        style: AppTypography.caption.copyWith(
                          color: _currentZone.warlordId == null
                              ? AppColors.getOnSurfaceMuted(context)
                              : isChampion
                                  ? AppColors.getSuccess(context)
                                  : themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentZone.warlordId == null
                            ? 'Be the first to dine here!'
                            : isChampion
                                ? (authState is Authenticated
                                    ? (authState.user.displayName ?? authState.user.username)
                                    : 'YOU')
                                : (_currentZone.warlordUsername ?? 'Food Champion'),
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_currentZone.warlordId != null) ...
                        [
                          const SizedBox(height: 4),
                          Text(
                            '${_currentZone.warlordRaids} visits • ${_currentZone.totalRaids} total raids',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.getOnSurfaceMuted(context),
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
        ),

        const SizedBox(height: 20),

        // Statistics Grid
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                '🍽️ Total Visits',
                _currentZone.totalRaids == 0 ? 'Never visited' : '${_currentZone.totalRaids} visits',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                '👑 Champion Visits',
                _currentZone.warlordRaids == 0 ? 'Unclaimed' : '${_currentZone.warlordRaids} visits',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // View full place detail screen
        OutlinedButton.icon(
          onPressed: () {
            _triggerHaptic();
            Navigator.pop(context);
            context.push('/place-detail', extra: _currentZone);
          },
          icon: const Icon(Icons.info_outline_rounded, size: 18),
          label: const Text('View Full Details'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: themeColor, width: 1.2),
            foregroundColor: themeColor,
            textStyle: const TextStyle(
              fontFamily: AppTypography.headingFont,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Geofence gate: raiding/capturing is only available when the user is
        // physically standing within range of the zone.
        if (_inRange) ...[
          // CTA RAID Button — text changes based on ownership state
          ElevatedButton(
            onPressed: () {
              _triggerHaptic();
              Navigator.pop(context);
              widget.onRaidStarted?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            child: Text(
              isChampion
                  ? '✅ YOUR PLACE'
                  : _currentZone.warlordId == null
                      ? '🍽️ BE THE FIRST TO CLAIM!'
                      : '🍴 CLAIM THIS SPOT',
              style: const TextStyle(
                fontFamily: AppTypography.headingFont,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (isChampion) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _triggerHaptic();
                Navigator.pop(context);
                widget.onRaidStarted?.call();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: themeColor, width: 1.5),
              ),
              child: Text(
                '🔄 DINE AGAIN',
                style: TextStyle(
                  color: themeColor,
                  fontFamily: AppTypography.headingFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ] else
          _buildProximityLock(),
      ],
    );
  }

  /// Shown when the user is not physically present at the venue.
  /// No distance numbers — the message focuses on being AT the place.
  Widget _buildProximityLock() {
    final muted = AppColors.getOnSurfaceMuted(context);
    final bool noGps = widget.distanceMeters == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(context).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  noGps
                      ? Icons.location_disabled_rounded
                      : Icons.restaurant_rounded,
                  color: AppColors.getPrimary(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noGps
                          ? 'Location access needed'
                          : 'You must be at this place',
                      style: AppTypography.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      noGps
                          ? 'Allow location so we can confirm you are dining at ${_currentZone.name}.'
                          : 'To check in, you need to actually visit and dine at ${_currentZone.name}. Open the app once you\'re there!',
                      style: AppTypography.caption.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock_outline_rounded, size: 18),
            label: Text(
              noGps ? 'ENABLE LOCATION' : 'VISIT TO CHECK IN',
              style: const TextStyle(
                fontFamily: AppTypography.headingFont,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: AppColors.getBorder(context),
              disabledForegroundColor: muted,
              minimumSize: const Size(double.infinity, 52),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariant(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context))),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCustomizeView(Color themeColor) {
    final colours = ['#FFD700', '#E53935', '#EF5350', '#4CAF50', '#2196F3', '#FF9800', '#9C27B0'];
    final icons = ['fork', 'hamburger', 'pizza'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize This Place',
          style: AppTypography.titleLarge.copyWith(color: themeColor),
        ),
        const SizedBox(height: 16),

        // Title Input
        TextFormField(
          controller: _titleController,
          maxLength: 30,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            labelText: 'Custom Title',
            labelStyle: TextStyle(color: AppColors.getOnSurfaceMuted(context)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.getBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: themeColor, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Color Picker Row
        Text('Banner Colour', style: AppTypography.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colours.length,
            itemBuilder: (context, index) {
              final colorHex = colours[index];
              final isSelected = _selectedColour == colorHex;
              Color visualColor = Colors.red;
              try {
                visualColor = Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
              } catch (_) {}

              return GestureDetector(
                onTap: () {
                  _triggerHaptic();
                  setState(() => _selectedColour = colorHex);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: visualColor,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppColors.getOnSurface(context), width: 3)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Icon Picker Row
        Text('Place Icon', style: AppTypography.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: icons.map((iconSlug) {
            final isSelected = _selectedIcon == iconSlug;
            final iconData = iconSlug == 'hamburger'
                ? Icons.restaurant
                : iconSlug == 'pizza'
                    ? Icons.local_pizza
                    : Icons.lunch_dining;

            return GestureDetector(
              onTap: () {
                _triggerHaptic();
                setState(() => _selectedIcon = iconSlug);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isSelected ? themeColor.withAlpha(40) : AppColors.getSurfaceVariant(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? themeColor : AppColors.getBorder(context),
                    width: 1.5,
                  ),
                ),
                child: Icon(iconData, color: isSelected ? themeColor : AppColors.getOnSurface(context)),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Actions Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _triggerHaptic();
                  setState(() => _isEditing = false);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: AppColors.getBorder(context)),
                ),
                child: Text('Cancel', style: TextStyle(color: AppColors.getOnSurface(context))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveCustomization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save ✨', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
