import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/core/services/notification_service.dart';
import 'package:hearth/features/chores/data/local_chore_repository.dart';
import 'package:hearth/features/chores/domain/calculate_fairness_score_usecase.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';

class ChoreActionState {
  const ChoreActionState({this.isLoading = false, this.message});

  final bool isLoading;
  final String? message;

  ChoreActionState copyWith({
    bool? isLoading,
    String? message,
    bool clearMessage = false,
  }) {
    return ChoreActionState(
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class ChoreNotifier extends StateNotifier<ChoreActionState> {
  ChoreNotifier(this.ref) : super(const ChoreActionState());

  final Ref ref;

  Future<void> addChore(ChoreDraft draft) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to add chores.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref
          .read(choreRepositoryProvider)
          .addChore(actorUserId: actorUserId, draft: draft);
      _invalidateDerivedProviders();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> updateChore(ChoreDraft draft) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to edit chores.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref
          .read(choreRepositoryProvider)
          .updateChore(actorUserId: actorUserId, draft: draft);
      _invalidateDerivedProviders();
      if (draft.id != null) {
        ref.invalidate(choreDetailProvider(draft.id!));
      }
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> deleteChore(String choreId) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to delete chores.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref
          .read(choreRepositoryProvider)
          .deleteChore(actorUserId: actorUserId, choreId: choreId);
      _invalidateDerivedProviders();
      ref.invalidate(choreDetailProvider(choreId));
      ref.invalidate(choreCompletionsProvider(choreId));
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> deferChore({
    required String choreId,
    required DateTime newDueAt,
    String? reason,
  }) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to defer chores.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref
          .read(choreRepositoryProvider)
          .deferChore(
            actorUserId: actorUserId,
            choreId: choreId,
            newDueAt: newDueAt,
            reason: reason,
          );
      _invalidateDerivedProviders();
      ref.invalidate(choreDetailProvider(choreId));
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<ChoreCompletionOutcome> completeChore({
    required String choreId,
    String? notes,
    String? photoLocalPath,
    DateTime? completedAt,
  }) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to complete chores.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final outcome = await ref
          .read(choreRepositoryProvider)
          .completeChore(
            actorUserId: actorUserId,
            choreId: choreId,
            notes: notes,
            photoLocalPath: photoLocalPath,
            completedAt: completedAt,
          );
      _invalidateDerivedProviders();
      ref.invalidate(choreDetailProvider(choreId));
      ref.invalidate(choreCompletionsProvider(choreId));
      state = state.copyWith(isLoading: false, clearMessage: true);
      return outcome;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  void _invalidateDerivedProviders() {
    ref.invalidate(choresHomeSummaryProvider);
    ref.invalidate(overdueChoresProvider);
    ref.invalidate(fairnessScoreSnapshotProvider);
    ref.invalidate(fairnessEntriesProvider);
    ref.invalidate(choresBootstrapProvider);
  }
}

final choreNotifierProvider =
    StateNotifierProvider<ChoreNotifier, ChoreActionState>((Ref ref) {
      return ChoreNotifier(ref);
    });

final choreHouseholdIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).activeHouseholdId;
});

final choreCurrentUserIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).userId;
});

final choreMembersProvider = FutureProvider<List<HouseholdMember>>((
  Ref ref,
) async {
  return ref.watch(householdMembersProvider.future);
});

final choreMemberLookupProvider = FutureProvider<Map<String, HouseholdMember>>((
  Ref ref,
) async {
  final members = await ref.watch(choreMembersProvider.future);
  return <String, HouseholdMember>{
    for (final member in members) member.userId: member,
  };
});

final choresProvider = StreamProvider<List<ChoreEntity>>((Ref ref) {
  final householdId = ref.watch(choreHouseholdIdProvider);
  if (householdId == null) {
    return Stream<List<ChoreEntity>>.value(const <ChoreEntity>[]);
  }
  return ref
      .watch(choreRepositoryProvider)
      .watchChoresForHousehold(householdId);
});

final todaysChoresProvider = StreamProvider<List<ChoreEntity>>((Ref ref) {
  final householdId = ref.watch(choreHouseholdIdProvider);
  final userId = ref.watch(choreCurrentUserIdProvider);
  if (householdId == null || userId == null) {
    return Stream<List<ChoreEntity>>.value(const <ChoreEntity>[]);
  }
  return ref
      .watch(choreRepositoryProvider)
      .watchChoresDueToday(householdId: householdId, userId: userId);
});

