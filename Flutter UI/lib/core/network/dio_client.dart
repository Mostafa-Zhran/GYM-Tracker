import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Gym/core/constants/app_constants.dart';
import 'package:Gym/core/network/jwt_interceptor.dart';

// Provider for FlutterSecureStorage instance
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// Provider for the configured Dio instance
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 60), // ✅ increase from 15s
    receiveTimeout: const Duration(seconds: 60), // ✅ add this too
    sendTimeout: const Duration(seconds: 60), // ✅ add this too
    validateStatus: (status) =>
        status != null && status < 500, // ✅ 204 won't throw

    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Attach JWT interceptor to every request
  dio.interceptors.add(JwtInterceptor(storage));

  // Log requests in debug mode
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ),
  );

  return dio;
});
