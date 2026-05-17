import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({this.user, this.isLoading = false, this.error, this.isAuthenticated = false});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool? isAuthenticated}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(isLoading: true);
    final isAuthResult = await _repository.isAuthenticated();
    await isAuthResult.fold(
      (_) async => state = const AuthState(),
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

  Future<bool> adminLogin(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.adminLogin(username, password);
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

  Future<String?> register({
    required String username,
    required String displayName,
    required String password,
    required String academicId,
    required String role,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.register(
      username: username,
      displayName: displayName,
      password: password,
      academicId: academicId,
      role: role,
      email: email,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return null;
      },
      (message) {
        state = state.copyWith(isLoading: false);
        return message;
      },
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) => ref.watch(authProvider).user);
