import 'dart:convert';

import 'package:equatable/equatable.dart';

enum FinanceCategory {
  housing,
  utilities,
  groceries,
  dining,
  transportation,
  subscriptions,
  maintenance,
  cleaning,
  family,
  pets,
  healthcare,
  other,
}

extension FinanceCategoryX on FinanceCategory {
  String get label => switch (this) {
    FinanceCategory.housing => 'Housing',
    FinanceCategory.utilities => 'Utilities',
    FinanceCategory.groceries => 'Groceries',
    FinanceCategory.dining => 'Dining',
    FinanceCategory.transportation => 'Transportation',
    FinanceCategory.subscriptions => 'Subscriptions',
    FinanceCategory.maintenance => 'Maintenance',
    FinanceCategory.cleaning => 'Cleaning',
    FinanceCategory.family => 'Family',
    FinanceCategory.pets => 'Pets',
    FinanceCategory.healthcare => 'Healthcare',
    FinanceCategory.other => 'Other',
  };

  static FinanceCategory fromName(String value) {
    return FinanceCategory.values.firstWhere(
      (FinanceCategory category) => category.name == value,
    );
  }
}

enum FinanceMemberRole { admin, member, observer }

extension FinanceMemberRoleX on FinanceMemberRole {
  String get label => switch (this) {
    FinanceMemberRole.admin => 'Admin',
    FinanceMemberRole.member => 'Member',
    FinanceMemberRole.observer => 'Observer',
  };

  static FinanceMemberRole fromName(String value) {
    return FinanceMemberRole.values.firstWhere(
      (FinanceMemberRole role) => role.name == value,
    );
  }
}

enum SplitRuleType { equal, percentage, fixed, exemption }

enum RecurrenceFrequency { weekly, monthly, quarterly, yearly }

enum SettlementStatus { pending, completed, cancelled }

class FinanceParticipant extends Equatable {
  const FinanceParticipant({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String email;
  final FinanceMemberRole role;

  bool get isObserver => role == FinanceMemberRole.observer;
  bool get isAdmin => role == FinanceMemberRole.admin;

  @override
  List<Object?> get props => <Object?>[userId, displayName, email, role];
}

class FinanceContext extends Equatable {
  const FinanceContext({
    required this.householdId,
    required this.currencyCode,
    required this.currentUserId,
    required this.currentUserRole,
    required this.participants,
  });

  final String householdId;
  final String currencyCode;
  final String currentUserId;
  final FinanceMemberRole currentUserRole;
  final List<FinanceParticipant> participants;

  bool get canEdit => currentUserRole != FinanceMemberRole.observer;
  bool get canManageBudgets => currentUserRole == FinanceMemberRole.admin;

  @override
  List<Object?> get props => <Object?>[
    householdId,
    currencyCode,
    currentUserId,
    currentUserRole,
    participants,
  ];
}

class SplitAllocation extends Equatable {
  const SplitAllocation({required this.userId, required this.amountCents});

  final String userId;
  final int amountCents;

  @override
  List<Object?> get props => <Object?>[userId, amountCents];
}

abstract class SplitRule extends Equatable {
  const SplitRule({required this.type, required this.participantUserIds});

  final SplitRuleType type;
  final List<String> participantUserIds;

  Map<String, Object?> toMap();

  String toJsonString() => jsonEncode(toMap());

  static SplitRule fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid split rule payload.');
    }
    final type = SplitRuleType.values.firstWhere(
      (SplitRuleType option) => option.name == decoded['type'],
    );
    final participants =
        (decoded['participantUserIds'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic value) => value as String)
            .toList();
    switch (type) {
      case SplitRuleType.equal:
        return EqualSplitRule(participantUserIds: participants);
      case SplitRuleType.percentage:
        return PercentageSplitRule(
          participantUserIds: participants,
          percentages:
              (decoded['percentages'] as Map<String, dynamic>? ??
                      const <String, dynamic>{})
                  .map(
                    (String key, dynamic value) =>
                        MapEntry<String, int>(key, value as int),
                  ),
        );
      case SplitRuleType.fixed:
        return FixedSplitRule(
          participantUserIds: participants,
          amountsCents:
              (decoded['amountsCents'] as Map<String, dynamic>? ??
                      const <String, dynamic>{})
                  .map(
                    (String key, dynamic value) =>
                        MapEntry<String, int>(key, value as int),
                  ),
        );
      case SplitRuleType.exemption:
        return ExemptionSplitRule(
          participantUserIds: participants,
          exemptUserIds:
              (decoded['exemptUserIds'] as List<dynamic>? ?? const <dynamic>[])
                  .map((dynamic value) => value as String)
                  .toList(),
        );
    }
  }
}

