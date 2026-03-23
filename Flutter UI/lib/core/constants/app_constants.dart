class AppConstants {
  AppConstants._();

  // ───────────────── Base URL ─────────────────
  static const String baseUrl = 'https://gymfluterapi.runasp.net';

  // ───────────────── Auth ─────────────────
  static const String loginEndpoint = '/api/Account/Login';
  static const String registerEndpoint = '/api/Account/Register/User';
  static const String coachesEndpoint =
      '/api/Account/Coahes'; // typo is intentional — matches backend
  static const String linkCoachEndpoint = '/assign-coach';
  // your POST link endpoint
  // ───────────────── Coach APIs ─────────────────
  static const String traineesEndpoint = '/trainees';
  static const String assignWorkoutEndpoint = '/assign';

  // ───────────────── Trainee APIs ─────────────────
  static const String todayWorkoutEndpoint = '/today';
  static const String logWorkoutEndpoint = '/log';

  // ───────────────── Chat ─────────────────
  static const String chatHistoryEndpoint = '/history';
  static const String chatSeenEndpoint = '/seen';

  // ── SignalR ───────────────────────────────────────────────────────────────
  static const String signalRHubUrl = 'https://gymfluterapi.runasp.net/chatHub';

  // ───────────────── Storage Keys ─────────────────
  static const String tokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String coachIdKey = 'coach_id';

  // ───────────────── Roles ─────────────────
  static const String coachRole = 'Coach';
  static const String traineeRole = 'Trainee';
}
