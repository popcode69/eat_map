import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_modals.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/place_request_bloc.dart';
import '../../domain/entities/place_request_entity.dart';

// Available place types the user can choose from
const _kPlaceTypes = [
  _PlaceType('restaurant', '🍽️', 'Restaurant'),
  _PlaceType('cafe', '☕', 'Café'),
  _PlaceType('bar', '🍺', 'Bar / Pub'),
  _PlaceType('dhaba', '🥘', 'Dhaba'),
  _PlaceType('hotel', '🏨', 'Hotel / Resort'),
  _PlaceType('bakery', '🥐', 'Bakery / Dessert'),
  _PlaceType('food_court', '🛒', 'Food Court'),
  _PlaceType('other', '📍', 'Other'),
];

class _PlaceType {
  final String value;
  final String emoji;
  final String label;
  const _PlaceType(this.value, this.emoji, this.label);
}

class RequestPlaceScreen extends StatefulWidget {
  const RequestPlaceScreen({super.key});

  @override
  State<RequestPlaceScreen> createState() => _RequestPlaceScreenState();
}

class _RequestPlaceScreenState extends State<RequestPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  String _selectedType = 'restaurant';
  double? _lat;
  double? _lng;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill city from the user's profile
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _cityCtrl.text = authState.user.city ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Could not get location. Please check permissions.'),
        backgroundColor: AppColors.getError(context),
      ));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _submit() {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;
    context.read<PlaceRequestBloc>().add(
          PlaceRequestSubmitted(
            PlaceRequestEntity(
              name: _nameCtrl.text.trim(),
              placeType: _selectedType,
              address: _addressCtrl.text.trim(),
              city: _cityCtrl.text.trim(),
              lat: _lat,
              lng: _lng,
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              contactNumber: _contactCtrl.text.trim().isEmpty
                  ? null
                  : _contactCtrl.text.trim(),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.getPrimary(context);

    return BlocListener<PlaceRequestBloc, PlaceRequestState>(
      listener: (context, state) {
        if (state is PlaceRequestSuccess) {
          AppModals.info(
            context,
            title: 'Request Sent!',
            message:
                'Thank you! Our team will review "${_nameCtrl.text}" and add it to EatMap soon.',
            buttonLabel: 'Done',
            icon: Icons.check_circle_outline_rounded,
          ).then((_) => context.pop());
        } else if (state is PlaceRequestFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.getError(context),
          ));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        appBar: AppBar(
          title: Text(
            'Suggest a Place',
            style: AppTypography.titleLarge
                .copyWith(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<PlaceRequestBloc, PlaceRequestState>(
          builder: (context, state) {
            final isLoading = state is PlaceRequestLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero banner ─────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary.withValues(alpha: 0.12),
                            primary.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: primary.withValues(alpha: 0.22), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.add_location_alt_rounded,
                                color: primary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Know a great spot?',
                                    style: AppTypography.titleMedium
                                        .copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  'Help grow the EatMap community by suggesting a restaurant, café, or dhaba.',
                                  style: AppTypography.caption.copyWith(
                                      color: AppColors.getOnSurfaceMuted(
                                          context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Place type chips ─────────────────────────────
                    Text('Place Type', style: AppTypography.labelLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kPlaceTypes.map((pt) {
                        final selected = _selectedType == pt.value;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedType = pt.value);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? primary.withValues(alpha: 0.12)
                                  : AppColors.getSurfaceVariant(context),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: selected
                                    ? primary
                                    : AppColors.getBorder(context),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(pt.emoji,
                                    style: const TextStyle(fontSize: 15)),
                                const SizedBox(width: 6),
                                Text(
                                  pt.label,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: selected
                                        ? primary
                                        : AppColors.getOnSurface(context),
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Required fields card ─────────────────────────
                    _SectionCard(
                      title: 'Place Details',
                      icon: Icons.store_rounded,
                      color: primary,
                      children: [
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Place Name',
                          hint: 'e.g. Sharma Ji Ka Dhaba',
                          icon: Icons.restaurant_rounded,
                          required: true,
                          enabled: !isLoading,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Place name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _addressCtrl,
                          label: 'Address',
                          hint: 'Street, Area, Landmark',
                          icon: Icons.location_on_outlined,
                          required: true,
                          enabled: !isLoading,
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Address is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _cityCtrl,
                          label: 'City',
                          hint: 'e.g. Jaipur',
                          icon: Icons.location_city_rounded,
                          required: true,
                          enabled: !isLoading,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'City is required'
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── GPS location card ────────────────────────────
                    _SectionCard(
                      title: 'GPS Location',
                      icon: Icons.my_location_rounded,
                      color: AppColors.getSuccess(context),
                      subtitle: 'Optional but helps us find the place faster',
                      children: [
                        if (_lat != null && _lng != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.getSuccess(context)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.getSuccess(context)
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: AppColors.getSuccess(context),
                                    size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                                    style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.getSuccess(context),
                                        fontFamily: 'monospace'),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() {
                                        _lat = null;
                                        _lng = null;
                                      }),
                                  child: Icon(Icons.close_rounded,
                                      color: AppColors.getOnSurfaceMuted(
                                          context),
                                      size: 18),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'No location set',
                            style: AppTypography.caption.copyWith(
                                color: AppColors.getOnSurfaceMuted(context)),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: (isLoading || _locating)
                                ? null
                                : _detectLocation,
                            icon: _locating
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            AppColors.getSuccess(context)),
                                  )
                                : Icon(Icons.gps_fixed_rounded,
                                    color: AppColors.getSuccess(context)),
                            label: Text(
                              _locating
                                  ? 'Detecting…'
                                  : _lat != null
                                      ? 'Update Location'
                                      : 'Use My Current Location',
                              style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.getSuccess(context)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: AppColors.getSuccess(context)
                                      .withValues(alpha: 0.6)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Optional details card ────────────────────────
                    _SectionCard(
                      title: 'Additional Info',
                      icon: Icons.info_outline_rounded,
                      color: AppColors.getWarning(context),
                      subtitle: 'Optional — helps the admin verify faster',
                      children: [
                        _buildField(
                          controller: _descCtrl,
                          label: 'Description',
                          hint: 'Cuisine type, specialty dish, timings…',
                          icon: Icons.notes_rounded,
                          enabled: !isLoading,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _contactCtrl,
                          label: 'Contact Number',
                          hint: '+91 XXXXX XXXXX',
                          icon: Icons.phone_outlined,
                          enabled: !isLoading,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Submit button ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          isLoading ? 'Sending Request…' : 'SEND REQUEST TO ADMIN',
                          style: const TextStyle(
                            fontFamily: AppTypography.headingFont,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final primary = AppColors.getPrimary(context);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.getOnSurfaceMuted(context)),
        labelStyle:
            TextStyle(color: AppColors.getOnSurfaceMuted(context)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.getError(context), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.getError(context), width: 2),
        ),
        filled: true,
        fillColor: AppColors.getSurface(context),
      ),
      validator: validator,
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.getBorder(context), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: AppTypography.caption.copyWith(
                            color: AppColors.getOnSurfaceMuted(context))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
