import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/core/utils/extensions.dart';
import 'package:hearth/features/auth/data/password_hasher.dart';
import 'package:hearth/features/auth/data/tables.dart';
import 'package:hearth/features/auth/domain/app_user.dart';
import 'package:hearth/features/auth/domain/auth_repository.dart';
import 'package:uuid/uuid.dart';

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return LocalAuthRepository(
    database: ref.read(appDatabaseProvider),
    passwordHasher: const PasswordHasher(),
    uuid: const Uuid(),
  );
});

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required AppDatabase database,
    required PasswordHasher passwordHasher,
    required Uuid uuid,
  }) : _database = database,
       _passwordHasher = passwordHasher,
       _uuid = uuid;

  final AppDatabase _database;
  final PasswordHasher _passwordHasher;
  final Uuid _uuid;

  @override
  Future<AppUser?> getUserById(String userId) async {
    final user = await (_database.select(
      _database.users,
    )..where((Users row) => row.id.equals(userId))).getSingleOrNull();
    return user == null ? null : _mapUser(user);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    final existing = await (_database.select(
      _database.users,
    )..where((Users row) => row.email.equals(normalized))).getSingleOrNull();
    if (existing == null) {
      throw StateError('No account exists for that email.');
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final normalized = email.trim().toLowerCase();
    final user = await (_database.select(
      _database.users,
    )..where((Users row) => row.email.equals(normalized))).getSingleOrNull();
    if (user == null) {
      throw StateError('No account exists for that email.');
    }

    final passwordHash = _passwordHasher.createHash(newPassword);
    await (_database.update(
      _database.users,
    )..where((Users row) => row.id.equals(user.id))).write(
      UsersCompanion(
        passwordHash: Value<String>(passwordHash.hash),
        passwordSalt: Value<String>(passwordHash.salt),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final user = await (_database.select(
      _database.users,
    )..where((Users row) => row.email.equals(normalized))).getSingleOrNull();
    if (user == null) {
      throw StateError('No account exists for that email.');
    }

    final isValid = _passwordHasher.verify(
      password: password,
      hash: user.passwordHash,
      salt: user.passwordSalt,
    );
    if (!isValid) {
      throw StateError('Incorrect password.');
    }

    return _mapUser(user);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final existing = await (_database.select(
      _database.users,
    )..where((Users row) => row.email.equals(normalized))).getSingleOrNull();
    if (existing != null) {
      throw StateError('An account with that email already exists.');
    }

    final now = DateTime.now();
    final hash = _passwordHasher.createHash(password);
    final id = _uuid.v4();
    final displayName = normalized.split('@').first.titleCase;

    await _database
        .into(_database.users)
        .insert(
          UsersCompanion.insert(
            id: id,
            email: normalized,
            displayName: displayName,
            passwordHash: hash.hash,
            passwordSalt: hash.salt,
            createdAt: now,
            updatedAt: now,
          ),
        );

    return AppUser(
      id: id,
      email: normalized,
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );
  }

  AppUser _mapUser(User user) {
    return AppUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
}
