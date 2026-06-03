import 'package:dio/dio.dart';
import '../logger/app_logger.dart';

/// Google Places Nearby Search API wrapper for fetching food/drink POIs.
/// Uses the legacy Nearby Search endpoint which is available on standard API keys.
class PlacesService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  final Dio _dio;
  final String _apiKey;
  final AppLogger _log = AppLogger();

  PlacesService({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ));

  /// Fetch all nearby food & drink places within [radiusMeters] of [lat],[lng].
  /// Covers: restaurant, bar, cafe, lodging (hotels), meal_takeaway.
  /// Returns empty list on failure — caller always gets a result.
  Future<List<Map<String, dynamic>>> fetchNearbyFoodPlaces({
    required double lat,
    required double lng,
    int radiusMeters = 2000,
  }) async {
    final List<Map<String, dynamic>> allPlaces = [];

    // Query each food type separately to maximise coverage
    // Google Places API only allows one 'type' per request
    const types = ['restaurant', 'bar', 'cafe', 'lodging', 'meal_takeaway'];

    for (final type in types) {
      try {
        _log.d('PlacesService: querying type=$type near $lat,$lng');

        final response = await _dio.get(
          _baseUrl,
          queryParameters: {
            'location': '$lat,$lng',
            'radius': radiusMeters,
            'type': type,
            'key': _apiKey,
          },
        );

        final data = response.data as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'UNKNOWN';
        final results = data['results'] as List<dynamic>? ?? [];

        _log.d('PlacesService: type=$type status=$status results=${results.length}');

        if (status == 'REQUEST_DENIED') {
          _log.w('PlacesService: API key missing Places API permission. '
              'Enable "Places API" at console.cloud.google.com.');
          break; // No point retrying other types
        }

        for (final place in results) {
          final map = place as Map<String, dynamic>;
          if (!allPlaces.any((p) => p['place_id'] == map['place_id'])) {
            allPlaces.add(map);
          }
        }
      } catch (e) {
        _log.w('PlacesService: error for type=$type', e);
      }
    }

    _log.d('PlacesService: total unique places fetched: ${allPlaces.length}');
    return allPlaces;
  }
}
