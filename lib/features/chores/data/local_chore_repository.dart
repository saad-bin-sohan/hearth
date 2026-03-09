import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/chores/data/tables.dart';
import 'package:hearth/features/chores/domain/calculate_fairness_score_usecase.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/chores/domain/chore_repository.dart';
import 'package:hearth/features/chores/domain/complete_chore_usecase.dart';
import 'package:hearth/features/chores/domain/defer_chore_usecase.dart';
import 'package:hearth/features/household/data/tables.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:uuid/uuid.dart';

final choreRepositoryProvider = Provider<ChoreRepository>((Ref ref) {
  return LocalChoreRepository(
    database: ref.read(appDatabaseProvider),
    uuid: const Uuid(),
  );
});

class LocalChoreRepository implements ChoreRepository {
  LocalChoreRepository({
    required AppDatabase database,
    required Uuid uuid,
    CompleteChoreUseCase completeChoreUseCase = const CompleteChoreUseCase(),
    CalculateFairnessScoreUseCase calculateFairnessScoreUseCase =
        const CalculateFairnessScoreUseCase(),
    DeferChoreUseCase deferChoreUseCase = const DeferChoreUseCase(),
  }) : _database = database,
       _uuid = uuid,
       _completeChoreUseCase = completeChoreUseCase,
       _calculateFairnessScoreUseCase = calculateFairnessScoreUseCase,
       _deferChoreUseCase = deferChoreUseCase;

  final AppDatabase _database;
  final Uuid _uuid;
  final CompleteChoreUseCase _completeChoreUseCase;
  final CalculateFairnessScoreUseCase _calculateFairnessScoreUseCase;
  final DeferChoreUseCase _deferChoreUseCase;

  @override
  Stream<List<ChoreEntity>> watchChoresForHousehold(String householdId) {
    final query =
        (_database.select(_database.chores)
              ..where(
                (Chores row) =>
                    row.householdId.equals(householdId) &
                    row.isActive.equals(true),
              )
              ..orderBy(<OrderingTerm Function(Chores)>[
                (Chores row) => OrderingTerm.asc(row.nextDueAt),
                (Chores row) => OrderingTerm.asc(row.createdAt),
              ]))
            .watch();
    return query.map((List<Chore> rows) => rows.map(_mapChore).toList());
  }

  @override
  Stream<List<ChoreEntity>> watchChoresDueToday({
    required String householdId,
    required String userId,
  }) {
    return watchChoresForHousehold(householdId).map((List<ChoreEntity> chores) {
      return chores
          .where(
            (ChoreEntity chore) =>
                _isAssignedToUser(chore, userId) &&
                _isDueToday(chore.nextDueAt),
          )
          .toList();
    });
  }

  @override
  Stream<List<ChoreEntity>> watchChoresDueThisWeek(String householdId) {
    return watchChoresForHousehold(householdId).map((List<ChoreEntity> chores) {
      final now = DateTime.now();
      final weekBoundary = _startOfDay(now).add(const Duration(days: 7));
      final filtered =
          chores
              .where(
                (ChoreEntity chore) =>
                    chore.nextDueAt.isBefore(weekBoundary) ||
                    _isSameDay(chore.nextDueAt, weekBoundary),
              )
              .toList()
            ..sort((ChoreEntity left, ChoreEntity right) {
              return left.nextDueAt.compareTo(right.nextDueAt);
            });
      return filtered;
    });
  }

  @override
  Stream<ChoreEntity?> watchChoreById(String id) {
    final query = (_database.select(
      _database.chores,
    )..where((Chores row) => row.id.equals(id))).watchSingleOrNull();
    return query.map((Chore? row) => row == null ? null : _mapChore(row));
  }

