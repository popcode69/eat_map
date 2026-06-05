import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_modals.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../map/presentation/bloc/map_bloc.dart';
import '../bloc/raid_bloc.dart';
import '../bloc/raid_bloc.dart' as bloc_state;

class BillUploadScreen extends StatefulWidget {
  final String raidId;
  final String zoneName;
  final String colour;
  final double? userLat;
  final double? userLng;

  const BillUploadScreen({
    super.key,
    required this.raidId,
    required this.zoneName,
    required this.colour,
    this.userLat,
    this.userLng,
  });

  @override
  State<BillUploadScreen> createState() => _BillUploadScreenState();
}

class _BillUploadScreenState extends State<BillUploadScreen> {
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _billPhotoPath;
  bool _isPhotoSelected = false;

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  Future<void> _pickBill() async {
    _triggerHaptic();
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 72,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _billPhotoPath = picked.path;
      _isPhotoSelected = true;
    });
  }

  Future<void> _pickBillFromGallery() async {
    _triggerHaptic();
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _billPhotoPath = picked.path;
      _isPhotoSelected = true;
    });
  }

  void _onSubmit() {
    _triggerHaptic();
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.00;
    final upi = _upiController.text.trim();

    context.read<RaidBloc>().add(RaidVerificationSubmitted(
          raidId: widget.raidId,
          spendAmount: amount,
          upiRef: upi.isEmpty ? null : upi,
          billPhotoPath: _billPhotoPath,
        ));
  }

  Future<void> _showTakeoverDialog(bloc_state.RaidSuccess successData) async {
    await AppModals.raidResult(
      context,
      points: successData.points,
      rank: successData.rank,
      isWarlord: successData.isWarlord,
      zoneName: widget.zoneName,
    );

    if (!mounted) return;
    // Refresh auth profile stats and reload map zones, then return to the map.
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
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = AppColors.getPrimary(context);
    try {
      themeColor = Color(int.parse('FF${widget.colour.replaceAll('#', '')}', radix: 16));
    } catch (_) {}

    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: BorderSide(color: AppColors.getBorder(context), width: 1.5),
    );

    final focusedBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: BorderSide(color: themeColor, width: 2.0),
    );

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text(
          'Verification Details',
          style: TextStyle(fontFamily: AppTypography.headingFont, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<RaidBloc, RaidState>(
        listener: (context, state) {
          if (state is bloc_state.RaidSuccess) {
            _showTakeoverDialog(state);
          } else if (state is RaidFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.getError(context)),
            );
            context.go('/home');
          }
        },
        builder: (context, state) {
          final isVerifying = state is RaidVerifying;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.zoneName,
                      style: AppTypography.displayLarge.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete Checkout Verification',
                      style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                    ),

                    const SizedBox(height: 32),

                    // Card Form Wrapper
                    Card(
                      color: AppColors.getSurface(context),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Photo Picker Container
                            Text('Receipt Photograph', style: AppTypography.labelLarge),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: isVerifying
                                  ? null
                                  : () => showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (ctx) => Container(
                                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                          decoration: BoxDecoration(
                                            color: AppColors.getSurface(context),
                                            borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(20)),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                  width: 40,
                                                  height: 4,
                                                  margin: const EdgeInsets.only(bottom: 16),
                                                  decoration: BoxDecoration(
                                                      color: AppColors.getBorder(context),
                                                      borderRadius: BorderRadius.circular(2))),
                                              ListTile(
                                                leading: Icon(Icons.camera_alt_outlined,
                                                    color: themeColor),
                                                title: const Text('Take Photo'),
                                                onTap: () {
                                                  Navigator.pop(ctx);
                                                  _pickBill();
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.photo_library_outlined,
                                                    color: themeColor),
                                                title: const Text('Choose from Gallery'),
                                                onTap: () {
                                                  Navigator.pop(ctx);
                                                  _pickBillFromGallery();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _isPhotoSelected
                                      ? AppColors.getSuccess(context).withAlpha(15)
                                      : AppColors.getSurfaceVariant(context),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isPhotoSelected
                                        ? AppColors.getSuccess(context)
                                        : AppColors.getBorder(context),
                                    width: 1.5,
                                    style: _isPhotoSelected ? BorderStyle.solid : BorderStyle.solid,
                                  ),
                                ),
                                child: _isPhotoSelected
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle, color: AppColors.getSuccess(context), size: 40),
                                          const SizedBox(height: 8),
                                          Text(
                                            _billPhotoPath != null
                                                ? _billPhotoPath!.split('/').last
                                                : 'photo attached',
                                            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to change photograph',
                                            style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo_outlined, color: AppColors.getOnSurfaceMuted(context), size: 36),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Upload Receipt Bill',
                                            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'JPEG fallback, compressed by 72%',
                                            style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Spend Amount Form field
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              style: AppTypography.bodyLarge,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.currency_rupee, color: AppColors.getOnSurfaceMuted(context)),
                                labelText: 'Total Spend Amount',
                                hintText: '₹150.00',
                                labelStyle: TextStyle(color: AppColors.getOnSurfaceMuted(context)),
                                enabledBorder: borderStyle,
                                focusedBorder: focusedBorderStyle,
                                errorBorder: borderStyle,
                                focusedErrorBorder: borderStyle,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                    return 'Please enter total spend amount';
                                }
                                final amt = double.tryParse(value.trim());
                                if (amt == null || amt < 50.0) {
                                  return 'Minimum spend required is ₹50';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Optional UPI Reference field
                            TextFormField(
                              controller: _upiController,
                              style: AppTypography.bodyLarge,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.qr_code, color: AppColors.getOnSurfaceMuted(context)),
                                labelText: 'UPI Ref Transaction (Optional)',
                                hintText: 'UPI 123456789012',
                                labelStyle: TextStyle(color: AppColors.getOnSurfaceMuted(context)),
                                enabledBorder: borderStyle,
                                focusedBorder: focusedBorderStyle,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // VERIFY SUBMIT BUTTON
                            ElevatedButton(
                              onPressed: isVerifying ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                              child: isVerifying
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      '⚔️ COMPLETE VERIFICATION',
                                      style: TextStyle(
                                        fontFamily: AppTypography.headingFont,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
