// core/error/error_handler.dart
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {
  static Failure handle(Object error) {
    return switch (error) {
      NoInternetException()    => const NetworkFailure('No internet connection'),
      UnauthorizedException()  => const AuthFailure('Session expired — please log in again'),
      GeofenceException()      => const DomainFailure('You\'re too far from this zone'),
      RaidCooldownException(remaining: final d) =>
          DomainFailure('Come back in ${d.inMinutes} minutes'),
      ServerException(statusCode: final code) when code == 429 =>
          const RateLimitFailure('Too many attempts — slow down'),
      ServerException(message: final msg) => ServerFailure(msg),
      _ => const UnknownFailure('Something went wrong'),
    };
  }
}
