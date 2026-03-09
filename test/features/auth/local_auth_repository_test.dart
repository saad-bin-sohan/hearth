import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/auth/data/local_auth_repository.dart';
import 'package:hearth/features/auth/data/password_hasher.dart';
import 'package:uuid/uuid.dart';

import '../../test_helpers.dart';

void main() {
  test('LocalAuthRepository signs up, signs in, and resets passwords', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    final repository = LocalAuthRepository(
      database: database,
      passwordHasher: const PasswordHasher(),
      uuid: const Uuid(),
    );

    final user = await repository.signUp(
      email: 'test@example.com',
      password: 'SecurePass1',
    );

    final signedIn = await repository.signIn(
      email: 'test@example.com',
      password: 'SecurePass1',
    );

    expect(signedIn.id, user.id);

    await repository.resetPassword(
      email: 'test@example.com',
      newPassword: 'NewPass123',
    );

    final resetUser = await repository.signIn(
      email: 'test@example.com',
      password: 'NewPass123',
    );

    expect(resetUser.email, 'test@example.com');
  });
}
