import 'package:equatable/equatable.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/finance/domain/split_engine.dart';

class BalanceComputationInput {
  const BalanceComputationInput({
    required this.id,
    required this.paidByUserId,
    required this.amountCents,
    required this.splitRule,
    required this.isRecurringTemplate,
  });

  final String id;
  final String paidByUserId;
  final int amountCents;
  final SplitRule splitRule;
  final bool isRecurringTemplate;
}

class SettlementComputationInput {
  const SettlementComputationInput({
    required this.debtorUserId,
    required this.creditorUserId,
    required this.amountCents,
    required this.status,
  });

  final String debtorUserId;
  final String creditorUserId;
  final int amountCents;
  final SettlementStatus status;
}

class BalanceResult extends Equatable {
  const BalanceResult({
    required this.debtorUserId,
    required this.creditorUserId,
    required this.amountCents,
  });

  final String debtorUserId;
  final String creditorUserId;
  final int amountCents;

  @override
  List<Object?> get props => <Object?>[debtorUserId, creditorUserId, amountCents];
}

class BalanceEngine {
  const BalanceEngine({
    this.splitEngine = const SplitEngine(),
  });

  final SplitEngine splitEngine;

  List<BalanceResult> compute({
    required List<BalanceComputationInput> expenses,
    required List<SettlementComputationInput> settlements,
  }) {
    final obligations = <String, int>{};

    void add(String debtor, String creditor, int amount) {
      if (debtor == creditor || amount == 0) {
        return;
      }
      final key = '$debtor::$creditor';
      obligations[key] = (obligations[key] ?? 0) + amount;
    }

    for (final expense in expenses.where((BalanceComputationInput entry) => !entry.isRecurringTemplate)) {
      final allocations = splitEngine.allocate(
        totalCents: expense.amountCents,
        rule: expense.splitRule,
      );
      for (final allocation in allocations) {
        if (allocation.userId == expense.paidByUserId || allocation.amountCents == 0) {
          continue;
        }
        add(allocation.userId, expense.paidByUserId, allocation.amountCents);
      }
    }

    for (final settlement in settlements.where(
      (SettlementComputationInput entry) => entry.status == SettlementStatus.completed,
    )) {
      add(settlement.debtorUserId, settlement.creditorUserId, -settlement.amountCents);
    }

    final results = <BalanceResult>[];
    final visited = <String>{};
    for (final entry in obligations.entries) {
      final parts = entry.key.split('::');
      final left = parts[0];
      final right = parts[1];
      final key = '$left::$right';
      final reverseKey = '$right::$left';
      if (visited.contains(key) || visited.contains(reverseKey)) {
        continue;
      }
      final forward = obligations[key] ?? 0;
      final reverse = obligations[reverseKey] ?? 0;
      final net = forward - reverse;
      if (net > 0) {
        results.add(
          BalanceResult(
            debtorUserId: left,
            creditorUserId: right,
            amountCents: net,
          ),
        );
      } else if (net < 0) {
        results.add(
          BalanceResult(
            debtorUserId: right,
            creditorUserId: left,
            amountCents: -net,
          ),
        );
      }
      visited.add(key);
      visited.add(reverseKey);
    }
    results.sort((BalanceResult left, BalanceResult right) {
      final debtorCompare = left.debtorUserId.compareTo(right.debtorUserId);
      if (debtorCompare != 0) {
        return debtorCompare;
      }
      return left.creditorUserId.compareTo(right.creditorUserId);
    });
    return results;
  }
}
