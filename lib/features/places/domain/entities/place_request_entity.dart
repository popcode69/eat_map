import 'package:equatable/equatable.dart';

class PlaceRequestEntity extends Equatable {
  final String name;
  final String placeType;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final String? description;
  final String? contactNumber;

  const PlaceRequestEntity({
    required this.name,
    required this.placeType,
    required this.address,
    required this.city,
    this.lat,
    this.lng,
    this.description,
    this.contactNumber,
  });

  @override
  List<Object?> get props =>
      [name, placeType, address, city, lat, lng, description, contactNumber];
}
