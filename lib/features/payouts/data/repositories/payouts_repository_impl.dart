import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/warlord_estimate_entity.dart';
import '../../domain/repositories/payouts_repository.dart';
import '../models/warlord_estimate_model.dart';

class PayoutsRepositoryImpl implements PayoutsRepository {
  final DioClient _dioClient;

  PayoutsRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Either<Failure, WarlordEstimateEntity>> getWarlordEstimate() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.warlordEstimate);
      final estimate =
          WarlordEstimateModel.fromJson(response.data as Map<String, dynamic>);
      return Right(estimate);
    } on DioException catch (e) {
      // Offline → return an empty projection so the card can render gracefully.
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        return const Right(WarlordEstimateModel(
          period: '',
          myShares: 0.0,
          totalShares: 0.0,
          pool: 0.0,
          projectedInr: 0.0,
        ));
      }
      return Left(ErrorHandler.handle(e.error ?? e));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