class EqualSplitRule extends SplitRule {
  const EqualSplitRule({required super.participantUserIds})
    : super(type: SplitRuleType.equal);

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.name,
      'participantUserIds': participantUserIds,
    };
  }

  @override
  List<Object?> get props => <Object?>[type, participantUserIds];
}

class PercentageSplitRule extends SplitRule {
  const PercentageSplitRule({
    required super.participantUserIds,
    required this.percentages,
  }) : super(type: SplitRuleType.percentage);

  final Map<String, int> percentages;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.name,
      'participantUserIds': participantUserIds,
      'percentages': percentages,
    };
  }

  @override
  List<Object?> get props => <Object?>[type, participantUserIds, percentages];
}

class FixedSplitRule extends SplitRule {
  const FixedSplitRule({
    required super.participantUserIds,
    required this.amountsCents,
  }) : super(type: SplitRuleType.fixed);

  final Map<String, int> amountsCents;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.name,
      'participantUserIds': participantUserIds,
      'amountsCents': amountsCents,
    };
  }

  @override
  List<Object?> get props => <Object?>[type, participantUserIds, amountsCents];
}

class ExemptionSplitRule extends SplitRule {
  const ExemptionSplitRule({
    required super.participantUserIds,
    required this.exemptUserIds,
  }) : super(type: SplitRuleType.exemption);

  final List<String> exemptUserIds;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.name,
      'participantUserIds': participantUserIds,
      'exemptUserIds': exemptUserIds,
    };
  }

  @override
  List<Object?> get props => <Object?>[type, participantUserIds, exemptUserIds];
}

class RecurrenceRule extends Equatable {
  const RecurrenceRule({required this.frequency, required this.anchorDate});

  final RecurrenceFrequency frequency;
  final DateTime anchorDate;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'frequency': frequency.name,
      'anchorDate': anchorDate.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toMap());

  static RecurrenceRule fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid recurrence payload.');
    }
    return RecurrenceRule(
      frequency: RecurrenceFrequency.values.firstWhere(
        (RecurrenceFrequency option) => option.name == decoded['frequency'],
      ),
      anchorDate: DateTime.parse(decoded['anchorDate'] as String),
    );
  }

  DateTime nextAfter(DateTime value) {
    return switch (frequency) {
      RecurrenceFrequency.weekly => value.add(const Duration(days: 7)),
      RecurrenceFrequency.monthly => _addMonths(value, 1),
      RecurrenceFrequency.quarterly => _addMonths(value, 3),
      RecurrenceFrequency.yearly => _addMonths(value, 12),
    };
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

  @override
  List<Object?> get props => <Object?>[frequency, anchorDate];
}

class ExpenseDraft extends Equatable {
  const ExpenseDraft({
    this.id,
    required this.householdId,
    required this.title,
    required this.amountCents,
    required this.category,
    required this.paidByUserId,
    required this.expenseDate,
    required this.splitRule,
    this.isRecurring = false,
    this.isRecurringTemplate = false,
    this.recurrenceRule,
    this.receiptReference,
    this.notes,
    this.sourceRecurringExpenseId,
    this.nextDueAt,
    this.lastGeneratedAt,
    this.isSettled = false,
  });

