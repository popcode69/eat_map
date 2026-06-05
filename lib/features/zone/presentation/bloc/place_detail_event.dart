import 'package:equatable/equatable.dart';

sealed class PlaceDetailEvent extends Equatable {
  const PlaceDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadZoneRaiders extends PlaceDetailEvent {
  final String zoneId;

  const LoadZoneRaiders(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}
