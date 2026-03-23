import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Gym/core/constants/app_constants.dart';
import 'package:Gym/core/network/dio_client.dart';
import 'package:Gym/features/auth/models/user_model.dart';
import 'package:Gym/features/coach_selection/models/coach_model.dart';
import 'package:Gym/features/trainee/models/today_workout_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.read(dioProvider),
    storage: ref.read(secureStorageProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  // ── LOGIN ─────────────────────────────────────────────────────────────────

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint("🔵 [AUTH] Sending login request...");

      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      debugPrint("🟢 [AUTH] Response received");

      final user = UserModel.fromJson(response.data as Map<String, dynamic>);

      debugPrint('🟢 [AUTH] Login success. userId: ${user.id}');
      debugPrint('🟢 [AUTH] CoachId: ${user.coachId ?? "null"}');

      // ✅ Store all user data including coachId
      await _storage.write(key: AppConstants.tokenKey, value: user.token);
      await _storage.write(key: AppConstants.userIdKey, value: user.id);
      await _storage.write(key: AppConstants.userRoleKey, value: user.role);
      await _storage.write(key: AppConstants.userNameKey, value: user.name);
      await _storage.write(
          key: AppConstants.coachIdKey, value: user.coachId ?? ''); // ✅

      debugPrint('🟢 [AUTH] All data written to storage');

      return user;
    } catch (e) {
      debugPrint("🔴 [AUTH] Login error: $e");
      rethrow;
    }
  }

  // ── REGISTER ──────────────────────────────────────────────────────────────

  Future<void> register({
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    try {
      await _dio.post(
        AppConstants.registerEndpoint,
        data: {
          'userName': userName,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'role': role,
        },
      );
      debugPrint("🟢 [AUTH] Register success");
    } catch (e) {
      debugPrint("🔴 [AUTH] Register error: $e");
      rethrow;
    }
  }

  // ── GET COACHES ───────────────────────────────────────────────────────────

  Future<List<CoachModel>> getCoaches() async {
    try {
      final response = await _dio.get(AppConstants.coachesEndpoint);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => CoachModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("🔴 [AUTH] Get coaches error: $e");
      rethrow;
    }
  }

  // ── LINK TRAINEE → COACH ──────────────────────────────────────────────────

  Future<void> linkTraineeToCoach({
    required String traineeId,
    required String coachId,
  }) async {
    try {
      await _dio.post(
        AppConstants.linkCoachEndpoint,
        data: {'coachId': coachId},
      );
      debugPrint("🟢 [AUTH] Trainee linked to coach");
    } catch (e) {
      debugPrint("🔴 [AUTH] Link coach error: $e");
      rethrow;
    }
  }

  // ── TODAY WORKOUT ─────────────────────────────────────────────────────────

  Future<TodayWorkoutModel?> getTodayWorkout() async {
    final response = await _dio.get(AppConstants.todayWorkoutEndpoint);
    if (response.statusCode == 204 ||
        response.data == null ||
        response.data == '' ||
        response.data is! Map) {
      return null;
    }
    return TodayWorkoutModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── LOG WORKOUT ───────────────────────────────────────────────────────────

  Future<void> logWorkout({required String notes}) async {
    try {
      await _dio.post(
        AppConstants.logWorkoutEndpoint,
        data: {
          'completedAt': DateTime.now().toIso8601String(),
          'notes': notes,
        },
      );
      debugPrint("🟢 Workout logged");
    } catch (e) {
      debugPrint("🔴 Log workout error: $e");
      rethrow;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.deleteAll();
    debugPrint("🟢 [AUTH] User logged out");
  }

  // ── RESTORE SESSION ───────────────────────────────────────────────────────

  Future<UserModel?> getStoredUser() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return null;

    final id = await _storage.read(key: AppConstants.userIdKey);
    final role = await _storage.read(key: AppConstants.userRoleKey);
    final name = await _storage.read(key: AppConstants.userNameKey);
    final coachId = await _storage.read(key: AppConstants.coachIdKey); // ✅

    if (id == null || role == null || name == null) return null;

    return UserModel(
      id: id,
      name: name,
      email: '',
      role: role,
      token: token,
      coachId: coachId?.isEmpty == true ? null : coachId, // ✅
    );
  }
}
