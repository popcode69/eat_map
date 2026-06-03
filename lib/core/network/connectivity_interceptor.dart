import 'package:dio/dio.dart';
import '../connectivity/connectivity_cubit.dart';
import '../error/exceptions.dart';

class ConnectivityInterceptor extends Interceptor {
  final ConnectivityCubit _connectivityCubit;

  ConnectivityInterceptor({required ConnectivityCubit connectivityCubit})
      : _connectivityCubit = connectivityCubit;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_connectivityCubit.state == ConnectivityState.offline) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: const NoInternetException(),
          type: DioExceptionType.connectionError,
        ),
      );
    }
    handler.next(options);
  }
}
