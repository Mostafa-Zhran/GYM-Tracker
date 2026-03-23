import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/core/constants/app_constants.dart';
import 'package:Gym/core/network/dio_client.dart';
import 'package:Gym/features/coach/models/trainee_model.dart';

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepository(dio: ref.read(dioProvider));
});

class CoachRepository {
  final Dio _dio;

  CoachRepository({required Dio dio}) : _dio = dio;

  /// Fetch all trainees assigned to this coach
  Future<List<TraineeModel>> getTrainees() async {
    final response = await _dio.get(AppConstants.traineesEndpoint);
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => TraineeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Assign a workout to a specific trainee
  Future<void> assignWorkout({
    required String traineeId,
    required String title,
    required String description,
    required DateTime date,
  }) async {
    await _dio.post(
      AppConstants.assignWorkoutEndpoint,
      data: {
        'traineeId': traineeId,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
      },
    );
  }
}
