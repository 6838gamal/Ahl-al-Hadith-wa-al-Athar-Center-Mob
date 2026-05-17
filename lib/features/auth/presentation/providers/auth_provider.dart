import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';

// ─── Repository Provider ──────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl());

// ─── Auth State ───────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({this.user, this.isLoading = false, this.error, this.isAuthenticated = false});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool? isAuthenticated}) => AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

// ─── Auth Notifier ────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.isAuthenticated();
    result.fold(
      (_) => state = const AuthState(),
      (isAuth) async {
        if (isAuth) {
          final userResult = await _repository.getCurrentUser();
          userResult.fold(
            (_) => state = const AuthState(),
            (user) => state = AuthState(user: user, isAuthenticated: true),
          );
        } else {
          state = const AuthState();
        }
      },
    );
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.login(username, password);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) {
        state = AuthState(user: user, isAuthenticated: true);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) => ref.watch(authProvider).user);