final thisWeekChoresProvider = StreamProvider<List<ChoreEntity>>((Ref ref) {
  final householdId = ref.watch(choreHouseholdIdProvider);
  if (householdId == null) {
    return Stream<List<ChoreEntity>>.value(const <ChoreEntity>[]);
  }
  return ref.watch(choreRepositoryProvider).watchChoresDueThisWeek(householdId);
});

final choreDetailProvider = StreamProvider.family<ChoreEntity?, String>((
  Ref ref,
  String choreId,
) {
  return ref.watch(choreRepositoryProvider).watchChoreById(choreId);
});

final choreCompletionsProvider =
    StreamProvider.family<List<ChoreCompletionEntity>, String>((
      Ref ref,
      String choreId,
    ) {
      return ref
          .watch(choreRepositoryProvider)
          .watchCompletionsForChore(choreId);
    });

final choresHomeSummaryProvider = FutureProvider<ChoreHomeSummary?>((
  Ref ref,
) async {
  final householdId = ref.watch(choreHouseholdIdProvider);
  final userId = ref.watch(choreCurrentUserIdProvider);
  if (householdId == null || userId == null) {
    return null;
  }
  return ref
      .watch(choreRepositoryProvider)
      .getHomeSummary(householdId: householdId, userId: userId);
});

final overdueChoresProvider = FutureProvider<List<ChoreEntity>>((
  Ref ref,
) async {
  final householdId = ref.watch(choreHouseholdIdProvider);
  if (householdId == null) {
    return const <ChoreEntity>[];
  }
  return ref.watch(choreRepositoryProvider).getOverdueChores(householdId);
});

final fairnessScoreSnapshotProvider = FutureProvider<FairnessScoreSnapshot?>((
  Ref ref,
) async {
  final householdId = ref.watch(choreHouseholdIdProvider);
  if (householdId == null) {
    return null;
  }
  final members = await ref.watch(choreMembersProvider.future);
  final activeMemberUserIds = members
      .where((HouseholdMember member) => member.role != HouseholdRole.observer)
      .map((HouseholdMember member) => member.userId)
      .toList();
  final memberMinutes = await ref
      .watch(choreRepositoryProvider)
      .getContributionMinutes(
        householdId: householdId,
        since: DateTime.now().subtract(const Duration(days: 30)),
      );
  return const CalculateFairnessScoreUseCase().execute(
    activeMemberUserIds: activeMemberUserIds,
    memberMinutes: memberMinutes,
  );
});

final fairnessEntriesProvider = FutureProvider<List<FairnessScoreEntry>>((
  Ref ref,
) async {
  final snapshot = await ref.watch(fairnessScoreSnapshotProvider.future);
  final members = await ref.watch(choreMembersProvider.future);
  if (snapshot == null) {
    return const <FairnessScoreEntry>[];
  }
  final memberLookup = <String, HouseholdMember>{
    for (final member in members) member.userId: member,
  };
  final entries =
      snapshot.scores.entries
          .map(
            (MapEntry<String, double> entry) => FairnessScoreEntry(
              userId: entry.key,
              displayName: memberLookup[entry.key]?.displayName ?? 'Unknown',
              minutesCompleted: snapshot.memberMinutes[entry.key] ?? 0,
              score: entry.value,
            ),
          )
          .toList()
        ..sort((FairnessScoreEntry left, FairnessScoreEntry right) {
          final scoreOrder = right.score.compareTo(left.score);
          if (scoreOrder != 0) {
            return scoreOrder;
          }
          return right.minutesCompleted.compareTo(left.minutesCompleted);
        });
  return entries;
});

final choresBootstrapProvider = FutureProvider<void>((Ref ref) async {
  final householdId = ref.watch(choreHouseholdIdProvider);
  if (householdId == null) {
    return;
  }
  final chores = await ref
      .watch(choreRepositoryProvider)
      .getOverdueChores(householdId);
  if (chores.isEmpty) {
    return;
  }
  final members = await ref.watch(choreMembersProvider.future);
  final memberLookup = <String, HouseholdMember>{
    for (final member in members) member.userId: member,
  };
  final notificationService = ref.watch(notificationServiceProvider);
  for (final chore in chores) {
    final assigneeName =
        memberLookup[chore.currentAssigneeUserId]?.displayName ?? 'Someone';
    await notificationService.schedule(
      id: 'chore-overdue-${chore.id}',
      title: '🧹 ${chore.title} is overdue',
      body: '$assigneeName was due to do this',
    );
  }
});
