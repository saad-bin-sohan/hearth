import 'package:hearth/features/chores/domain/chore_models.dart';

abstract class ChoreRepository {
  Stream<List<ChoreEntity>> watchChoresForHousehold(String householdId);

  Stream<List<ChoreEntity>> watchChoresDueToday({
    required String householdId,
    required String userId,
  });

  Stream<List<ChoreEntity>> watchChoresDueThisWeek(String householdId);

  Stream<ChoreEntity?> watchChoreById(String id);

  Future<ChoreEntity?> getChoreById(String id);

  Future<void> addChore({
    required String actorUserId,
    required ChoreDraft draft,
  });

  Future<void> updateChore({
    required String actorUserId,
    required ChoreDraft draft,
  });

  Future<void> deleteChore({
    required String actorUserId,
    required String choreId,
  });

  Future<ChoreCompletionOutcome> completeChore({
    required String actorUserId,
    required String choreId,
    String? notes,
    String? photoLocalPath,
    DateTime? completedAt,
  });

  Future<void> deferChore({
    required String actorUserId,
    required String choreId,
    required DateTime newDueAt,
    String? reason,
  });

  Stream<List<ChoreCompletionEntity>> watchCompletionsForChore(String choreId);

  Future<List<ChoreCompletionEntity>> getCompletionsForHousehold({
    required String householdId,
    DateTime? since,
  });

  Future<Map<String, int>> getContributionMinutes({
    required String householdId,
    DateTime? since,
  });

  Future<Map<String, double>> calculateFairnessScores(String householdId);

  Future<ChoreHomeSummary> getHomeSummary({
    required String householdId,
    required String userId,
  });

  Future<List<ChoreEntity>> getOverdueChores(String householdId);
}
