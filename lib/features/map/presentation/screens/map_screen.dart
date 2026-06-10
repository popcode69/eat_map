import 'dart:async';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/cache/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/map_legend_overlay.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_modals.dart';
import '../../../shell/presentation/screens/main_shell.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../zone/domain/entities/zone_entity.dart';
import '../../../raid/presentation/bloc/raid_bloc.dart' show RaidBloc, RaidResumeRequested;
import '../bloc/map_bloc.dart';
import '../bloc/map_bloc.dart' as bloc_state;
import '../../../zone/presentation/widgets/zone_detail_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLocationPermissionGranted = false;
  Map<String, BitmapDescriptor> _markerIcons = {};
  bool _isGeneratingMarkers = false;
  bool _showLegend = false;

  // ─────────────────────────────────────────────────────────────────
  // MARKER GENERATORS
  // ─────────────────────────────────────────────────────────────────

  /// Loads a network image as a [ui.Image]. Returns null on failure/timeout.
  Future<ui.Image?> _loadNetworkImage(String url) async {
    try {
      final completer = Completer<ui.Image?>();
      final stream = NetworkImage(url).resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          stream.removeListener(listener);
          completer.complete(info.image);
        },
        onError: (_, __) {
          stream.removeListener(listener);
          completer.complete(null);
        },
      );
      stream.addListener(listener);
      return await completer.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  /// Generates a premium captured-zone marker with avatar or initials.
  ///
  /// When [isCrown] is true the marker denotes the locality's top Warlord —
  /// it gets a gold ring and a crown perched on top of the medallion.
  Future<BitmapDescriptor> _generateCapturedMarker({
    required Color accentColor,
    required bool isMyZone,
    required String ownerInitial,
    String? avatarUrl,
    bool isCrown = false,
  }) async {
    ui.Image? avatarImg;
    if (avatarUrl != null) {
      avatarImg = await _loadNetworkImage(avatarUrl);
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // ~60 % of the old 130×158 canvas
    const double W = 80.0;
    const double H = 96.0;
    const Offset center = Offset(40, 38);
    const double outerR = 30.0;
    const double innerR = 26.0;
    const double avatarR = 22.0;
    const Color gold = Color(0xFFFFD700);
    final Color ringColor = accentColor;

    // 1. Drop shadow
    canvas.drawCircle(
      Offset(center.dx, center.dy + 4),
      outerR,
      Paint()
        ..color = Colors.black.withOpacity(0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 2. Colored outer glow
    canvas.drawCircle(
      center,
      outerR + 4,
      Paint()
        ..color = ringColor.withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 3. White separator ring
    canvas.drawCircle(center, outerR, Paint()..color = Colors.white.withOpacity(0.95));

    // 4. Accent color ring
    canvas.drawCircle(center, outerR - 3, Paint()..color = ringColor);

    // 5. Dark radial-gradient background
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          innerR,
          [const Color(0xFF1C1C2E), const Color(0xFF0A0A14)],
          [0.0, 1.0],
        ),
    );

    // 6. Avatar photo or initial letter
    if (avatarImg != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: avatarR)));
      canvas.drawImageRect(
        avatarImg,
        Rect.fromLTWH(0, 0, avatarImg.width.toDouble(), avatarImg.height.toDouble()),
        Rect.fromCircle(center: center, radius: avatarR),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
      canvas.drawCircle(
        center,
        avatarR,
        Paint()
          ..color = ringColor.withOpacity(0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      final tp = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: ownerInitial.toUpperCase(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isMyZone ? gold : Colors.white,
            shadows: [Shadow(color: ringColor.withOpacity(0.7), blurRadius: 8)],
          ),
        )
        ..layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }

    // 7. Pin tail — circle bottom is at center.dy + outerR = 68
    final tailPath = Path()
      ..moveTo(40, 94)
      ..lineTo(28, 68)
      ..lineTo(52, 68)
      ..close();
    canvas.drawPath(
      tailPath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(40, 68),
          const Offset(40, 94),
          [ringColor, ringColor.withOpacity(0.0)],
        ),
    );

    // 8. Crown for the locality's top Warlord
    if (isCrown) {
      final crownTp = TextPainter(textDirection: TextDirection.ltr)
        ..text = const TextSpan(
          text: '👑',
          style: TextStyle(fontSize: 18),
        )
        ..layout();
      crownTp.paint(canvas, Offset(center.dx - crownTp.width / 2, -2));
    }

    final image = await recorder.endRecording().toImage(W.toInt(), H.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Clean minimal green marker for uncaptured zones — no food icon, no badge.
  /// Just the coloured pin so the map stays uncluttered.
  Future<BitmapDescriptor> _generateUncapturedMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // ~64 % of the previous 56×72 canvas
    const double W = 36.0;
    const double H = 46.0;
    const Offset center = Offset(18, 18);
    const double outerR = 17.0;
    const Color green = Color(0xFF00C853);
    const Color greenLight = Color(0xFFB9F6CA);

    // 1. Soft drop-shadow
    canvas.drawCircle(
      Offset(center.dx, center.dy + 3),
      outerR - 2,
      Paint()
        ..color = Colors.black.withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2. Outer green circle
    canvas.drawCircle(center, outerR, Paint()..color = green);

    // 3. White inner halo ring
    canvas.drawCircle(center, outerR - 4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // 4. Centre dot — circle bottom is at center.dy + outerR = 35
    canvas.drawCircle(center, 4, Paint()..color = greenLight);

    // 5. Pin tail
    final tail = Path()
      ..moveTo(18, 44)
      ..lineTo(11, 35)
      ..lineTo(25, 35)
      ..close();
    canvas.drawPath(
      tail,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(18, 35),
          const Offset(18, 44),
          [green, green.withOpacity(0.0)],
        ),
    );

    final image = await recorder.endRecording().toImage(W.toInt(), H.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<void> _generateAllMarkers(
      List<ZoneEntity> zones, String? currentUserId, String? currentUserAvatarUrl) async {
    if (_isGeneratingMarkers) return;
    _isGeneratingMarkers = true;

    final Map<String, BitmapDescriptor> tempIcons = {};

    // Locality's top Warlord = the captured zone with the most total raids.
    // Gets a crowned marker (PRD §5.1). Needs at least one raid to qualify.
    String? topWarlordZoneId;
    int topRaids = 0;
    for (final zone in zones) {
      if (zone.warlordId != null && zone.totalRaids > topRaids) {
        topRaids = zone.totalRaids;
        topWarlordZoneId = zone.id;
      }
    }

    for (final zone in zones) {
      try {
        if (zone.warlordId != null) {
          // ── CAPTURED marker ──────────────────────────────────────
          final isMyZone = zone.warlordId == currentUserId;

          // Task 3: enemy strongholds are always RED; the user's own zones
          // default to YELLOW but honour the colour picked in customization.
          Color accentColor;
          if (isMyZone) {
            accentColor = const Color(0xFFFFD700); // default yellow
            try {
              final hex = zone.customColour.replaceAll('#', '');
              accentColor = Color(int.parse('FF$hex', radix: 16));
            } catch (_) {}
          } else {
            accentColor = const Color(0xFFE53935); // enemy red
          }

          final ownerInitial =
              (zone.warlordUsername ?? zone.warlordId ?? 'W')[0];

          // For the current user's zone, prefer the up-to-date auth avatar
          final avatarUrl = isMyZone
              ? (currentUserAvatarUrl ?? zone.warlordAvatarUrl)
              : zone.warlordAvatarUrl;

          tempIcons[zone.id] = await _generateCapturedMarker(
            accentColor: accentColor,
            isMyZone: isMyZone,
            ownerInitial: ownerInitial,
            avatarUrl: avatarUrl,
            isCrown: zone.id == topWarlordZoneId,
          );
        } else {
          // ── UNCAPTURED — clean green pin, no food icon
          tempIcons[zone.id] = await _generateUncapturedMarker();
        }
      } catch (_) {
        // Skip on canvas error — fallback pin will be used
      }
    }

    if (mounted) {
      setState(() {
        _markerIcons = tempIcons;
        _isGeneratingMarkers = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    context.read<MapBloc>().add(const LoadNearbyZonesRequested('te7u6b'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeRaidIfActive();
      _maybeShowLegend();
    });
  }

  Future<void> _maybeShowLegend() async {
    final seen = await SecureStorage().hasSeenMapLegend();
    if (!seen && mounted) setState(() => _showLegend = true);
  }

  Future<void> _dismissLegend() async {
    await SecureStorage().setMapLegendSeen();
    if (mounted) setState(() => _showLegend = false);
  }

  Future<void> _resumeRaidIfActive() async {
    final raid = await SecureStorage().getActiveRaid();
    if (raid == null || !mounted) return;

    final raidId = raid['raidId'] as String;
    final zoneId = raid['zoneId'] as String;
    final zoneName = raid['zoneName'] as String? ?? 'Unknown Place';
    final colour = raid['colour'] as String? ?? '#E53935';
    final status = raid['status'] as String? ?? 'running';
    final durationMins = (raid['durationMins'] as num?)?.toInt() ?? 5;

    // How much time (if any) is left on the timer.
    final startedAt = DateTime.tryParse(raid['startedAt'] as String? ?? '');
    final remaining = startedAt == null
        ? 0
        : startedAt
            .add(Duration(minutes: durationMins))
            .difference(DateTime.now())
            .inSeconds;

    // Verification is presence-only and runs automatically when the timer hits
    // zero — there is no bill-upload step anymore. If the timer already
    // finished (flagged awaiting_verification, or it elapsed while the app was
    // killed), resume at 0s so it completes and auto-verifies through the
    // normal RaidTimerScreen flow.
    final secondsRemaining =
        (status == 'awaiting_verification' || remaining <= 0) ? 0 : remaining;

    if (!mounted) return;
    context.read<RaidBloc>().add(RaidResumeRequested(
          raidId: raidId,
          zoneId: zoneId,
          secondsRemaining: secondsRemaining,
          totalSeconds: durationMins * 60,
        ));
    context.push('/raid-timer', extra: {
      'zoneId': zoneId,
      'zoneName': zoneName,
      'colour': colour,
      'userLat': _currentPosition?.latitude,
      'userLng': _currentPosition?.longitude,
    });
  }

  Future<void> _getUserLocation() async {
    // 1. Location service check
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      final shouldEnable = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Required'),
          content: const Text(
            'Location services are off. Enable them to see zones near you.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      if (shouldEnable == true) {
        await Geolocator.openLocationSettings();
        // Re-check after user returns from settings
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }
      if (!serviceEnabled) {
        if (mounted) setState(() => _currentPosition = const LatLng(26.9124, 75.7873));
        return;
      }
    }

    // 2. Permission check
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _currentPosition = const LatLng(26.9124, 75.7873));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            'Location permission is permanently denied. Open app settings to enable it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (mounted) setState(() => _currentPosition = const LatLng(26.9124, 75.7873));
      return;
    }

    if (mounted) setState(() => _isLocationPermissionGranted = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _currentPosition = latLng);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 15.5)),
      );

      if (mounted) {
        context.read<AuthBloc>().add(UpdateLocationRequested(
              lat: position.latitude,
              lng: position.longitude,
            ));
        context.read<MapBloc>().add(LoadNearbyZonesRequested(
              'te7u6b',
              lat: position.latitude,
              lng: position.longitude,
            ));
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────
  // INTERACTION
  // ─────────────────────────────────────────────────────────────────

  void _triggerHaptic() => HapticFeedback.lightImpact();

  void _onZoneTapped(ZoneEntity zone) {
    _triggerHaptic();
    context.read<MapBloc>().add(SelectZoneRequested(zone));

    // Distance between the raider and the zone — drives the geofence gate that
    // only lets users raid/capture a place they are physically standing at.
    final double? distanceMeters = _currentPosition == null
        ? null
        : Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            zone.lat,
            zone.lng,
          );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ZoneDetailSheet(
        zone: zone,
        distanceMeters: distanceMeters,
        onRaidStarted: () {
          context.push('/raid-timer', extra: {
            'zoneId': zone.id,
            'zoneName': zone.name,
            'colour': zone.customColour,
            'userLat': _currentPosition?.latitude,
            'userLng': _currentPosition?.longitude,
          });
        },
        onZoneUpdated: (updatedZone) {
          if (_currentPosition != null) {
            context.read<MapBloc>().add(LoadNearbyZonesRequested(
                  'te7u6b',
                  lat: _currentPosition!.latitude,
                  lng: _currentPosition!.longitude,
                ));
          } else {
            context
                .read<MapBloc>()
                .add(const LoadNearbyZonesRequested('te7u6b'));
          }
        },
      ),
    ).whenComplete(
        () => context.read<MapBloc>().add(const SelectZoneRequested(null)));
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final String username =
        authState is Authenticated ? authState.user.username : 'Raider';
    final double balance =
        authState is Authenticated ? authState.user.walletBalance : 0.00;
    final int points =
        authState is Authenticated ? authState.user.totalPoints : 0;
    final String? currentUserId =
        authState is Authenticated ? authState.user.id : null;
    final String? currentUserAvatarUrl =
        authState is Authenticated ? authState.user.avatarUrl : null;

    return Stack(
      children: [
      Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: AppColors.getBackground(context),
      body: Stack(
        children: [
          _buildMapCanvas(currentUserId, currentUserAvatarUrl),
          _buildFloatingHeader(username, points, balance),
          _buildFloatingLegend(),
        ],
      ),
    ),
      if (_showLegend) MapLegendOverlay(onDismiss: _dismissLegend),
    ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // MARKERS
  // ─────────────────────────────────────────────────────────────────

  /// Snapchat-style soft halo drawn beneath the user's own zone markers.
  /// Colour follows the self-marker colour (yellow by default, or the user's
  /// chosen customization colour).
  Set<Circle> _buildSelfGlowCircles(
      List<ZoneEntity> zones, String? currentUserId) {
    final circles = <Circle>{};
    for (final zone in zones) {
      final isMyZone =
          zone.warlordId != null && zone.warlordId == currentUserId;
      if (!isMyZone) continue;

      Color glow = const Color(0xFFFFD700); // default yellow
      try {
        final hex = zone.customColour.replaceAll('#', '');
        glow = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}

      circles.add(Circle(
        circleId: CircleId('glow_${zone.id}'),
        center: LatLng(zone.lat, zone.lng),
        radius: 30, // metres — a gentle aura around the pin
        fillColor: glow.withOpacity(0.16),
        strokeColor: glow.withOpacity(0.40),
        strokeWidth: 1,
      ));
    }
    return circles;
  }

  Set<Marker> _buildMarkers(List<ZoneEntity> zones, String? currentUserId) {
    return zones.map((zone) {
      final BitmapDescriptor? icon = _markerIcons[zone.id];
      final bool isCaptured = zone.warlordId != null;
      final bool isMyZone = isCaptured && zone.warlordId == currentUserId;

      // Fallback hue while custom markers are generating
      final double hue = isMyZone
          ? BitmapDescriptor.hueYellow
          : isCaptured
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueGreen;

      return Marker(
        markerId: MarkerId(zone.id),
        position: LatLng(zone.lat, zone.lng),
        icon: icon ?? BitmapDescriptor.defaultMarkerWithHue(hue),
        consumeTapEvents: true,
        onTap: () => _onZoneTapped(zone),
      );
    }).toSet();
  }

  // ─────────────────────────────────────────────────────────────────
  // MAP CANVAS
  // ─────────────────────────────────────────────────────────────────

  Widget _buildMapCanvas(String? currentUserId, String? currentUserAvatarUrl) {
    return BlocConsumer<MapBloc, MapState>(
      listener: (context, state) {
        if (state is bloc_state.MapLoaded) {
          _isGeneratingMarkers = false;
          _generateAllMarkers(state.zones, currentUserId, currentUserAvatarUrl);
        }
      },
      builder: (context, state) {
        // Always render the GoogleMap — never replace it with a full-screen
        // spinner or blank container. Zones/markers update in place once loaded.
        final zones =
            state is bloc_state.MapLoaded ? state.zones : <ZoneEntity>[];
        final isLoading = state is MapLoading;
        final hasError = state is MapFailure;

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? const LatLng(26.9124, 75.7873),
                zoom: 14.5,
              ),
              markers: _buildMarkers(zones, currentUserId),
              circles: _buildSelfGlowCircles(zones, currentUserId),
              mapType: MapType.normal,
              myLocationEnabled: _isLocationPermissionGranted,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (_currentPosition != null) {
                  controller.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(target: _currentPosition!, zoom: 15.5),
                  ));
                }
              },
            ),

            // Small floating pill — only shown while zones are loading
            if (isLoading)
              Positioned(
                top: MediaQuery.of(context).padding.top + 72,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            color: AppColors.getPrimary(context),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Finding zones…',
                          style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Slim error banner — stays below the header
            if (hasError)
              Positioned(
                top: MediaQuery.of(context).padding.top + 72,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.getError(context).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Could not load zones — showing cached data',
                          style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HEADER & LEGEND
  // ─────────────────────────────────────────────────────────────────

  Widget _buildFloatingHeader(String username, int points, double balance) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              _triggerHaptic();
              _scaffoldKey.currentState?.openDrawer();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.getBorder(context), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.menu, color: AppColors.getOnSurface(context)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.getBorder(context), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.military_tech,
                    color: AppColors.getWarning(context), size: 20),
                const SizedBox(width: 4),
                Text('$points PTS',
                    style: AppTypography.labelLarge
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(
                    width: 1.5,
                    height: 16,
                    color: AppColors.getBorder(context)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _triggerHaptic();
                    MainShell.of(context)?.goToTab(ShellTab.wallet);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: AppColors.getSuccess(context), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '₹${balance.toStringAsFixed(0)}',
                        style: AppTypography.labelLarge.copyWith(
                            color: AppColors.getSuccess(context),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLegend() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(context), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(
                const Color(0xFF00E676), Icons.restaurant_outlined, 'Open'),
            _buildLegendItem(
                AppColors.getPrimary(context), Icons.shield_rounded, 'Enemy'),
            _buildLegendItem(
                const Color(0xFFFFD700), Icons.star_rounded, 'Mine'),
            _buildLegendCrown('King'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: AppTypography.caption
                .copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    );
  }

  /// Legend chip for the locality's top Warlord — uses the crown emoji to
  /// match the crowned map marker.
  Widget _buildLegendCrown(String text) {
    const Color gold = Color(0xFFFFD700);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: gold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('👑', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: AppTypography.caption
                .copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // DRAWER
  // ─────────────────────────────────────────────────────────────────

  static const List<String> _levelTitles = [
    'Taster', 'Regular', 'Explorer', 'Zone Warlord',
    'Food Baron', 'City Legend', 'Nation Chief',
  ];

  Widget _buildDrawer() {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final displayName = user?.displayName ?? user?.username ?? 'Raider';
    final username = user?.username ?? 'raider';
    final avatarUrl = user?.avatarUrl;
    final level = user?.level ?? 1;
    final points = user?.totalPoints ?? 0;
    final balance = user?.walletBalance ?? 0.0;
    final levelTitle = level >= 1 && level <= _levelTitles.length
        ? _levelTitles[level - 1]
        : 'Nation Chief';

    return Drawer(
      width: 300,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Container(
          color: AppColors.getBackground(context),
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────────
              _buildDrawerHeader(
                  displayName, username, avatarUrl, level, levelTitle, points, balance),

              // ── NAV ITEMS ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('NAVIGATE'),
                      const SizedBox(height: 6),
                      _buildNavRow(
                        icon: Icons.map_rounded,
                        label: 'Tactical Map',
                        subtitle: 'Conquer zones near you',
                        color: AppColors.getPrimary(context),
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildNavRow(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Wallet & Earnings',
                        subtitle: '₹${balance.toStringAsFixed(0)} available',
                        color: AppColors.getSuccess(context),
                        onTap: () {
                          Navigator.pop(context);
                          MainShell.of(context)?.goToTab(ShellTab.wallet);
                        },
                      ),
                      _buildNavRow(
                        icon: Icons.leaderboard_rounded,
                        label: 'City Rankings',
                        subtitle: 'See who rules the city',
                        color: AppColors.getWarning(context),
                        onTap: () {
                          Navigator.pop(context);
                          MainShell.of(context)?.goToTab(ShellTab.ranks);
                        },
                      ),
                      _buildNavRow(
                        icon: Icons.person_rounded,
                        label: 'Raider Profile',
                        subtitle: 'Lv.$level — $levelTitle',
                        color: const Color(0xFF7C4DFF),
                        onTap: () {
                          Navigator.pop(context);
                          MainShell.of(context)?.goToTab(ShellTab.profile);
                        },
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.getBorder(context), height: 1),
                      const SizedBox(height: 16),
                      _buildSectionLabel('DISCOVER'),
                      const SizedBox(height: 6),
                      _buildNavRow(
                        icon: Icons.notifications_rounded,
                        label: 'Notifications',
                        subtitle: 'Raids, rewards & alerts',
                        color: const Color(0xFF00BCD4),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/notifications');
                        },
                      ),
                      _buildNavRow(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Food Passport',
                        subtitle: 'Your conquest history',
                        color: const Color(0xFFFF6F00),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/profile/passport');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── FOOTER ──────────────────────────────────────────
              _buildDrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    String displayName,
    String username,
    String? avatarUrl,
    int level,
    String levelTitle,
    int points,
    double balance,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFE53935), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar + name ──────────────────────────────────
              Row(
                children: [
                  // Avatar with white ring
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _drawerAvatarPlaceholder(),
                              errorWidget: (_, __, ___) =>
                                  _drawerAvatarPlaceholder(),
                            )
                          : _drawerAvatarPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1),
                          ),
                          child: Text(
                            '⚔️  Lv.$level · $levelTitle',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Stats row ──────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildStatChip('⚔️', '$points', 'Points')),
                    Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.3)),
                    Expanded(
                        child: _buildStatChip(
                            '💰', '₹${balance.toStringAsFixed(0)}', 'Balance')),
                    Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.3)),
                    Expanded(child: _buildStatChip('🛡️', '5', 'Zones')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerAvatarPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
    );
  }

  Widget _buildStatChip(String emoji, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelLarge
              .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppTypography.labelSmall
              .copyWith(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.getOnSurfaceMuted(context),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: color.withValues(alpha: 0.08),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                            color: AppColors.getOnSurfaceMuted(context)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.getOnSurfaceMuted(context), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        children: [
          Divider(color: AppColors.getBorder(context), height: 1),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out'),
              onPressed: () async {
                _triggerHaptic();
                final confirmed = await AppModals.confirm(
                  context,
                  title: 'Stand down, Raider?',
                  message:
                      'You will be signed out and your strongholds left undefended.',
                  confirmLabel: 'Sign Out',
                  cancelLabel: 'Stay',
                  icon: Icons.logout_rounded,
                  destructive: true,
                );
                if (!confirmed || !mounted) return;
                context.read<AuthBloc>().add(SignOutRequested());
                context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.getError(context),
                side: BorderSide(
                    color: AppColors.getError(context).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'EatMap v1.0.0',
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.getOnSurfaceMuted(context)),
          ),
        ],
      ),
    );
  }
}
