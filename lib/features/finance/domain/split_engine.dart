import 'package:hearth/features/finance/domain/finance_models.dart';

class SplitEngine {
  const SplitEngine();

  List<SplitAllocation> allocate({
    required int totalCents,
    required SplitRule rule,
  }) {
    if (totalCents <= 0) {
      throw StateError('Amount must be greater than zero.');
    }
    if (rule.participantUserIds.isEmpty) {
      throw StateError('At least one participant is required.');
    }

    return switch (rule) {
      EqualSplitRule() => _equal(totalCents, rule.participantUserIds),
      PercentageSplitRule() => _percentage(totalCents, rule),
      FixedSplitRule() => _fixed(totalCents, rule),
      ExemptionSplitRule() => _exemption(totalCents, rule),
      SplitRule() => throw StateError('Unsupported split rule type.'),
    };
  }

  List<SplitAllocation> _equal(int totalCents, List<String> participants) {
    final base = totalCents ~/ participants.length;
    final remainder = totalCents % participants.length;
    return List<SplitAllocation>.generate(participants.length, (int index) {
      return SplitAllocation(
        userId: participants[index],
        amountCents: base + (index < remainder ? 1 : 0),
      );
    });
  }

  List<SplitAllocation> _percentage(
    int totalCents,
    PercentageSplitRule rule,
  ) {
    final percentages = <String, int>{};
    for (final participant in rule.participantUserIds) {
      percentages[participant] = rule.percentages[participant] ?? 0;
    }
    final sum = percentages.values.fold<int>(0, (int left, int right) => left + right);
    if (sum != 100) {
      throw StateError('Percentages must add up to 100.');
    }

    final allocations = <SplitAllocation>[];
    final remainders = <({String userId, int remainder})>[];
    var allocated = 0;
    for (final participant in rule.participantUserIds) {
      final raw = totalCents * percentages[participant]!;
      final cents = raw ~/ 100;
      allocated += cents;
      allocations.add(SplitAllocation(userId: participant, amountCents: cents));
      remainders.add((userId: participant, remainder: raw % 100));
    }

    var remaining = totalCents - allocated;
    remainders.sort((left, right) => right.remainder.compareTo(left.remainder));
    final updated = allocations.toList();
    var index = 0;
    while (remaining > 0) {
      final target = remainders[index % remainders.length].userId;
      final targetIndex = updated.indexWhere(
        (SplitAllocation entry) => entry.userId == target,
      );
      updated[targetIndex] = SplitAllocation(
        userId: updated[targetIndex].userId,
        amountCents: updated[targetIndex].amountCents + 1,
      );
      remaining -= 1;
      index += 1;
    }
    return updated;
  }

  List<SplitAllocation> _fixed(int totalCents, FixedSplitRule rule) {
    final allocations = rule.participantUserIds
        .map(
          (String userId) => SplitAllocation(
            userId: userId,
            amountCents: rule.amountsCents[userId] ?? 0,
          ),
        )
        .toList();
    final sum = allocations.fold<int>(
      0,
      (int total, SplitAllocation entry) => total + entry.amountCents,
    );
    if (sum != totalCents) {
      throw StateError('Fixed allocations must equal the expense total exactly.');
    }
    return allocations;
  }

  List<SplitAllocation> _exemption(int totalCents, ExemptionSplitRule rule) {
    final eligible = rule.participantUserIds
        .where((String userId) => !rule.exemptUserIds.contains(userId))
        .toList();
    if (eligible.isEmpty) {
      throw StateError('At least one participant must remain after exemptions.');
    }
    final equal = _equal(totalCents, eligible);
    final allocations = <SplitAllocation>[];
    for (final participant in rule.participantUserIds) {
      final match = equal.where((SplitAllocation entry) => entry.userId == participant);
      allocations.add(
        SplitAllocation(
          userId: participant,
          amountCents: match.isEmpty ? 0 : match.first.amountCents,
        ),
      );
    }
    return allocations;
  }
}
