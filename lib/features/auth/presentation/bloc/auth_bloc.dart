import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in_google.dart';
import '../../domain/usecases/sign_in_phone.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/update_location.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/upload_avatar.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser _getCurrentUser;
  final SignInWithPhone _signInWithPhone;
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;
  final UploadAvatar _uploadAvatar;
  final UpdateLocation _updateLocation;
  final UpdateProfile _updateProfile;

  AuthBloc({
    required GetCurrentUser getCurrentUser,
    required SignInWithPhone signInWithPhone,
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
    required UploadAvatar uploadAvatar,
    required UpdateLocation updateLocation,
    required UpdateProfile updateProfile,
  })  : _getCurrentUser = getCurrentUser,
        _signInWithPhone = signInWithPhone,
        _signInWithGoogle = signInWithGoogle,
        _signOut = signOut,
        _uploadAvatar = uploadAvatar,
        _updateLocation = updateLocation,
        _updateProfile = updateProfile,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithPhoneRequested>(_onSignInWithPhoneRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<UploadAvatarRequested>(_onUploadAvatarRequested);
    on<UpdateLocationRequested>(_onUpdateLocationRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _getCurrentUser();
    result.fold(
      (_) => emit(Unauthenticated()),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignInWithPhoneRequested(
    SignInWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signInWithPhone(phone: event.phone, code: event.code);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signInWithGoogle(
      googleId: event.googleId,
      deviceToken: event.deviceToken,
      deviceId: event.deviceId,
    );
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signOut();
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onUpdateLocationRequested(
    UpdateLocationRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) return;
    // Fire-and-forget: location update doesn't affect auth state
    await _updateLocation(lat: event.lat, lng: event.lng);
  }

  Future<void> _onUploadAvatarRequested(
    UploadAvatarRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) return;
    final currentUser = (state as Authenticated).user;
    final result = await _uploadAvatar(filePath: event.filePath);
    result.fold(
      (failure) => emit(AvatarUploadFailure(user: currentUser, message: failure.message)),
      (updatedUser) => emit(Authenticated(updatedUser)),
    );
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) return;
    final currentUser = (state as Authenticated).user;
    final result = await _updateProfile(
      username: event.username,
      displayName: event.displayName,
      city: event.city,
      avatarUrl: event.avatarUrl,
    );
    result.fold(
      (failure) => emit(ProfileUpdateFailure(user: currentUser, message: failure.message)),
      (updatedUser) => emit(Authenticated(updatedUser)),
    );
  }
}
