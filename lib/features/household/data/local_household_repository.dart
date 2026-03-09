import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/household/data/tables.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/domain/household_repository.dart';
import 'package:uuid/uuid.dart';

final householdRepositoryProvider = Provider<HouseholdRepository>((Ref ref) {
  return LocalHouseholdRepository(
    database: ref.read(appDatabaseProvider),
    uuid: const Uuid(),
  );
});

class LocalHouseholdRepository implements HouseholdRepository {
  LocalHouseholdRepository({required AppDatabase database, required Uuid uuid})
    : _database = database,
      _uuid = uuid;

  final AppDatabase _database;
  final Uuid _uuid;
  final Random _random = Random.secure();

  static const List<String> _alphabet = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  @override
  Future<String> buildInviteShareText(String householdId) async {
    final household = await getHouseholdById(householdId);
    if (household == null) {
      throw StateError('Household not found.');
    }
    return 'Join ${household.name} on Hearth with invite code ${household.inviteCode}.';
  }

  @override
  Future<HouseholdEntity> createHousehold({
    required String userId,
    required String name,
    required String emoji,
    required String avatarColorKey,
    required String currencyCode,
  }) async {
    final now = DateTime.now();
    final householdId = _uuid.v4();
    final inviteCode = await _generateInviteCode();

    await _database.transaction(() async {
      await _database
          .into(_database.households)
          .insert(
            HouseholdsCompanion.insert(
              id: householdId,
              name: name.trim(),
              emoji: emoji,
              avatarColorKey: avatarColorKey,
              currencyCode: currencyCode,
              inviteCode: inviteCode,
              createdByUserId: userId,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _database
          .into(_database.householdMemberships)
          .insert(
            HouseholdMembershipsCompanion.insert(
              id: _uuid.v4(),
              householdId: householdId,
              userId: userId,
              role: HouseholdRole.admin.name,
              joinedAt: now,
            ),
          );
    });

    return HouseholdEntity(
      id: householdId,
      name: name.trim(),
      emoji: emoji,
      avatarColorKey: avatarColorKey,
      currencyCode: currencyCode,
      inviteCode: inviteCode,
      createdByUserId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<HouseholdEntity?> getHouseholdById(String householdId) async {
    final household = await (_database.select(
      _database.households,
    )..where((Households row) => row.id.equals(householdId))).getSingleOrNull();
    return household == null ? null : _mapHousehold(household);
  }

  @override
  Future<HouseholdEntity?> getHouseholdForUser(String userId) async {
    final membership =
        await (_database.select(_database.householdMemberships)
              ..where((HouseholdMemberships row) => row.userId.equals(userId)))
            .getSingleOrNull();
    if (membership == null) {
      return null;
    }
    return getHouseholdById(membership.householdId);
  }

  @override
  Future<List<HouseholdMember>> getMembers(String householdId) async {
    final query = _database.select(_database.householdMemberships).join([
      innerJoin(
        _database.users,
        _database.users.id.equalsExp(_database.householdMemberships.userId),
      ),
    ])..where(_database.householdMemberships.householdId.equals(householdId));

    final rows = await query.get();
    final members =
        rows.map((TypedResult row) {
          final membership = row.readTable(_database.householdMemberships);
          final user = row.readTable(_database.users);
          return HouseholdMember(
            membershipId: membership.id,
            userId: user.id,
            displayName: user.displayName,
            email: user.email,
            role: HouseholdRole.values.firstWhere(
              (HouseholdRole role) => role.name == membership.role,
            ),
            joinedAt: membership.joinedAt,
          );
        }).toList()..sort(
          (HouseholdMember left, HouseholdMember right) =>
              left.joinedAt.compareTo(right.joinedAt),
        );
    return members;
  }

  @override
  Future<HouseholdEntity> joinHousehold({
    required String userId,
    required String inviteCode,
  }) async {
    final normalized = inviteCode.trim().toUpperCase();
    final household =
        await (_database.select(_database.households)
              ..where((Households row) => row.inviteCode.equals(normalized)))
            .getSingleOrNull();
    if (household == null) {
      throw StateError('That invite code could not be found.');
    }

    final existing =
        await (_database.select(_database.householdMemberships)..where(
              (HouseholdMemberships row) =>
                  row.householdId.equals(household.id) &
                  row.userId.equals(userId),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await _database
          .into(_database.householdMemberships)
          .insert(
            HouseholdMembershipsCompanion.insert(
              id: _uuid.v4(),
              householdId: household.id,
              userId: userId,
              role: HouseholdRole.member.name,
              joinedAt: DateTime.now(),
            ),
          );
    }

    return _mapHousehold(household);
  }

  @override
  Future<HouseholdInvitePreview> previewInvite(String inviteCode) async {
    final normalized = inviteCode.trim().toUpperCase();
    final household =
        await (_database.select(_database.households)
              ..where((Households row) => row.inviteCode.equals(normalized)))
            .getSingleOrNull();
    if (household == null) {
      throw StateError('That invite code could not be found.');
    }

    final memberCount =
        await (_database.selectOnly(_database.householdMemberships)
              ..addColumns(<Expression<Object>>[
                _database.householdMemberships.id.count(),
              ])
              ..where(
                _database.householdMemberships.householdId.equals(household.id),
              ))
            .map(
              (TypedResult row) =>
                  row.read(_database.householdMemberships.id.count()) ?? 0,
            )
            .getSingle();

    return HouseholdInvitePreview(
      household: _mapHousehold(household),
      memberCount: memberCount,
    );
  }

  @override
  Future<void> removeMember({
    required String actingUserId,
    required String householdId,
    required String memberUserId,
  }) async {
    await _assertCanManage(
      actingUserId: actingUserId,
      householdId: householdId,
    );
    final targetMembership = await _membershipFor(householdId, memberUserId);
    if (targetMembership == null) {
      throw StateError('Member not found.');
    }
    if (targetMembership.role == HouseholdRole.admin.name) {
      final admins = await _adminCount(householdId);
      if (admins <= 1) {
        throw StateError('At least one admin must remain in the household.');
      }
    }

    await (_database.delete(_database.householdMemberships)..where(
          (HouseholdMemberships row) => row.id.equals(targetMembership.id),
        ))
        .go();
  }

  @override
  Future<void> updateRole({
    required String actingUserId,
    required String householdId,
    required String memberUserId,
    required HouseholdRole role,
  }) async {
    await _assertCanManage(
      actingUserId: actingUserId,
      householdId: householdId,
    );
    final targetMembership = await _membershipFor(householdId, memberUserId);
    if (targetMembership == null) {
      throw StateError('Member not found.');
    }
    if (targetMembership.userId == actingUserId &&
        targetMembership.role == HouseholdRole.admin.name &&
        role != HouseholdRole.admin) {
      final admins = await _adminCount(householdId);
      if (admins <= 1) {
        throw StateError('At least one admin must remain in the household.');
      }
    }

    await (_database.update(_database.householdMemberships)..where(
          (HouseholdMemberships row) => row.id.equals(targetMembership.id),
        ))
        .write(HouseholdMembershipsCompanion(role: Value<String>(role.name)));
  }

  Future<void> _assertCanManage({
    required String actingUserId,
    required String householdId,
  }) async {
    final actingMembership = await _membershipFor(householdId, actingUserId);
    if (actingMembership == null ||
        actingMembership.role != HouseholdRole.admin.name) {
      throw StateError('Only admins can manage members.');
    }
  }

  Future<int> _adminCount(String householdId) async {
    final countExp = _database.householdMemberships.id.count();
    final row =
        await (_database.selectOnly(_database.householdMemberships)
              ..addColumns(<Expression<Object>>[countExp])
              ..where(
                _database.householdMemberships.householdId.equals(householdId) &
                    _database.householdMemberships.role.equals(
                      HouseholdRole.admin.name,
                    ),
              ))
            .getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<HouseholdMembership?> _membershipFor(
    String householdId,
    String userId,
  ) {
    return (_database.select(_database.householdMemberships)..where(
          (HouseholdMemberships row) =>
              row.householdId.equals(householdId) & row.userId.equals(userId),
        ))
        .getSingleOrNull();
  }

  Future<String> _generateInviteCode() async {
    while (true) {
      final code = List<String>.generate(
        8,
        (int index) => _alphabet[_random.nextInt(_alphabet.length)],
      ).join();
      final existing =
          await (_database.select(_database.households)
                ..where((Households row) => row.inviteCode.equals(code)))
              .getSingleOrNull();
      if (existing == null) {
        return code;
      }
    }
  }

  HouseholdEntity _mapHousehold(Household household) {
    return HouseholdEntity(
      id: household.id,
      name: household.name,
      emoji: household.emoji,
      avatarColorKey: household.avatarColorKey,
      currencyCode: household.currencyCode,
      inviteCode: household.inviteCode,
      createdByUserId: household.createdByUserId,
      createdAt: household.createdAt,
      updatedAt: household.updatedAt,
    );
  }
}
