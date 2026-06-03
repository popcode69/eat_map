import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cache/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  AuthInterceptor({required SecureStorage secureStorage})
      : _secureStorage = secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      String? token;

      // 1. First attempt to fetch active session token from Supabase client
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        token = session.accessToken;
      }

      // 2. Fallback to local secure storage if Supabase session is not initialized
      token ??= await _secureStorage.getToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Fail silently to avoid blocking requests if Supabase has not been initialized
    }
    
    handler.next(options);
  }
}
