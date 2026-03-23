import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/core/constants/app_constants.dart';
import 'package:Gym/core/network/dio_client.dart';
import 'package:Gym/features/trainee/models/today_workout_model.dart';

final traineeRepositoryProvider = Provider<TraineeRepository>((ref) {
  return TraineeRepository(dio: ref.read(dioProvider));
});

class TraineeRepository {
  final Dio _dio;

  TraineeRepository({required Dio dio}) : _dio = dio;

  /// Get today's workout
  Future<TodayWorkoutModel?> getTodayWorkout() async {
    final response = await _dio.get(AppConstants.todayWorkoutEndpoint);

    // ✅ 204 returns empty string, not null
    if (response.statusCode == 204 ||
        response.data == null ||
        response.data == '' ||
        response.data is! Map) {
      return null;
    }

    return TodayWorkoutModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Log today's workout
  Future<void> logWorkout({
    required String notes,
  }) async {
    await _dio.post(
      AppConstants.logWorkoutEndpoint,
      data: {
        "notes": notes,
        "completedAt": DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}
