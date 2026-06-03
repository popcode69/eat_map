import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../zone/data/repositories/zone_repository_impl.dart';
import '../../../zone/domain/entities/zone_entity.dart';
import '../../../zone/domain/usecases/get_nearby_zones.dart';

// ==========================================
// 1. MAP EVENTS
// ==========================================
sealed class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

final class LoadNearbyZonesRequested extends MapEvent {
  final String geohash;
  final double? lat;
  final double? lng;

  const LoadNearbyZonesRequested(this.geohash, {this.lat, this.lng});

  @override
  List<Object?> get props => [geohash, lat, lng];
}

final class SelectZoneRequested extends MapEvent {
  final ZoneEntity? selectedZone;

  const SelectZoneRequested(this.selectedZone);

  @override
  List<Object?> get props => [selectedZone];
}

// ==========================================
// 2. MAP STATES
// ==========================================
sealed class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

final class MapInitial extends MapState {}

final class MapLoading extends MapState {}

final class MapLoaded extends MapState {
  final List<ZoneEntity> zones;
  final ZoneEntity? selectedZone;

  const MapLoaded({required this.zones, this.selectedZone});

  MapLoaded copyWith({
    List<ZoneEntity>? zones,
    ZoneEntity? selectedZone,
    bool clearSelected = false,
  }) {
    return MapLoaded(
      zones: zones ?? this.zones,
      selectedZone: clearSelected ? null : (selectedZone ?? this.selectedZone),
    );
  }

  @override
  List<Object?> get props => [zones, selectedZone];
}

final class MapFailure extends MapState {
  final String message;

  const MapFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ==========================================
// 3. MAP BLOC
// ==========================================
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetNearbyZones _getNearbyZones;
  final ZoneRepositoryImpl _zoneRepo;
  final AppLogger _log = AppLogger();

  MapBloc({
    required GetNearbyZones getNearbyZones,
    required ZoneRepositoryImpl zoneRepo,
  })  : _getNearbyZones = getNearbyZones,
        _zoneRepo = zoneRepo,
        super(MapInitial()) {
    on<LoadNearbyZonesRequested>(_onLoadNearbyZonesRequested);
    on<SelectZoneRequested>(_onSelectZoneRequested);
  }

  Future<void> _onLoadNearbyZonesRequested(
    LoadNearbyZonesRequested event,
    Emitter<MapState> emit,
  ) async {
    _log.d('MapBloc: LoadNearbyZonesRequested lat=${event.lat} lng=${event.lng}');
    final currentSelected =
        state is MapLoaded ? (state as MapLoaded).selectedZone : null;
    emit(MapLoading());

    // If we have real coordinates, use Google Places to get ALL food/drink POIs
    if (event.lat != null && event.lng != null) {
      try {
        final zones = await _zoneRepo.getNearbyFoodPlaces(
          lat: event.lat!,
          lng: event.lng!,
        );
        _log.d('MapBloc: getNearbyFoodPlaces returned ${zones.length} POIs');
        emit(MapLoaded(zones: zones, selectedZone: currentSelected));
        return;
      } catch (e) {
        _log.w('MapBloc: getNearbyFoodPlaces failed — falling back to geohash', e);
      }
    }

    // Fallback: geohash-based zone fetch
    final result = await _getNearbyZones(geohash: event.geohash);
    result.fold(
      (failure) {
        _log.w('MapBloc: GetNearbyZones failed: ${failure.message}');
        emit(MapFailure(failure.message));
      },
      (zones) {
        _log.d('MapBloc: GetNearbyZones succeeded with ${zones.length} zones.');
        emit(MapLoaded(zones: zones, selectedZone: currentSelected));
      },
    );
  }

  void _onSelectZoneRequested(
    SelectZoneRequested event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(
        selectedZone: event.selectedZone,
        clearSelected: event.selectedZone == null,
      ));
    }
  }
}
