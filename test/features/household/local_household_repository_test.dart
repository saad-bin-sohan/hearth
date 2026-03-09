import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/auth/data/local_auth_repository.dart';
import 'package:hearth/features/auth/data/password_hasher.dart';
import 'package:hearth/features/household/data/local_household_repository.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:uuid/uuid.dart';

import '../../test_helpers.dart';

void main() {
  test('Household repository enforces unique invite and last admin protection', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    final authRepository = LocalAuthRepository(
      database: database,
      passwordHasher: const PasswordHasher(),
      uuid: const Uuid(),
    );
    final householdRepository = LocalHouseholdRepository(
      database: database,
      uuid: const Uuid(),
    );

    final owner = await authRepository.signUp(
      email: 'owner@example.com',
      password: 'SecurePass1',
    );
    final member = await authRepository.signUp(
      email: 'member@example.com',
      password: 'SecurePass1',
    );

    final household = await householdRepository.createHousehold(
      userId: owner.id,
      name: 'Hearth Home',
      emoji: '🏡',
      avatarColorKey: 'terracotta',
      currencyCode: 'USD',
    );

    await householdRepository.joinHousehold(
      userId: member.id,
      inviteCode: household.inviteCode,
    );

    final preview = await householdRepository.previewInvite(household.inviteCode);
    expect(preview.memberCount, 2);

    await expectLater(
      () => householdRepository.updateRole(
        actingUserId: owner.id,
        householdId: household.id,
        memberUserId: owner.id,
        role: HouseholdRole.member,
      ),
      throwsA(isA<StateError>()),
    );

    await householdRepository.updateRole(
      actingUserId: owner.id,
      householdId: household.id,
      memberUserId: member.id,
      role: HouseholdRole.observer,
    );

    final members = await householdRepository.getMembers(household.id);
    expect(
      members.singleWhere((HouseholdMember person) => person.userId == member.id).role,
      HouseholdRole.observer,
    );
  });
}
