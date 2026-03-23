import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gym/features/auth/data/auth_repository.dart';
import 'package:Gym/features/auth/models/user_model.dart';
import 'package:Gym/features/chat/data/chat_signalr_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => user != null;
  String? get role => user?.role;
  String? get userId => user?.id;
  String? get userName => user?.name;
  String? get coachId => user?.coachId;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref; // ✅ عشان نوصل للـ SignalR

  AuthNotifier(this._repository, this._ref) : super(const AuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await _repository.getStoredUser();
      state = user != null ? AuthState(user: user) : const AuthState();
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final user = await _repository.login(email: email, password: password);
      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    // ✅ قطع SignalR قبل ما تمسح البيانات
    try {
      final signalR = _ref.read(chatSignalRServiceProvider);
      await signalR.disconnect();
    } catch (_) {}

    await _repository.logout();
    state = const AuthState();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref); // ✅ مرر ref
});