  final String? id;
  final String householdId;
  final String title;
  final int amountCents;
  final FinanceCategory category;
  final String paidByUserId;
  final DateTime expenseDate;
  final SplitRule splitRule;
  final bool isRecurring;
  final bool isRecurringTemplate;
  final RecurrenceRule? recurrenceRule;
  final String? receiptReference;
  final String? notes;
  final String? sourceRecurringExpenseId;
  final DateTime? nextDueAt;
  final DateTime? lastGeneratedAt;
  final bool isSettled;

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    title,
    amountCents,
    category,
    paidByUserId,
    expenseDate,
    splitRule,
    isRecurring,
    isRecurringTemplate,
    recurrenceRule,
    receiptReference,
    notes,
    sourceRecurringExpenseId,
    nextDueAt,
    lastGeneratedAt,
    isSettled,
  ];
}

class ExpenseEntity extends Equatable {
  const ExpenseEntity({
    required this.id,
    required this.householdId,
    required this.title,
    required this.amountCents,
    required this.category,
    required this.paidByUserId,
    required this.expenseDate,
    required this.splitRule,
    required this.isRecurring,
    required this.isRecurringTemplate,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.isSettled,
    this.recurrenceRule,
    this.receiptReference,
    this.notes,
    this.sourceRecurringExpenseId,
    this.nextDueAt,
    this.lastGeneratedAt,
    this.paidByDisplayName,
  });

  final String id;
  final String householdId;
  final String title;
  final int amountCents;
  final FinanceCategory category;
  final String paidByUserId;
  final DateTime expenseDate;
  final SplitRule splitRule;
  final bool isRecurring;
  final bool isRecurringTemplate;
  final RecurrenceRule? recurrenceRule;
  final String? receiptReference;
  final String? notes;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSettled;
  final String? sourceRecurringExpenseId;
  final DateTime? nextDueAt;
  final DateTime? lastGeneratedAt;
  final String? paidByDisplayName;

  bool get isGeneratedRecurringInstance =>
      sourceRecurringExpenseId != null && !isRecurringTemplate;

  ExpenseDraft toDraft() {
    return ExpenseDraft(
      id: id,
      householdId: householdId,
      title: title,
      amountCents: amountCents,
      category: category,
      paidByUserId: paidByUserId,
      expenseDate: expenseDate,
      splitRule: splitRule,
      isRecurring: isRecurring,
      isRecurringTemplate: isRecurringTemplate,
      recurrenceRule: recurrenceRule,
      receiptReference: receiptReference,
      notes: notes,
      sourceRecurringExpenseId: sourceRecurringExpenseId,
      nextDueAt: nextDueAt,
      lastGeneratedAt: lastGeneratedAt,
      isSettled: isSettled,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    title,
    amountCents,
    category,
    paidByUserId,
    expenseDate,
    splitRule,
    isRecurring,
    isRecurringTemplate,
    recurrenceRule,
    receiptReference,
    notes,
    createdByUserId,
    createdAt,
    updatedAt,
    isSettled,
    sourceRecurringExpenseId,
    nextDueAt,
    lastGeneratedAt,
    paidByDisplayName,
  ];
}

class BalanceEntity extends Equatable {
  const BalanceEntity({
    required this.id,
    required this.householdId,
    required this.debtorUserId,
    required this.creditorUserId,
    required this.amountCents,
    required this.lastUpdatedAt,
    required this.debtorDisplayName,
    required this.creditorDisplayName,
  });

  final String id;
  final String householdId;
  final String debtorUserId;
  final String creditorUserId;
  final int amountCents;
  final DateTime lastUpdatedAt;
  final String debtorDisplayName;
  final String creditorDisplayName;

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    debtorUserId,
    creditorUserId,
    amountCents,
    lastUpdatedAt,
    debtorDisplayName,
    creditorDisplayName,
  ];
}

