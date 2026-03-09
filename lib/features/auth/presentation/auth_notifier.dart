import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/features/auth/data/local_auth_repository.dart';
import 'package:hearth/features/auth/domain/app_user.dart';
import 'package:uuid/uuid.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

class AuthState {
  const AuthState({required this.status, this.user, this.message});

  final AuthStatus status;
  final AppUser? user;
  final String? message;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref)
    : super(const AuthState(status: AuthStatus.unauthenticated));

  final Ref ref;
  final Uuid _uuid = const Uuid();

  Future<void> hydrate() async {
    final session = ref.read(sessionControllerProvider);
    if (!session.hasSession || session.userId == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final user = await ref
        .read(authRepositoryProvider)
        .getUserById(session.userId!);
    state = user == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      await ref
          .read(sessionControllerProvider.notifier)
          .saveSession(authToken: _uuid.v4(), userId: user.id);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on StateError catch (error) {
      state = AuthState(status: AuthStatus.error, message: error.message);
    }
  }

  Future<void> signOut() async {
    await ref.read(sessionControllerProvider.notifier).clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password);
      await ref
          .read(sessionControllerProvider.notifier)
          .saveSession(authToken: _uuid.v4(), userId: user.id);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on StateError catch (error) {
      state = AuthState(status: AuthStatus.error, message: error.message);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      state = const AuthState(status: AuthStatus.unauthenticated);
    } on StateError catch (error) {
      state = AuthState(status: AuthStatus.error, message: error.message);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(email: email, newPassword: newPassword);
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        message: 'Password updated. Sign in with your new password.',
      );
    } on StateError catch (error) {
      state = AuthState(status: AuthStatus.error, message: error.message);
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  Ref ref,
) {
  return AuthNotifier(ref);
});
