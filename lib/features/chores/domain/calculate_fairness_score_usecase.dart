import 'package:hearth/features/chores/domain/chore_models.dart';

class CalculateFairnessScoreUseCase {
  const CalculateFairnessScoreUseCase();

  FairnessScoreSnapshot execute({
    required List<String> activeMemberUserIds,
    required Map<String, int> memberMinutes,
  }) {
    if (activeMemberUserIds.isEmpty) {
      return const FairnessScoreSnapshot(
        scores: <String, double>{},
        memberMinutes: <String, int>{},
      );
    }

    final normalizedMinutes = <String, int>{
      for (final userId in activeMemberUserIds)
        userId: memberMinutes[userId] ?? 0,
    };
    final totalMinutes = normalizedMinutes.values.fold<int>(
      0,
      (int total, int value) => total + value,
    );
    if (totalMinutes == 0) {
      return FairnessScoreSnapshot(
        scores: <String, double>{
          for (final userId in activeMemberUserIds) userId: 100,
        },
        memberMinutes: normalizedMinutes,
      );
    }

    final fairShareMinutes = totalMinutes / activeMemberUserIds.length;
    return FairnessScoreSnapshot(
      scores: <String, double>{
        for (final userId in activeMemberUserIds)
          userId: cappedFairnessScore(
            contributedMinutes: normalizedMinutes[userId] ?? 0,
            fairShareMinutes: fairShareMinutes,
          ),
      },
      memberMinutes: normalizedMinutes,
    );
  }
}
