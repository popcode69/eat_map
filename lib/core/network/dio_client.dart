import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../cache/secure_storage.dart';
import '../connectivity/connectivity_cubit.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import 'connectivity_interceptor.dart';

class DioClient {
  late final Dio _dio;

  Dio get dio => _dio;

  DioClient({
    required SecureStorage secureStorage,
    required ConnectivityCubit connectivityCubit,
    String? baseUrl,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      ConnectivityInterceptor(connectivityCubit: connectivityCubit),
      AuthInterceptor(secureStorage: secureStorage),

      // Smart retry policy for server recoveries
      RetryInterceptor(
        dio: _dio,
        retries: ApiConfig.maxRetries,
        retryDelays: ApiConfig.retryDelays,
      ),
      
      // Beautiful console logger for HTTP cycles
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);
  }
}
