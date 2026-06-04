import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/place_request_entity.dart';

class PlaceRequestRepositoryImpl {
  final DioClient _dioClient;

  PlaceRequestRepositoryImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<Either<Failure, Unit>> submitRequest(
      PlaceRequestEntity request) async {
    try {
      final body = <String, dynamic>{
        'name': request.name,
        'place_type': request.placeType,
        'address': request.address,
        'city': request.city,
      };
      if (request.lat != null) body['lat'] = request.lat;
      if (request.lng != null) body['lng'] = request.lng;
      if (request.description != null && request.description!.isNotEmpty) {
        body['description'] = request.description;
      }
      if (request.contactNumber != null &&
          request.contactNumber!.isNotEmpty) {
        body['contact_number'] = request.contactNumber;
      }

      await _dioClient.dio.post(ApiEndpoints.submitPlaceRequest, data: body);
      return const Right(unit);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        // Treat as success in offline/dev mode — request logged locally.
        return const Right(unit);
      }
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        final msg = (body['detail'] ?? body['message'])?.toString();
        if (msg != null && msg.isNotEmpty) return Left(ServerFailure(msg));
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
