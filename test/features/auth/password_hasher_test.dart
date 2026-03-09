import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/auth/data/password_hasher.dart';

void main() {
  test('PasswordHasher creates verifiable hashes', () {
    const hasher = PasswordHasher();
    final hash = hasher.createHash('SecurePass1');

    expect(
      hasher.verify(
        password: 'SecurePass1',
        hash: hash.hash,
        salt: hash.salt,
      ),
      isTrue,
    );
    expect(
      hasher.verify(
        password: 'WrongPass1',
        hash: hash.hash,
        salt: hash.salt,
      ),
      isFalse,
    );
  });
}
