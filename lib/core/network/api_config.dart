/// Centralized network configuration.
///
/// Keeping base URL and timeouts in one place makes it trivial to switch
/// environments (dev / staging / prod) and to reason about the offline-dev
/// fallback behaviour driven by [DioClient].
class ApiConfig {
  ApiConfig._();

  /// Backend base URL. All paths in [ApiEndpoints] are relative to this.
  static const String baseUrl = 'https://dev.gixbot.online/api/v1';

  /// Localhost for the Android emulator — handy when running the FastAPI
  /// server locally. Swap [baseUrl] for this during local development.
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';

  // ── Timeouts ────────────────────────────────────────────────────────
  // Kept deliberately short so the offline-dev fallback (mock data) kicks in
  // quickly when the backend is unreachable, while still tolerating a slow
  // first response. Upload calls get a longer [sendTimeout].
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Retry policy ────────────────────────────────────────────────────
  static const int maxRetries = 2;
  static const List<Duration> retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  /// Sentinel token meaning "offline-dev mode": repositories return mock data
  /// instead of hitting the network when this is the stored auth token.
  static const String mockToken = 'local_mock_token';
}
