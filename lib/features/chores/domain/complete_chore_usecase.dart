import 'package:hearth/features/chores/domain/chore_models.dart';

class CompleteChoreUseCase {
  const CompleteChoreUseCase();

  static const Duration onTimeGracePeriod = Duration(hours: 24);
  static const List<int> milestoneStreaks = <int>[7, 14, 30];

  ChoreCompletionComputation execute({
    required ChoreEntity chore,
    required DateTime completedAt,
  }) {
    final wasOnTime = !completedAt.isAfter(
      chore.nextDueAt.add(onTimeGracePeriod),
    );
    final updatedIndex =
        chore.assignmentType == ChoreAssignmentType.rotation &&
            chore.assignedToUserIds.isNotEmpty
        ? (chore.currentAssigneeIndex + 1) % chore.assignedToUserIds.length
        : chore.currentAssigneeIndex;
    final updatedStreak = wasOnTime ? chore.streakCount + 1 : 0;
    return ChoreCompletionComputation(
      wasOnTime: wasOnTime,
      updatedAssigneeIndex: updatedIndex,
      updatedStreakCount: updatedStreak,
      nextDueAt: _nextDueAt(chore),
      milestoneReached: isMilestone(updatedStreak),
    );
  }

  bool isMilestone(int streakCount) {
    return milestoneStreaks.contains(streakCount);
  }

  DateTime _nextDueAt(ChoreEntity chore) {
    return switch (chore.frequency) {
      ChoreFrequency.daily => chore.nextDueAt.add(const Duration(days: 1)),
      ChoreFrequency.weekly => chore.nextDueAt.add(const Duration(days: 7)),
      ChoreFrequency.biweekly => chore.nextDueAt.add(const Duration(days: 14)),
      ChoreFrequency.monthly => _addMonths(chore.nextDueAt, 1),
      ChoreFrequency.custom => _nextFromRRule(
        anchor: chore.nextDueAt,
        rule: chore.recurrenceRule,
      ),
    };
  }

  DateTime _nextFromRRule({required DateTime anchor, required String? rule}) {
    if (rule == null || rule.trim().isEmpty) {
      return anchor.add(const Duration(days: 7));
    }

    final parts = <String, String>{};
    for (final part in rule.split(';')) {
      final pieces = part.split('=');
      if (pieces.length == 2) {
        parts[pieces.first.toUpperCase()] = pieces.last.toUpperCase();
      }
    }

    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final frequency = parts['FREQ'];
    switch (frequency) {
      case 'DAILY':
        return anchor.add(Duration(days: interval));
      case 'WEEKLY':
        return anchor.add(Duration(days: interval * 7));
      case 'MONTHLY':
        return _addMonths(anchor, interval);
      default:
        return anchor.add(const Duration(days: 7));
    }
  }

  DateTime _addMonths(DateTime value, int delta) {
    final monthIndex = value.month + delta;
    final year = value.year + ((monthIndex - 1) ~/ 12);
    final month = ((monthIndex - 1) % 12) + 1;
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = value.day > maxDay ? maxDay : value.day;
    return DateTime(
      year,
      month,
      day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }
}

class ChoreCompletionComputation {
  const ChoreCompletionComputation({
    required this.wasOnTime,
    required this.updatedAssigneeIndex,
    required this.updatedStreakCount,
    required this.nextDueAt,
    required this.milestoneReached,
  });

  final bool wasOnTime;
  final int updatedAssigneeIndex;
  final int updatedStreakCount;
  final DateTime nextDueAt;
  final bool milestoneReached;
}
