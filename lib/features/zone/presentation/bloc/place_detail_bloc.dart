import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/entities/zone_raider_entity.dart';
import '../../domain/usecases/get_zone_detail.dart';
import '../../domain/usecases/get_zone_raiders.dart';
import 'place_detail_event.dart';
import 'place_detail_state.dart';

class PlaceDetailBloc extends Bloc<PlaceDetailEvent, PlaceDetailState> {
  final GetZoneDetail _getZoneDetail;
  final GetZoneRaiders _getZoneRaiders;

  PlaceDetailBloc({
    required GetZoneDetail getZoneDetail,
    required GetZoneRaiders getZoneRaiders,
  })  : _getZoneDetail = getZoneDetail,
        _getZoneRaiders = getZoneRaiders,
        super(const PlaceDetailInitial()) {
    on<LoadZoneRaiders>(_onLoad);
  }

  Future<void> _onLoad(
    LoadZoneRaiders event,
    Emitter<PlaceDetailState> emit,
  ) async {
    emit(const PlaceDetailLoading());

    // Start both requests concurrently, then await each typed result.
    final Future<Either<Failure, ZoneEntity>> zoneFuture =
        _getZoneDetail(zoneId: event.zoneId);
    final Future<Either<Failure, List<ZoneRaiderEntity>>> raidersFuture =
        _getZoneRaiders(zoneId: event.zoneId);

    final Either<Failure, ZoneEntity> zoneResult = await zoneFuture;
    final Either<Failure, List<ZoneRaiderEntity>> raidersResult =
        await raidersFuture;

    zoneResult.fold(
      (failure) => emit(PlaceDetailError(failure.message)),
      (zone) => raidersResult.fold(
        (_) => emit(PlaceDetailLoaded(zone: zone, raiders: const [])),
        (raiders) => emit(PlaceDetailLoaded(zone: zone, raiders: raiders)),
      ),
    );
  }
}
