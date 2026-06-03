// EatMap Client Exception Hierarchy
// core/error/exceptions.dart

sealed class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException[code=$code]: $message';
}

// ==========================================
// NETWORK EXCEPTIONS
// ==========================================

final class NoInternetException extends AppException {
  const NoInternetException() : super('No internet connection', code: 'NO_INTERNET');
}

final class TimeoutException extends AppException {
  const TimeoutException() : super('Request timed out', code: 'TIMEOUT');
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Session expired', code: 'UNAUTHORIZED');
}

final class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode, String? code})
      : super(code: code ?? 'SERVER_ERROR');
}

// ==========================================
// DOMAIN EXCEPTIONS
// ==========================================

final class GeofenceException extends AppException {
  const GeofenceException() : super('You are too far from this zone', code: 'GEOFENCE');
}

final class RaidCooldownException extends AppException {
  final Duration remaining;
  const RaidCooldownException(this.remaining)
      : super('Cooldown active', code: 'COOLDOWN');
}

final class VerificationException extends AppException {
  const VerificationException(super.message, {String? code})
      : super(code: code ?? 'VERIFICATION_FAILED');
}

final class InsufficientBalanceException extends AppException {
  const InsufficientBalanceException() : super('Minimum ₹100 required', code: 'LOW_BALANCE');
}
