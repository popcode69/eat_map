import 'package:equatable/equatable.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/entities/zone_raider_entity.dart';

sealed class PlaceDetailState extends Equatable {
  const PlaceDetailState();

  @override
  List<Object?> get props => [];
}

class PlaceDetailInitial extends PlaceDetailState {
  const PlaceDetailInitial();
}

class PlaceDetailLoading extends PlaceDetailState {
  const PlaceDetailLoading();
}

class PlaceDetailLoaded extends PlaceDetailState {
  final ZoneEntity zone;
  final List<ZoneRaiderEntity> raiders;

  const PlaceDetailLoaded({required this.zone, required this.raiders});

  @override
  List<Object?> get props => [zone, raiders];
}

class PlaceDetailError extends PlaceDetailState {
  final String message;

  const PlaceDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
