import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {}

final class SignInWithPhoneRequested extends AuthEvent {
  final String phone;
  final String code;

  const SignInWithPhoneRequested({required this.phone, required this.code});

  @override
  List<Object?> get props => [phone, code];
}

final class SignInWithGoogleRequested extends AuthEvent {
  final String googleId;
  final String deviceToken;
  final String deviceId;

  const SignInWithGoogleRequested({
    required this.googleId,
    required this.deviceToken,
    required this.deviceId,
  });

  @override
  List<Object?> get props => [googleId, deviceToken, deviceId];
}

final class SignOutRequested extends AuthEvent {}

final class UploadAvatarRequested extends AuthEvent {
  final String filePath;

  const UploadAvatarRequested({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

final class UpdateLocationRequested extends AuthEvent {
  final double lat;
  final double lng;

  const UpdateLocationRequested({required this.lat, required this.lng});

  @override
  List<Object?> get props => [lat, lng];
}

final class UpdateProfileRequested extends AuthEvent {
  final String? username;
  final String? displayName;
  final String? city;
  final String? avatarUrl;

  const UpdateProfileRequested({
    this.username,
    this.displayName,
    this.city,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [username, displayName, city, avatarUrl];
}
