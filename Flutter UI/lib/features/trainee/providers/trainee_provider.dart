import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/features/trainee/data/trainee_repository.dart';
import 'package:Gym/features/trainee/models/today_workout_model.dart';

/// ── Today Workout Provider ─────────────────────────────────────────────

final todayWorkoutProvider = FutureProvider<TodayWorkoutModel?>((ref) async {
  final repo = ref.read(traineeRepositoryProvider);
  return repo.getTodayWorkout();
});

/// ── Log Workout State ──────────────────────────────────────────────────

class LogWorkoutState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const LogWorkoutState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  LogWorkoutState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return LogWorkoutState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ── Log Workout Notifier ───────────────────────────────────────────────

class LogWorkoutNotifier extends StateNotifier<LogWorkoutState> {
  final TraineeRepository _repository;

  LogWorkoutNotifier(this._repository) : super(const LogWorkoutState());

  Future<void> logWorkout({
    required String notes,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      isSuccess: false,
    );

    try {
      await _repository.logWorkout(
        notes: notes,
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

/// ── Provider ───────────────────────────────────────────────────────────

final logWorkoutProvider =
    StateNotifierProvider<LogWorkoutNotifier, LogWorkoutState>((ref) {
  return LogWorkoutNotifier(ref.read(traineeRepositoryProvider));
});
