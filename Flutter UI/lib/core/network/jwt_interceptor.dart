import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Gym/core/constants/app_constants.dart';

class JwtInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  JwtInterceptor(this.storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // ✅ متضيفش توكن على Login
    if (options.path.contains("/api/Account/Login")) {
      return handler.next(options);
    }

    try {
      final token = await storage.read(key: AppConstants.tokenKey);

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // لو حصل أي خطأ كمل الريكوست عادي
    }

    handler.next(options);
  }
}