  @override
  Future<ChoreEntity?> getChoreById(String id) async {
    final row = await (_database.select(
      _database.chores,
    )..where((Chores chore) => chore.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapChore(row);
  }

  @override
  Future<void> addChore({
    required String actorUserId,
    required ChoreDraft draft,
  }) async {
    await _assertCanEdit(
      actorUserId: actorUserId,
      householdId: draft.householdId,
    );
    final normalizedUserIds = _normalizedAssignedUserIds(
      draft.assignedToUserIds,
    );
    if (normalizedUserIds.isEmpty) {
      throw StateError('Choose at least one assignee.');
    }
    final now = DateTime.now();
    await _database
        .into(_database.chores)
        .insert(
          ChoresCompanion.insert(
            id: _uuid.v4(),
            householdId: draft.householdId,
            title: draft.title.trim(),
            description: Value<String?>(_trimmedOrNull(draft.description)),
            areaTag: draft.areaTag.name,
            estimatedMinutes: draft.estimatedMinutes,
            frequency: draft.frequency.name,
            recurrenceRule: Value<String?>(
              _trimmedOrNull(draft.recurrenceRule),
            ),
            assignmentType: draft.assignmentType.name,
            assignedToUserIds: choreUserIdsToJson(normalizedUserIds),
            currentAssigneeIndex: Value<int>(
              _clampAssigneeIndex(
                draft.currentAssigneeIndex,
                normalizedUserIds.length,
              ),
            ),
            nextDueAt: draft.nextDueAt,
            isActive: Value<bool>(draft.isActive),
            streakCount: const Value<int>(0),
            createdAt: now,
            createdByUserId: actorUserId,
          ),
        );
  }

  @override
  Future<void> updateChore({
    required String actorUserId,
    required ChoreDraft draft,
  }) async {
    final choreId = draft.id;
    if (choreId == null) {
      throw StateError('Chore id is required for updates.');
    }
    final existing = await _getChoreRowById(choreId);
    if (existing == null) {
      throw StateError('Chore not found.');
    }
    await _assertCanEdit(
      actorUserId: actorUserId,
      householdId: existing.householdId,
    );
    final normalizedUserIds = _normalizedAssignedUserIds(
      draft.assignedToUserIds,
    );
    if (normalizedUserIds.isEmpty) {
      throw StateError('Choose at least one assignee.');
    }
    await (_database.update(
      _database.chores,
    )..where((Chores row) => row.id.equals(choreId))).write(
      ChoresCompanion(
        title: Value<String>(draft.title.trim()),
        description: Value<String?>(_trimmedOrNull(draft.description)),
        areaTag: Value<String>(draft.areaTag.name),
        estimatedMinutes: Value<int>(draft.estimatedMinutes),
        frequency: Value<String>(draft.frequency.name),
        recurrenceRule: Value<String?>(_trimmedOrNull(draft.recurrenceRule)),
        assignmentType: Value<String>(draft.assignmentType.name),
        assignedToUserIds: Value<String>(choreUserIdsToJson(normalizedUserIds)),
        currentAssigneeIndex: Value<int>(
          _clampAssigneeIndex(
            draft.currentAssigneeIndex,
            normalizedUserIds.length,
          ),
        ),
        nextDueAt: Value<DateTime>(draft.nextDueAt),
        isActive: Value<bool>(draft.isActive),
      ),
    );
  }

  @override
  Future<void> deleteChore({
    required String actorUserId,
    required String choreId,
  }) async {
    final chore = await _getChoreRowById(choreId);
    if (chore == null) {
      return;
    }
    await _assertAdmin(
      actorUserId: actorUserId,
      householdId: chore.householdId,
    );
    await _database.transaction(() async {
      await (_database.delete(
        _database.choreCompletions,
      )..where((ChoreCompletions row) => row.choreId.equals(choreId))).go();
      await (_database.delete(
        _database.choreDeferrals,
      )..where((ChoreDeferrals row) => row.choreId.equals(choreId))).go();
      await (_database.delete(
        _database.chores,
      )..where((Chores row) => row.id.equals(choreId))).go();
    });
  }

  @override
  Future<ChoreCompletionOutcome> completeChore({
    required String actorUserId,
    required String choreId,
    String? notes,
    String? photoLocalPath,
    DateTime? completedAt,
  }) async {
    final choreRow = await _getChoreRowById(choreId);
    if (choreRow == null) {
      throw StateError('Chore not found.');
    }
    final chore = _mapChore(choreRow);
    await _assertCanEdit(
      actorUserId: actorUserId,
      householdId: chore.householdId,
    );
    final completionTime = completedAt ?? DateTime.now();
    final computation = _completeChoreUseCase.execute(
      chore: chore,
      completedAt: completionTime,
    );
    final completion = ChoreCompletionEntity(
      id: _uuid.v4(),
      choreId: choreId,
      completedByUserId: actorUserId,
      completedAt: completionTime,
      photoLocalPath: _trimmedOrNull(photoLocalPath),
      notes: _trimmedOrNull(notes),
      wasOnTime: computation.wasOnTime,
    );
    final updatedChore = chore.copyWith(
      currentAssigneeIndex: computation.updatedAssigneeIndex,
      nextDueAt: computation.nextDueAt,
      streakCount: computation.updatedStreakCount,
    );

    await _database.transaction(() async {
      await _database
          .into(_database.choreCompletions)
          .insert(
            ChoreCompletionsCompanion.insert(
              id: completion.id,
              choreId: completion.choreId,
              completedByUserId: completion.completedByUserId,
              completedAt: completion.completedAt,
              photoLocalPath: Value<String?>(completion.photoLocalPath),
              notes: Value<String?>(completion.notes),
              wasOnTime: completion.wasOnTime,
            ),
          );
      await (_database.update(
        _database.chores,
      )..where((Chores row) => row.id.equals(choreId))).write(
        ChoresCompanion(
          currentAssigneeIndex: Value<int>(updatedChore.currentAssigneeIndex),
          nextDueAt: Value<DateTime>(updatedChore.nextDueAt),
          streakCount: Value<int>(updatedChore.streakCount),
        ),
      );
    });

    return ChoreCompletionOutcome(
      chore: updatedChore,
      completion: completion,
      wasOnTime: computation.wasOnTime,
      milestoneReached: computation.milestoneReached,
    );
  }

  @override
  Future<void> deferChore({
    required String actorUserId,
    required String choreId,
    required DateTime newDueAt,
    String? reason,
  }) async {
    final choreRow = await _getChoreRowById(choreId);
    if (choreRow == null) {
      throw StateError('Chore not found.');
    }
    final chore = _mapChore(choreRow);
    await _assertCanEdit(
      actorUserId: actorUserId,
      householdId: chore.householdId,
    );
    final updatedChore = _deferChoreUseCase.execute(
      chore: chore,
      newDueAt: newDueAt,
    );
    final deferredAt = DateTime.now();
    await _database.transaction(() async {
      await _database
          .into(_database.choreDeferrals)
          .insert(
            ChoreDeferralsCompanion.insert(
              id: _uuid.v4(),
              choreId: choreId,
              deferredByUserId: actorUserId,
              deferredAt: deferredAt,
              reason: Value<String?>(_trimmedOrNull(reason)),
              newDueAt: newDueAt,
            ),
          );
      await (_database.update(
        _database.chores,
      )..where((Chores row) => row.id.equals(choreId))).write(
        ChoresCompanion(nextDueAt: Value<DateTime>(updatedChore.nextDueAt)),
      );
    });
  }

  @override
  Stream<List<ChoreCompletionEntity>> watchCompletionsForChore(String choreId) {
    final query =
        (_database.select(_database.choreCompletions)
              ..where((ChoreCompletions row) => row.choreId.equals(choreId))
              ..orderBy(<OrderingTerm Function(ChoreCompletions)>[
                (ChoreCompletions row) => OrderingTerm.desc(row.completedAt),
              ]))
            .watch();
    return query.map(
      (List<ChoreCompletion> rows) => rows.map(_mapCompletion).toList(),
    );
  }

  @override
  Future<List<ChoreCompletionEntity>> getCompletionsForHousehold({
    required String householdId,
    DateTime? since,
  }) async {
    final query =
        _database
            .select(_database.choreCompletions)
            .join(<Join<HasResultSet, dynamic>>[
              innerJoin(
                _database.chores,
                _database.chores.id.equalsExp(
                  _database.choreCompletions.choreId,
                ),
              ),
            ])
          ..where(_database.chores.householdId.equals(householdId))
          ..orderBy(<OrderingTerm>[
            OrderingTerm.desc(_database.choreCompletions.completedAt),
          ]);
    if (since != null) {
      query.where(
        _database.choreCompletions.completedAt.isBiggerOrEqualValue(since),
      );
    }
    final rows = await query.get();
    return rows
        .map(
          (TypedResult row) =>
              _mapCompletion(row.readTable(_database.choreCompletions)),
        )
        .toList();
  }

  @override
  Future<Map<String, int>> getContributionMinutes({
    required String householdId,
    DateTime? since,
  }) async {
    final query = _database.select(_database.choreCompletions).join(
      <Join<HasResultSet, dynamic>>[
        innerJoin(
          _database.chores,
          _database.chores.id.equalsExp(_database.choreCompletions.choreId),
        ),
      ],
    )..where(_database.chores.householdId.equals(householdId));
    if (since != null) {
      query.where(
        _database.choreCompletions.completedAt.isBiggerOrEqualValue(since),
      );
    }
    final rows = await query.get();
    final memberMinutes = <String, int>{};
    for (final row in rows) {
      final completion = row.readTable(_database.choreCompletions);
      final chore = row.readTable(_database.chores);
      memberMinutes.update(
        completion.completedByUserId,
        (int value) => value + chore.estimatedMinutes,
        ifAbsent: () => chore.estimatedMinutes,
      );
    }
    return memberMinutes;
  }

  @override
  Future<Map<String, double>> calculateFairnessScores(
    String householdId,
  ) async {
    final activeMembers = await _activeMemberUserIds(householdId);
    final memberMinutes = await getContributionMinutes(
      householdId: householdId,
      since: DateTime.now().subtract(const Duration(days: 30)),
    );
    return _calculateFairnessScoreUseCase
        .execute(
          activeMemberUserIds: activeMembers,
          memberMinutes: memberMinutes,
        )
        .scores;
  }

  @override
  Future<ChoreHomeSummary> getHomeSummary({
    required String householdId,
    required String userId,
  }) async {
    final chores =
        await (_database.select(_database.chores)..where(
              (Chores row) =>
                  row.householdId.equals(householdId) &
                  row.isActive.equals(true),
            ))
            .get();
    final now = DateTime.now();
    var dueTodayCount = 0;
    var overdueCount = 0;
    for (final row in chores) {
      final chore = _mapChore(row);
      if (!_isAssignedToUser(chore, userId)) {
        continue;
      }
      if (_isDueToday(chore.nextDueAt)) {
        dueTodayCount += 1;
      }
      if (chore.nextDueAt.isBefore(now)) {
        overdueCount += 1;
      }
    }
    return ChoreHomeSummary(
      dueTodayCount: dueTodayCount,
      overdueCount: overdueCount,
    );
  }

  @override
  Future<List<ChoreEntity>> getOverdueChores(String householdId) async {
    final rows =
        await (_database.select(_database.chores)
              ..where(
                (Chores row) =>
                    row.householdId.equals(householdId) &
                    row.isActive.equals(true) &
                    row.nextDueAt.isSmallerThanValue(DateTime.now()),
              )
              ..orderBy(<OrderingTerm Function(Chores)>[
                (Chores row) => OrderingTerm.asc(row.nextDueAt),
              ]))
            .get();
    return rows.map(_mapChore).toList();
  }

  Future<List<String>> _activeMemberUserIds(String householdId) async {
    final rows =
        await (_database.select(_database.householdMemberships)..where(
              (HouseholdMemberships row) => row.householdId.equals(householdId),
            ))
            .get();
    return rows
        .where(
          (HouseholdMembership membership) =>
              membership.role != HouseholdRole.observer.name,
        )
        .map((HouseholdMembership membership) => membership.userId)
        .toList();
  }

  Future<HouseholdMembership?> _membershipFor({
    required String householdId,
    required String userId,
  }) {
    return (_database.select(_database.householdMemberships)..where(
          (HouseholdMemberships row) =>
              row.householdId.equals(householdId) & row.userId.equals(userId),
        ))
        .getSingleOrNull();
  }

  Future<void> _assertCanEdit({
    required String actorUserId,
    required String householdId,
  }) async {
    final membership = await _membershipFor(
      householdId: householdId,
      userId: actorUserId,
    );
    if (membership == null) {
      throw StateError('Household access is missing.');
    }
    if (membership.role == HouseholdRole.observer.name) {
      throw StateError('Observers cannot change chores.');
    }
  }

  Future<void> _assertAdmin({
    required String actorUserId,
    required String householdId,
  }) async {
    final membership = await _membershipFor(
      householdId: householdId,
      userId: actorUserId,
    );
    if (membership == null || membership.role != HouseholdRole.admin.name) {
      throw StateError('Only admins can delete chores.');
    }
  }

  Future<Chore?> _getChoreRowById(String choreId) {
    return (_database.select(
      _database.chores,
    )..where((Chores row) => row.id.equals(choreId))).getSingleOrNull();
  }

  ChoreEntity _mapChore(Chore row) {
    return ChoreEntity(
      id: row.id,
      householdId: row.householdId,
      title: row.title,
      description: row.description,
      areaTag: ChoreAreaTagX.fromName(row.areaTag),
      estimatedMinutes: row.estimatedMinutes,
      frequency: ChoreFrequencyX.fromName(row.frequency),
      recurrenceRule: row.recurrenceRule,
      assignmentType: ChoreAssignmentTypeX.fromName(row.assignmentType),
      assignedToUserIds: choreUserIdsFromJson(row.assignedToUserIds),
      currentAssigneeIndex: row.currentAssigneeIndex,
      nextDueAt: row.nextDueAt,
      isActive: row.isActive,
      streakCount: row.streakCount,
      createdAt: row.createdAt,
      createdByUserId: row.createdByUserId,
    );
  }

  ChoreCompletionEntity _mapCompletion(ChoreCompletion row) {
    return ChoreCompletionEntity(
      id: row.id,
      choreId: row.choreId,
      completedByUserId: row.completedByUserId,
      completedAt: row.completedAt,
      photoLocalPath: row.photoLocalPath,
      notes: row.notes,
      wasOnTime: row.wasOnTime,
    );
  }

  bool _isAssignedToUser(ChoreEntity chore, String userId) {
    if (chore.assignmentType == ChoreAssignmentType.rotation) {
      return chore.currentAssigneeUserId == userId;
    }
    return chore.assignedToUserIds.contains(userId);
  }

  bool _isDueToday(DateTime value) {
    final now = DateTime.now();
    final start = _startOfDay(now);
    final end = start.add(const Duration(days: 1));
    return (value.isAfter(start) || _isSameDay(value, start)) &&
        value.isBefore(end);
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  int _clampAssigneeIndex(int index, int userCount) {
    if (userCount <= 0) {
      return 0;
    }
    if (index < 0) {
      return 0;
    }
    if (index >= userCount) {
      return userCount - 1;
    }
    return index;
  }

  List<String> _normalizedAssignedUserIds(List<String> userIds) {
    return userIds
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
