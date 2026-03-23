import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:Gym/core/widgets/gym_shell.dart';
import 'package:Gym/features/auth/providers/auth_provider.dart';
import 'package:Gym/features/auth/screens/login_page.dart';
import 'package:Gym/features/auth/screens/register_page.dart';

import 'package:Gym/features/coach/screens/assign_workout_screen.dart';
import 'package:Gym/features/coach/screens/trainees_list_screen.dart';
import 'package:Gym/features/coach/models/trainee_model.dart';

import 'package:Gym/features/trainee/screens/today_workout_screen.dart';
import 'package:Gym/features/trainee/screens/log_workout_screen.dart';

import 'package:Gym/features/chat/screens/chat_screen.dart';
import 'package:Gym/features/coach_selection/coach_selection.dart';
import 'package:Gym/core/constants/app_constants.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String selectCoach = '/select-coach';
  static const String coachHome = '/coach';
  static const String assignWorkout = '/coach/assign-workout';
  static const String traineeHome = '/trainee';
  static const String logWorkout = '/trainee/log-workout';
  static const String chat = '/chat';
  // coachProfile & traineeProfile removed — add back when ready
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final currentPath = state.matchedLocation;
      final onLogin = currentPath == AppRoutes.login;
      final onRegister = currentPath == AppRoutes.register;
      final onSelectCoach = currentPath == AppRoutes.selectCoach;

      // Public pages — no auth needed
      if (onRegister || onSelectCoach) return null;

      if (!isLoggedIn && !onLogin) return AppRoutes.login;

      if (isLoggedIn && onLogin) {
        return authState.role == AppConstants.coachRole
            ? AppRoutes.coachHome
            : AppRoutes.traineeHome;
      }

      return null;
    },
    routes: [
      // ── Auth ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const GymLoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const GymRegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.selectCoach,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CoachSelectionPage(
            traineeId: extra['traineeId'] as String,
            traineeName: extra['traineeName'] as String,
          );
        },
      ),

      // ── Coach routes ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.coachHome,
        builder: (_, __) => const CoachShell(
          currentIndex: 0,
          child: TraineesListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.assignWorkout,
        builder: (_, state) => CoachShell(
          currentIndex: 1,
          child: AssignWorkoutScreen(
            preSelectedTrainee: state.extra as TraineeModel?,
          ),
        ),
      ),

      // ── Trainee routes ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.traineeHome,
        builder: (_, __) => const TraineeShell(
          currentIndex: 0,
          child: TodayWorkoutScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.logWorkout,
        builder: (_, state) => TraineeShell(
          currentIndex: 0,
          child: LogWorkoutScreen(
            workoutId: state.extra as String?,
          ),
        ),
      ),

      // ── Chat ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.chat,
        builder: (_, state) => ChatScreen(
          args: state.extra as ChatArgs,
        ),
      ),
    ],
  );
});

// ── ChatArgs ──────────────────────────────────────────────────────────────

class ChatArgs {
  final String otherUserId;
  final String otherUserName;

  const ChatArgs({
    required this.otherUserId,
    required this.otherUserName,
  });
}
