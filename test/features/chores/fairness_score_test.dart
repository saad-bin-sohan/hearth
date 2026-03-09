import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/chores/domain/calculate_fairness_score_usecase.dart';

void main() {
  const useCase = CalculateFairnessScoreUseCase();

  test('single active member gets a score of 100', () {
    final snapshot = useCase.execute(
      activeMemberUserIds: const <String>['alice'],
      memberMinutes: const <String, int>{'alice': 60},
    );

    expect(snapshot.scores['alice'], 100);
  });

  test('two members with equal minutes both score 100', () {
    final snapshot = useCase.execute(
      activeMemberUserIds: const <String>['alice', 'bob'],
      memberMinutes: const <String, int>{'alice': 45, 'bob': 45},
    );

    expect(snapshot.scores['alice'], 100);
    expect(snapshot.scores['bob'], 100);
  });

  test(
    'heavy imbalance caps the leading member and leaves the other near 33',
    () {
      final snapshot = useCase.execute(
        activeMemberUserIds: const <String>['alice', 'bob'],
        memberMinutes: const <String, int>{'alice': 100, 'bob': 20},
      );

      expect(snapshot.scores['alice'], 100);
      expect(snapshot.scores['bob'], closeTo(33.33, 0.01));
    },
  );

  test(
    'three members with one doing nothing yields a zero score for that member',
    () {
      final snapshot = useCase.execute(
        activeMemberUserIds: const <String>['alice', 'bob', 'charlie'],
        memberMinutes: const <String, int>{
          'alice': 60,
          'bob': 60,
          'charlie': 0,
        },
      );

      expect(snapshot.scores['alice'], 100);
      expect(snapshot.scores['bob'], 100);
      expect(snapshot.scores['charlie'], 0);
    },
  );

  test('zero total minutes gives everyone a score of 100', () {
    final snapshot = useCase.execute(
      activeMemberUserIds: const <String>['alice', 'bob', 'charlie'],
      memberMinutes: const <String, int>{},
    );

    expect(snapshot.scores['alice'], 100);
    expect(snapshot.scores['bob'], 100);
    expect(snapshot.scores['charlie'], 100);
  });
}
