import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/features/finance/domain/balance_engine.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';

void main() {
  const engine = BalanceEngine();

  test('simplifies opposite direction debts into one net balance', () {
    final result = engine.compute(
      expenses: <BalanceComputationInput>[
        const BalanceComputationInput(
          id: 'expense-a',
          paidByUserId: 'alice',
          amountCents: 1000,
          splitRule: EqualSplitRule(
            participantUserIds: <String>['alice', 'bob'],
          ),
          isRecurringTemplate: false,
        ),
        const BalanceComputationInput(
          id: 'expense-b',
          paidByUserId: 'bob',
          amountCents: 800,
          splitRule: EqualSplitRule(
            participantUserIds: <String>['alice', 'bob'],
          ),
          isRecurringTemplate: false,
        ),
      ],
      settlements: const <SettlementComputationInput>[],
    );

    expect(result, const <BalanceResult>[
      BalanceResult(
        debtorUserId: 'bob',
        creditorUserId: 'alice',
        amountCents: 100,
      ),
    ]);
  });

  test('subtracts completed settlements and ignores pending ones', () {
    final result = engine.compute(
      expenses: <BalanceComputationInput>[
        const BalanceComputationInput(
          id: 'expense-c',
          paidByUserId: 'alice',
          amountCents: 1200,
          splitRule: EqualSplitRule(
            participantUserIds: <String>['alice', 'bob', 'charlie'],
          ),
          isRecurringTemplate: false,
        ),
      ],
      settlements: const <SettlementComputationInput>[
        SettlementComputationInput(
          debtorUserId: 'charlie',
          creditorUserId: 'alice',
          amountCents: 150,
          status: SettlementStatus.completed,
        ),
        SettlementComputationInput(
          debtorUserId: 'bob',
          creditorUserId: 'alice',
          amountCents: 50,
          status: SettlementStatus.pending,
        ),
      ],
    );

    expect(result, const <BalanceResult>[
      BalanceResult(
        debtorUserId: 'bob',
        creditorUserId: 'alice',
        amountCents: 400,
      ),
      BalanceResult(
        debtorUserId: 'charlie',
        creditorUserId: 'alice',
        amountCents: 250,
      ),
    ]);
  });
}