class BalanceSummary extends Equatable {
  const BalanceSummary({
    required this.incomingCents,
    required this.outgoingCents,
  });

  final int incomingCents;
  final int outgoingCents;

  int get netCents => incomingCents - outgoingCents;

  @override
  List<Object?> get props => <Object?>[incomingCents, outgoingCents];
}

class CategoryBudgetEntity extends Equatable {
  const CategoryBudgetEntity({
    required this.id,
    required this.householdId,
    required this.category,
    required this.limitCents,
    required this.createdByUserId,
    required this.updatedAt,
  });

  final String id;
  final String householdId;
  final FinanceCategory category;
  final int limitCents;
  final String createdByUserId;
  final DateTime updatedAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    category,
    limitCents,
    createdByUserId,
    updatedAt,
  ];
}

class BudgetProgress extends Equatable {
  const BudgetProgress({
    required this.category,
    required this.spentCents,
    this.limitCents,
  });

  final FinanceCategory category;
  final int spentCents;
  final int? limitCents;

  double get progress {
    if (limitCents == null || limitCents == 0) {
      return 0;
    }
    return spentCents / limitCents!;
  }

  @override
  List<Object?> get props => <Object?>[category, spentCents, limitCents];
}

class SettlementEntity extends Equatable {
  const SettlementEntity({
    required this.id,
    required this.householdId,
    required this.debtorUserId,
    required this.creditorUserId,
    required this.amountCents,
    required this.status,
    required this.initiatedByUserId,
    required this.createdAt,
    required this.debtorDisplayName,
    required this.creditorDisplayName,
    this.confirmedByUserId,
    this.completedAt,
    this.cancelledAt,
    this.sourceExpenseId,
  });

  final String id;
  final String householdId;
  final String debtorUserId;
  final String creditorUserId;
  final int amountCents;
  final SettlementStatus status;
  final String initiatedByUserId;
  final String? confirmedByUserId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? sourceExpenseId;
  final String debtorDisplayName;
  final String creditorDisplayName;

  bool get isPending => status == SettlementStatus.pending;
  bool get isCompleted => status == SettlementStatus.completed;

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    debtorUserId,
    creditorUserId,
    amountCents,
    status,
    initiatedByUserId,
    confirmedByUserId,
    createdAt,
    completedAt,
    cancelledAt,
    sourceExpenseId,
    debtorDisplayName,
    creditorDisplayName,
  ];
}

enum FinanceActivityType { expense, settlement }

class FinanceActivityItem extends Equatable {
  const FinanceActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amountCents,
    required this.occurredAt,
    this.expenseId,
  });

  final String id;
  final FinanceActivityType type;
  final String title;
  final String subtitle;
  final int amountCents;
  final DateTime occurredAt;
  final String? expenseId;

  @override
  List<Object?> get props => <Object?>[
    id,
    type,
    title,
    subtitle,
    amountCents,
    occurredAt,
    expenseId,
  ];
}

class FinanceHomeSummary extends Equatable {
  const FinanceHomeSummary({
    required this.dueBillsThisWeek,
    required this.openBalanceCount,
  });

  final int dueBillsThisWeek;
  final int openBalanceCount;

  @override
  List<Object?> get props => <Object?>[dueBillsThisWeek, openBalanceCount];
}

class FinanceDashboardData extends Equatable {
  const FinanceDashboardData({
    required this.summary,
    required this.balances,
    required this.recentExpenses,
    required this.pendingSettlements,
  });

  final BalanceSummary summary;
  final List<BalanceEntity> balances;
  final List<ExpenseEntity> recentExpenses;
  final List<SettlementEntity> pendingSettlements;

  @override
  List<Object?> get props => <Object?>[
    summary,
    balances,
    recentExpenses,
    pendingSettlements,
  ];
}
