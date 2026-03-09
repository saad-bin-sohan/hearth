import 'package:hearth/features/auth/domain/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signUp({
    required String email,
    required String password,
  });

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  });

  Future<AppUser?> getUserById(String userId);
}
