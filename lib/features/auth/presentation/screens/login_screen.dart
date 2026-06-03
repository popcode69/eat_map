import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/cache/secure_storage.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOtpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    // Generate light haptic tap for interaction feedback (flutter-trd.md §1.4)
    HapticFeedback.lightImpact();
  }

  void _onSubmit() {
    _triggerHaptic();
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (!_isOtpSent) {
      // Simulate sending OTP, then display OTP verification field
      setState(() {
        _isOtpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent to phone successfully! (Mock Verification: 123456)'),
          backgroundColor: AppColors.getSuccess(context),
        ),
      );
    } else {
      // Dispatch SignIn event to Bloc
      context.read<AuthBloc>().add(
            SignInWithPhoneRequested(phone: phone, code: otp),
          );
    }
  }

  Future<void> _routeAfterAuth(BuildContext context) async {
    final seen = await di.sl<SecureStorage>().hasSeenOnboarding();
    if (!context.mounted) return;
    context.go(seen ? '/home' : '/onboarding');
  }

  void _onGoogleSignIn() {
    _triggerHaptic();
    // Dispatch Google Sign-In event
    context.read<AuthBloc>().add(
          const SignInWithGoogleRequested(
            googleId: 'mock_google_id_token',
            deviceToken: 'mock_device_token',
            deviceId: 'mock_device_id',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: BorderSide(color: AppColors.getBorder(context), width: 1.5),
    );

    final focusedBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: BorderSide(color: AppColors.getPrimary(context), width: 2.0),
    );

    final errorBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: BorderSide(color: AppColors.getError(context), width: 1.5),
    );

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Login successful
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome back, ${state.user.username}! ⚔️'),
                backgroundColor: AppColors.getSuccess(context),
              ),
            );
            // First-time raiders see the tutorial; returning ones go to the map.
            _routeAfterAuth(context);
          } else if (state is AuthFailure) {
            // Login failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.getError(context),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Brand / Logo Section (Premium Cyberpunk conquest visual)
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: AppColors.getPrimaryLight(context),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(color: AppColors.getPrimary(context), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.getPrimary(context).withAlpha(40),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              size: 40,
                              color: AppColors.getPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'EatMap',
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.getOnSurface(context),
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'CONQUER ZONES · CLAIM BOUNTIES',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.getPrimary(context),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),

                    // Card Form Wrapper (Flat + bordered card style)
                    Card(
                      color: AppColors.getSurface(context),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isOtpSent ? 'Verify OTP' : 'Raider Authentication',
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.getOnSurface(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isOtpSent
                                  ? 'Enter the 6-digit passcode sent to your device.'
                                  : 'Sign in to sync your points, balance, and claimed zones.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.getOnSurfaceMuted(context),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Phone Field
                            if (!_isOtpSent) ...[
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.getOnSurface(context),
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.phone_android, color: AppColors.getOnSurfaceMuted(context)),
                                  labelText: 'Mobile Number',
                                  hintText: '+91 98765 43210',
                                  labelStyle: TextStyle(color: AppColors.getOnSurfaceMuted(context)),
                                  enabledBorder: borderStyle,
                                  focusedBorder: focusedBorderStyle,
                                  errorBorder: errorBorderStyle,
                                  focusedErrorBorder: errorBorderStyle,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter mobile number';
                                  }
                                  if (value.trim().length < 10) {
                                    return 'Please enter a valid mobile number';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              // OTP Verification Field
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                maxLength: 6,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.getOnSurface(context),
                                  letterSpacing: 6.0,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.getOnSurfaceMuted(context)),
                                  labelText: '6-Digit Passcode',
                                  counterText: '',
                                  labelStyle: TextStyle(color: AppColors.getOnSurfaceMuted(context)),
                                  enabledBorder: borderStyle,
                                  focusedBorder: focusedBorderStyle,
                                  errorBorder: errorBorderStyle,
                                  focusedErrorBorder: errorBorderStyle,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter verification code';
                                  }
                                  if (value.trim().length != 6) {
                                    return 'OTP must be exactly 6 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              // Back button
                              TextButton(
                                onPressed: () {
                                  _triggerHaptic();
                                  setState(() {
                                    _isOtpSent = false;
                                    _otpController.clear();
                                  });
                                },
                                child: Text(
                                  '← Use different phone number',
                                  style: TextStyle(color: AppColors.getPrimary(context)),
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 32),

                            // Submit Button (Interactive primary styling)
                            ElevatedButton(
                              onPressed: isLoading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.getPrimary(context),
                                foregroundColor: AppColors.getOnPrimary(context),
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _isOtpSent ? '⚔️ VERIFY PASSCODE' : '🚀 SEND OTP CODE',
                                      style: const TextStyle(
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
                    
                    const SizedBox(height: 32),

                    // Divider Text
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.getBorder(context))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR SECURELY ACCESS VIA',
                            style: AppTypography.caption.copyWith(color: AppColors.getOnSurfaceMuted(context)),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.getBorder(context))),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Google OAuth Button ( secondary border design standard )
                    OutlinedButton(
                      onPressed: isLoading ? null : _onGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.getBorder(context), width: 1.5),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Custom Icon/Asset Placeholder
                          const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Continue with Google',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.getOnSurface(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Privacy Agreement Label
                    Center(
                      child: Text(
                        'By continuing, you agree to EatMap\'s Terms and Fairplay policy.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.getOnSurfaceMuted(context),
                        ),
                        textAlign: TextAlign.center,
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
