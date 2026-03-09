import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/chores/domain/complete_chore_usecase.dart';

void main() {
  const useCase = CompleteChoreUseCase();
  final baseDueAt = DateTime(2026, 3, 9, 9);

  ChoreEntity buildChore({
    required ChoreAssignmentType assignmentType,
    required List<String> assignedToUserIds,
    int currentAssigneeIndex = 0,
    int streakCount = 0,
  }) {
    return ChoreEntity(
      id: 'chore-1',
      householdId: 'house-1',
      title: 'Kitchen reset',
      areaTag: ChoreAreaTag.kitchen,
      estimatedMinutes: 20,
      frequency: ChoreFrequency.weekly,
      assignmentType: assignmentType,
      assignedToUserIds: assignedToUserIds,
      currentAssigneeIndex: currentAssigneeIndex,
      nextDueAt: baseDueAt,
      isActive: true,
      streakCount: streakCount,
      createdAt: baseDueAt.subtract(const Duration(days: 10)),
      createdByUserId: 'alice',
    );
  }

  test('fixed assignment keeps the assignee index in place', () {
    final computation = useCase.execute(
      chore: buildChore(
        assignmentType: ChoreAssignmentType.fixed,
        assignedToUserIds: const <String>['alice'],
      ),
      completedAt: baseDueAt,
    );

    expect(computation.updatedAssigneeIndex, 0);
  });

  test('rotation with 2 members cycles 0 to 1 to 0', () {
    final chore = buildChore(
      assignmentType: ChoreAssignmentType.rotation,
      assignedToUserIds: const <String>['alice', 'bob'],
    );
    final first = useCase.execute(chore: chore, completedAt: baseDueAt);
    final second = useCase.execute(
      chore: chore.copyWith(currentAssigneeIndex: first.updatedAssigneeIndex),
      completedAt: baseDueAt.add(const Duration(days: 7)),
    );

    expect(first.updatedAssigneeIndex, 1);
    expect(second.updatedAssigneeIndex, 0);
  });

  test('rotation with 3 members cycles 0 to 1 to 2 to 0', () {
    var chore = buildChore(
      assignmentType: ChoreAssignmentType.rotation,
      assignedToUserIds: const <String>['alice', 'bob', 'charlie'],
    );

    final first = useCase.execute(chore: chore, completedAt: baseDueAt);
    chore = chore.copyWith(currentAssigneeIndex: first.updatedAssigneeIndex);
    final second = useCase.execute(
      chore: chore,
      completedAt: baseDueAt.add(const Duration(days: 7)),
    );
    chore = chore.copyWith(currentAssigneeIndex: second.updatedAssigneeIndex);
    final third = useCase.execute(
      chore: chore,
      completedAt: baseDueAt.add(const Duration(days: 14)),
    );

    expect(first.updatedAssigneeIndex, 1);
    expect(second.updatedAssigneeIndex, 2);
    expect(third.updatedAssigneeIndex, 0);
  });

  test('on-time completion increments streak count', () {
    final computation = useCase.execute(
      chore: buildChore(
        assignmentType: ChoreAssignmentType.fixed,
        assignedToUserIds: const <String>['alice'],
        streakCount: 4,
      ),
      completedAt: baseDueAt.add(const Duration(hours: 2)),
    );

    expect(computation.wasOnTime, isTrue);
    expect(computation.updatedStreakCount, 5);
  });

  test('late completion beyond the grace period resets streak to 0', () {
    final computation = useCase.execute(
      chore: buildChore(
        assignmentType: ChoreAssignmentType.fixed,
        assignedToUserIds: const <String>['alice'],
        streakCount: 6,
      ),
      completedAt: baseDueAt.add(const Duration(hours: 25)),
    );

    expect(computation.wasOnTime, isFalse);
    expect(computation.updatedStreakCount, 0);
  });

  test('milestone detection only fires at 7, 14, and 30', () {
    expect(useCase.isMilestone(6), isFalse);
    expect(useCase.isMilestone(7), isTrue);
    expect(useCase.isMilestone(13), isFalse);
    expect(useCase.isMilestone(14), isTrue);
    expect(useCase.isMilestone(29), isFalse);
    expect(useCase.isMilestone(30), isTrue);
  });
}
