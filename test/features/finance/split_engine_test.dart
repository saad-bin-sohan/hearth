import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/finance/domain/split_engine.dart';

void main() {
  const engine = SplitEngine();
  const participants = <String>['alice', 'bob', 'charlie'];

  test('equal split distributes leftover cents from the start of the list', () {
    final result = engine.allocate(
      totalCents: 100,
      rule: const EqualSplitRule(participantUserIds: participants),
    );

    expect(
      result.map((SplitAllocation entry) => entry.amountCents).toList(),
      <int>[34, 33, 33],
    );
  });

  test('percentage split uses largest remainder allocation', () {
    final result = engine.allocate(
      totalCents: 1001,
      rule: const PercentageSplitRule(
        participantUserIds: participants,
        percentages: <String, int>{
          'alice': 50,
          'bob': 30,
          'charlie': 20,
        },
      ),
    );

    expect(
      result.map((SplitAllocation entry) => entry.amountCents).toList(),
      <int>[501, 300, 200],
    );
  });

  test('percentage split rejects totals that do not add up to 100', () {
    expect(
      () => engine.allocate(
        totalCents: 1000,
        rule: const PercentageSplitRule(
          participantUserIds: participants,
          percentages: <String, int>{
            'alice': 40,
            'bob': 30,
            'charlie': 20,
          },
        ),
      ),
      throwsStateError,
    );
  });

  test('fixed split requires an exact total match', () {
    expect(
      () => engine.allocate(
        totalCents: 1000,
        rule: const FixedSplitRule(
          participantUserIds: participants,
          amountsCents: <String, int>{
            'alice': 300,
            'bob': 300,
            'charlie': 300,
          },
        ),
      ),
      throwsStateError,
    );
  });

  test('exemption split gives exempt members zero and shares remaining equally', () {
    final result = engine.allocate(
      totalCents: 1000,
      rule: const ExemptionSplitRule(
        participantUserIds: participants,
        exemptUserIds: <String>['bob'],
      ),
    );

    expect(
      result.map((SplitAllocation entry) => entry.amountCents).toList(),
      <int>[500, 0, 500],
    );
  });
}
