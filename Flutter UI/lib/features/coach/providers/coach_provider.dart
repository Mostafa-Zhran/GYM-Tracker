import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/features/coach/data/coach_repository.dart';
import 'package:Gym/features/coach/models/trainee_model.dart';

// ── Trainees List Provider ─────────────────────────────────────────────────

/// Async provider that fetches the list of trainees
final traineesProvider = FutureProvider<List<TraineeModel>>((ref) async {
  return ref.read(coachRepositoryProvider).getTrainees();
});

// ── Assign Workout State ───────────────────────────────────────────────────

class AssignWorkoutState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const AssignWorkoutState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  AssignWorkoutState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return AssignWorkoutState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AssignWorkoutNotifier extends StateNotifier<AssignWorkoutState> {
  final CoachRepository _repository;

  AssignWorkoutNotifier(this._repository) : super(const AssignWorkoutState());

  Future<void> assign({
    required String traineeId,
    required String title,
    required String description,
    required DateTime date,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);
    try {
      await _repository.assignWorkout(
        traineeId: traineeId,
        title: title,
        description: description,
        date: date,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const AssignWorkoutState();
}

final assignWorkoutProvider =
    StateNotifierProvider<AssignWorkoutNotifier, AssignWorkoutState>((ref) {
  return AssignWorkoutNotifier(ref.read(coachRepositoryProvider));
});
