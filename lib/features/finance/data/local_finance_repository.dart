import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/finance/data/tables.dart';
import 'package:hearth/features/finance/domain/balance_engine.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/finance/domain/finance_repository.dart';
import 'package:hearth/features/finance/domain/split_engine.dart';
import 'package:uuid/uuid.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((Ref ref) {
  return LocalFinanceRepository(
    database: ref.read(appDatabaseProvider),
    uuid: const Uuid(),
  );
});

class LocalFinanceRepository implements FinanceRepository {
  LocalFinanceRepository({
    required AppDatabase database,
    required Uuid uuid,
    SplitEngine splitEngine = const SplitEngine(),
    BalanceEngine balanceEngine = const BalanceEngine(),
  })  : _database = database,
        _uuid = uuid,
        _splitEngine = splitEngine,
        _balanceEngine = balanceEngine;

  final AppDatabase _database;
  final Uuid _uuid;
  final SplitEngine _splitEngine;
  final BalanceEngine _balanceEngine;

  @override
  Future<FinanceContext?> getContext({
    required String householdId,
    required String userId,
  }) async {
    final household = await (_database.select(
      _database.households,
    )..where((row) => row.id.equals(householdId))).getSingleOrNull();
    if (household == null) {
      return null;
    }
    final participants = await _participantsForHousehold(householdId);
    final currentUser = participants.where(
      (FinanceParticipant participant) => participant.userId == userId,
    );
    if (currentUser.isEmpty) {
      return null;
    }
    return FinanceContext(
      householdId: householdId,
      currencyCode: household.currencyCode,
      currentUserId: userId,
      currentUserRole: currentUser.first.role,
      participants: participants,
    );
  }

  @override
  Future<FinanceDashboardData> getDashboard({
    required String householdId,
    required String userId,
  }) async {
    final balances = await getBalances(householdId: householdId);
    final summary = await getBalanceSummary(
      householdId: householdId,
      userId: userId,
    );
    final pendingSettlements = await _pendingSettlementsForHousehold(householdId);
    final visiblePending = pendingSettlements
        .where(
          (SettlementEntity settlement) =>
              settlement.debtorUserId == userId ||
              settlement.creditorUserId == userId,
        )
        .toList();
    return FinanceDashboardData(
      summary: summary,
      balances: balances,
      recentExpenses: await getRecentExpenses(householdId: householdId),
      pendingSettlements: visiblePending,
    );
  }

  @override
  Future<FinanceHomeSummary> getHomeSummary({
    required String householdId,
    required String userId,
  }) async {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    final dueTemplates = await (_database.select(_database.expenses)
          ..where(
            (Expenses row) =>
                row.householdId.equals(householdId) &
                row.isRecurringTemplate.equals(true) &
                row.nextDueAt.isBiggerOrEqualValue(now) &
                row.nextDueAt.isSmallerOrEqualValue(weekFromNow),
          ))
        .get();
    final balances = await getBalances(householdId: householdId);
    final openBalanceCount = balances
        .where(
          (BalanceEntity balance) =>
              balance.debtorUserId == userId || balance.creditorUserId == userId,
        )
        .length;
    return FinanceHomeSummary(
      dueBillsThisWeek: dueTemplates.length,
      openBalanceCount: openBalanceCount,
    );
  }

  @override
  Future<List<FinanceActivityItem>> getRecentActivity({
    required String householdId,
    int limit = 10,
  }) async {
    final expenses = await getRecentExpenses(householdId: householdId, limit: limit);
    final settlements = await (_database.select(_database.settlements)
          ..where(
            (Settlements row) =>
                row.householdId.equals(householdId) &
                row.status.equals(SettlementStatus.completed.name),
          )
          ..orderBy(<OrderingTerm Function(Settlements)>[
            (Settlements row) => OrderingTerm.desc(row.completedAt),
            (Settlements row) => OrderingTerm.desc(row.createdAt),
          ])
          ..limit(limit))
        .get();
    final participantMap = await _participantNameMap(householdId);
    final items = <FinanceActivityItem>[
      ...expenses.map(
        (ExpenseEntity expense) => FinanceActivityItem(
          id: expense.id,
          type: FinanceActivityType.expense,
          title: expense.title,
          subtitle:
              '${expense.paidByDisplayName ?? participantMap[expense.paidByUserId] ?? 'Someone'} covered ${expense.category.label}',
          amountCents: expense.amountCents,
          occurredAt: expense.expenseDate,
          expenseId: expense.id,
        ),
      ),
      ...settlements.map(
        (Settlement settlement) => FinanceActivityItem(
          id: settlement.id,
          type: FinanceActivityType.settlement,
          title: 'Settlement completed',
          subtitle:
              '${participantMap[settlement.debtorUserId] ?? 'Someone'} settled with ${participantMap[settlement.creditorUserId] ?? 'someone'}',
          amountCents: settlement.amountCents,
          occurredAt: settlement.completedAt ?? settlement.createdAt,
        ),
      ),
    ]
      ..sort(
        (FinanceActivityItem left, FinanceActivityItem right) =>
            right.occurredAt.compareTo(left.occurredAt),
      );
    if (items.length > limit) {
      return items.take(limit).toList();
    }
    return items;
  }

  @override
  Future<List<ExpenseEntity>> getRecentExpenses({
    required String householdId,
    int limit = 20,
  }) async {
    final payerAlias = _database.alias(_database.users, 'payer_expenses');
    final query = _database.select(_database.expenses).join([
      leftOuterJoin(
        payerAlias,
        payerAlias.id.equalsExp(_database.expenses.paidByUserId),
      ),
    ])
      ..where(
        _database.expenses.householdId.equals(householdId) &
            _database.expenses.isRecurringTemplate.equals(false),
      )
      ..orderBy(<OrderingTerm>[
        OrderingTerm.desc(_database.expenses.expenseDate),
        OrderingTerm.desc(_database.expenses.createdAt),
      ])
      ..limit(limit);
    final rows = await query.get();
    return rows
        .map(
          (TypedResult row) => _mapExpense(
            row.readTable(_database.expenses),
            paidByDisplayName: row.readTableOrNull(payerAlias)?.displayName,
          ),
        )
        .toList();
  }

  @override
  Future<List<ExpenseEntity>> getRecurringTemplates({
    required String householdId,
  }) async {
    final payerAlias = _database.alias(_database.users, 'payer_templates');
    final query = _database.select(_database.expenses).join([
      leftOuterJoin(
        payerAlias,
        payerAlias.id.equalsExp(_database.expenses.paidByUserId),
      ),
    ])
      ..where(
        _database.expenses.householdId.equals(householdId) &
            _database.expenses.isRecurringTemplate.equals(true),
      );
    final rows = await query.get();
    final templates = rows
        .map(
          (TypedResult row) => _mapExpense(
            row.readTable(_database.expenses),
            paidByDisplayName: row.readTableOrNull(payerAlias)?.displayName,
          ),
        )
        .toList()
      ..sort((ExpenseEntity left, ExpenseEntity right) {
        final leftDue = left.nextDueAt;
        final rightDue = right.nextDueAt;
        if (leftDue == null && rightDue == null) {
          return left.title.compareTo(right.title);
        }
        if (leftDue == null) {
          return 1;
        }
        if (rightDue == null) {
          return -1;
        }
        return leftDue.compareTo(rightDue);
      });
    return templates;
  }

  @override
  Future<ExpenseEntity?> getExpenseById(String expenseId) async {
    final payerAlias = _database.alias(_database.users, 'payer_detail');
    final query = _database.select(_database.expenses).join([
      leftOuterJoin(
        payerAlias,
        payerAlias.id.equalsExp(_database.expenses.paidByUserId),
      ),
    ])
      ..where(_database.expenses.id.equals(expenseId));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapExpense(
      row.readTable(_database.expenses),
      paidByDisplayName: row.readTableOrNull(payerAlias)?.displayName,
    );
  }

  @override
  Future<List<BalanceEntity>> getBalances({
    required String householdId,
  }) async {
    final debtorAlias = _database.alias(_database.users, 'debtor');
    final creditorAlias = _database.alias(_database.users, 'creditor');
    final query = _database.select(_database.balances).join([
      leftOuterJoin(
        debtorAlias,
        debtorAlias.id.equalsExp(_database.balances.debtorUserId),
      ),
      leftOuterJoin(
        creditorAlias,
        creditorAlias.id.equalsExp(_database.balances.creditorUserId),
      ),
    ])
      ..where(_database.balances.householdId.equals(householdId))
      ..orderBy(<OrderingTerm>[
        OrderingTerm.desc(_database.balances.amountCents),
      ]);
    final rows = await query.get();
    return rows
        .map(
          (TypedResult row) => BalanceEntity(
            id: row.readTable(_database.balances).id,
            householdId: row.readTable(_database.balances).householdId,
            debtorUserId: row.readTable(_database.balances).debtorUserId,
            creditorUserId: row.readTable(_database.balances).creditorUserId,
            amountCents: row.readTable(_database.balances).amountCents,
            lastUpdatedAt: row.readTable(_database.balances).lastUpdatedAt,
            debtorDisplayName:
                row.readTableOrNull(debtorAlias)?.displayName ?? 'Unknown',
            creditorDisplayName:
                row.readTableOrNull(creditorAlias)?.displayName ?? 'Unknown',
          ),
        )
        .toList();
  }

  @override
  Future<BalanceSummary> getBalanceSummary({
    required String householdId,
    required String userId,
  }) async {
    final balances = await getBalances(householdId: householdId);
    var incoming = 0;
    var outgoing = 0;
    for (final balance in balances) {
      if (balance.creditorUserId == userId) {
        incoming += balance.amountCents;
      } else if (balance.debtorUserId == userId) {
        outgoing += balance.amountCents;
      }
    }
    return BalanceSummary(incomingCents: incoming, outgoingCents: outgoing);
  }

  @override
  Future<List<BudgetProgress>> getBudgetProgress({
    required String householdId,
  }) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);
    final startOfNextMonth = DateTime(now.year, now.month + 1);
    final budgetRows = await (_database.select(
      _database.categoryBudgets,
    )..where((CategoryBudgets row) => row.householdId.equals(householdId))).get();
    final expenseRows = await (_database.select(_database.expenses)
          ..where(
            (Expenses row) =>
                row.householdId.equals(householdId) &
                row.isRecurringTemplate.equals(false) &
                row.expenseDate.isBiggerOrEqualValue(startOfMonth) &
                row.expenseDate.isSmallerThanValue(startOfNextMonth),
          ))
        .get();

    final budgetMap = <FinanceCategory, int>{};
    for (final budget in budgetRows) {
      budgetMap[FinanceCategoryX.fromName(budget.category)] = budget.limitCents;
    }

    final spentMap = <FinanceCategory, int>{};
    for (final expense in expenseRows) {
      final category = FinanceCategoryX.fromName(expense.category);
      spentMap[category] = (spentMap[category] ?? 0) + expense.amountCents;
    }

    return FinanceCategory.values
        .map(
          (FinanceCategory category) => BudgetProgress(
            category: category,
            spentCents: spentMap[category] ?? 0,
            limitCents: budgetMap[category],
          ),
        )
        .toList();
  }

  @override
  Future<List<SettlementEntity>> getSettlementsForPair({
    required String householdId,
    required String debtorUserId,
    required String creditorUserId,
  }) async {
    final rows = await (_database.select(_database.settlements)
          ..where(
            (Settlements row) =>
                row.householdId.equals(householdId) &
                row.debtorUserId.equals(debtorUserId) &
                row.creditorUserId.equals(creditorUserId),
          )
          ..orderBy(<OrderingTerm Function(Settlements)>[
            (Settlements row) => OrderingTerm.desc(row.createdAt),
          ]))
        .get();
    final participantMap = await _participantNameMap(householdId);
    return rows
        .map((Settlement row) => _mapSettlement(row, participantMap))
        .toList();
  }

  @override
  Future<SettlementEntity?> getPendingSettlementForPair({
    required String householdId,
    required String debtorUserId,
    required String creditorUserId,
  }) async {
    final row = await (_database.select(_database.settlements)
          ..where(
            (Settlements settlement) =>
                settlement.householdId.equals(householdId) &
                settlement.debtorUserId.equals(debtorUserId) &
                settlement.creditorUserId.equals(creditorUserId) &
                settlement.status.equals(SettlementStatus.pending.name),
          )
          ..orderBy(<OrderingTerm Function(Settlements)>[
            (Settlements settlement) => OrderingTerm.desc(settlement.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    final participantMap = await _participantNameMap(householdId);
    return _mapSettlement(row, participantMap);
  }

  @override
  Future<ExpenseEntity> addExpense({
    required String actorUserId,
    required ExpenseDraft draft,
  }) async {
    final actorRole = await _roleFor(draft.householdId, actorUserId);
    if (actorRole == FinanceMemberRole.observer) {
      throw StateError('Observers cannot add expenses.');
    }
    _splitEngine.allocate(totalCents: draft.amountCents, rule: draft.splitRule);

    final now = DateTime.now();
    final expenseId = _uuid.v4();
    await _database.into(_database.expenses).insert(
          ExpensesCompanion.insert(
            id: expenseId,
            householdId: draft.householdId,
            title: draft.title.trim(),
            amountCents: draft.amountCents,
            category: draft.category.name,
            paidByUserId: draft.paidByUserId,
            expenseDate: draft.expenseDate,
            splitRuleJson: draft.splitRule.toJsonString(),
            isRecurring: Value<bool>(draft.isRecurring),
            isRecurringTemplate: Value<bool>(draft.isRecurringTemplate),
            recurrenceRuleJson: Value<String?>(draft.recurrenceRule?.toJsonString()),
            receiptReference: Value<String?>(draft.receiptReference),
            notes: Value<String?>(draft.notes),
            createdBy: actorUserId,
            createdAt: now,
            updatedAt: now,
            isSettled: Value<bool>(draft.isSettled),
            sourceRecurringExpenseId: Value<String?>(draft.sourceRecurringExpenseId),
            nextDueAt: Value<DateTime?>(draft.nextDueAt),
            lastGeneratedAt: Value<DateTime?>(draft.lastGeneratedAt),
          ),
        );

    if (draft.isRecurringTemplate) {
      await reconcileRecurringBillsOnLaunch(draft.householdId);
    } else {
      await _recomputeBalances(draft.householdId);
    }

    final created = await getExpenseById(expenseId);
    if (created == null) {
      throw StateError('Expense could not be loaded after creation.');
    }
    return created;
  }

  @override
  Future<ExpenseEntity> updateExpense({
    required String actorUserId,
    required ExpenseDraft draft,
  }) async {
    if (draft.id == null) {
      throw StateError('Expense id is required for updates.');
    }
    final existing = await getExpenseById(draft.id!);
    if (existing == null) {
      throw StateError('Expense not found.');
    }
    if (existing.createdByUserId != actorUserId) {
      throw StateError('Only the expense owner can edit this record.');
    }

    _splitEngine.allocate(totalCents: draft.amountCents, rule: draft.splitRule);
    final now = DateTime.now();
    final effectiveNextDue = draft.isRecurringTemplate
        ? _effectiveNextDue(existing, draft)
        : draft.nextDueAt;

    await (_database.update(
      _database.expenses,
    )..where((Expenses row) => row.id.equals(draft.id!))).write(
      ExpensesCompanion(
        title: Value<String>(draft.title.trim()),
        amountCents: Value<int>(draft.amountCents),
        category: Value<String>(draft.category.name),
        paidByUserId: Value<String>(draft.paidByUserId),
        expenseDate: Value<DateTime>(draft.expenseDate),
        splitRuleJson: Value<String>(draft.splitRule.toJsonString()),
        isRecurring: Value<bool>(draft.isRecurring),
        isRecurringTemplate: Value<bool>(draft.isRecurringTemplate),
        recurrenceRuleJson: Value<String?>(draft.recurrenceRule?.toJsonString()),
        receiptReference: Value<String?>(draft.receiptReference),
        notes: Value<String?>(draft.notes),
        updatedAt: Value<DateTime>(now),
        nextDueAt: Value<DateTime?>(effectiveNextDue),
      ),
    );

    if (existing.isRecurringTemplate || draft.isRecurringTemplate) {
      await reconcileRecurringBillsOnLaunch(draft.householdId);
    } else {
      await _recomputeBalances(draft.householdId);
    }

    final updated = await getExpenseById(draft.id!);
    if (updated == null) {
      throw StateError('Expense could not be loaded after update.');
    }
    return updated;
  }

  @override
  Future<void> deleteExpense({
    required String actorUserId,
    required String expenseId,
  }) async {
    final existing = await getExpenseById(expenseId);
    if (existing == null) {
      throw StateError('Expense not found.');
    }
    if (existing.createdByUserId != actorUserId) {
      throw StateError('Only the expense owner can delete this record.');
    }
    await (_database.delete(
      _database.expenses,
    )..where((Expenses row) => row.id.equals(expenseId))).go();
    if (existing.isRecurringTemplate) {
      await reconcileRecurringBillsOnLaunch(existing.householdId);
    } else {
      await _recomputeBalances(existing.householdId);
    }
  }

  @override
  Future<void> setBudget({
    required String actorUserId,
    required String householdId,
    required FinanceCategory category,
    required int? limitCents,
  }) async {
    final actorRole = await _roleFor(householdId, actorUserId);
    if (actorRole != FinanceMemberRole.admin) {
      throw StateError('Only admins can edit budgets.');
    }
    final existing = await (_database.select(_database.categoryBudgets)
          ..where(
            (CategoryBudgets row) =>
                row.householdId.equals(householdId) &
                row.category.equals(category.name),
          ))
        .getSingleOrNull();
    if (limitCents == null || limitCents <= 0) {
      if (existing != null) {
        await (_database.delete(
          _database.categoryBudgets,
        )..where((CategoryBudgets row) => row.id.equals(existing.id))).go();
      }
      return;
    }
    final now = DateTime.now();
    if (existing == null) {
      await _database.into(_database.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              id: _uuid.v4(),
              householdId: householdId,
              category: category.name,
              limitCents: limitCents,
              createdByUserId: actorUserId,
              updatedAt: now,
            ),
          );
      return;
    }
    await (_database.update(
      _database.categoryBudgets,
    )..where((CategoryBudgets row) => row.id.equals(existing.id))).write(
      CategoryBudgetsCompanion(
        limitCents: Value<int>(limitCents),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  @override
  Future<SettlementEntity> requestSettlement({
    required String actorUserId,
    required String householdId,
    required String debtorUserId,
    required String creditorUserId,
    required int amountCents,
    String? sourceExpenseId,
  }) async {
    if (amountCents <= 0) {
      throw StateError('Settlement amount must be greater than zero.');
    }
    if (actorUserId != debtorUserId && actorUserId != creditorUserId) {
      throw StateError('Only the debtor or creditor can request settlement.');
    }
    final currentBalance = await _balanceForPair(
      householdId: householdId,
      debtorUserId: debtorUserId,
      creditorUserId: creditorUserId,
    );
    if (currentBalance == null || currentBalance.amountCents < amountCents) {
      throw StateError('Settlement exceeds the current outstanding balance.');
    }
    final pending = await getPendingSettlementForPair(
      householdId: householdId,
      debtorUserId: debtorUserId,
      creditorUserId: creditorUserId,
    );
    if (pending != null) {
      throw StateError('A settlement is already waiting for confirmation.');
    }
    final now = DateTime.now();
    final settlementId = _uuid.v4();
    await _database.into(_database.settlements).insert(
          SettlementsCompanion.insert(
            id: settlementId,
            householdId: householdId,
            debtorUserId: debtorUserId,
            creditorUserId: creditorUserId,
            amountCents: amountCents,
            status: SettlementStatus.pending.name,
            initiatedByUserId: actorUserId,
            createdAt: now,
            sourceExpenseId: Value<String?>(sourceExpenseId),
          ),
        );
    final participantMap = await _participantNameMap(householdId);
    final row = await (_database.select(
      _database.settlements,
    )..where((Settlements settlement) => settlement.id.equals(settlementId))).getSingle();
    return _mapSettlement(row, participantMap);
  }

  @override
  Future<SettlementEntity> confirmSettlement({
    required String actorUserId,
    required String settlementId,
  }) async {
    final settlement = await (_database.select(
      _database.settlements,
    )..where((Settlements row) => row.id.equals(settlementId))).getSingleOrNull();
    if (settlement == null) {
      throw StateError('Settlement not found.');
    }
    if (settlement.status != SettlementStatus.pending.name) {
      throw StateError('Only pending settlements can be confirmed.');
    }
    if (actorUserId != settlement.debtorUserId && actorUserId != settlement.creditorUserId) {
      throw StateError('Only the debtor or creditor can confirm settlement.');
    }
    if (actorUserId == settlement.initiatedByUserId) {
      throw StateError('The counterparty must provide the second confirmation.');
    }

    final currentBalance = await _balanceForPair(
      householdId: settlement.householdId,
      debtorUserId: settlement.debtorUserId,
      creditorUserId: settlement.creditorUserId,
    );
    if (currentBalance == null || currentBalance.amountCents < settlement.amountCents) {
      throw StateError('The outstanding balance has changed. Start a new settlement.');
    }

    final now = DateTime.now();
    await (_database.update(
      _database.settlements,
    )..where((Settlements row) => row.id.equals(settlementId))).write(
      SettlementsCompanion(
        status: Value<String>(SettlementStatus.completed.name),
        confirmedByUserId: Value<String>(actorUserId),
        completedAt: Value<DateTime>(now),
      ),
    );
    await _recomputeBalances(settlement.householdId);
    final participantMap = await _participantNameMap(settlement.householdId);
    final updated = await (_database.select(
      _database.settlements,
    )..where((Settlements row) => row.id.equals(settlementId))).getSingle();
    return _mapSettlement(updated, participantMap);
  }

  @override
  Future<void> cancelSettlement({
    required String actorUserId,
    required String settlementId,
  }) async {
    final settlement = await (_database.select(
      _database.settlements,
    )..where((Settlements row) => row.id.equals(settlementId))).getSingleOrNull();
    if (settlement == null) {
      throw StateError('Settlement not found.');
    }
    if (settlement.status != SettlementStatus.pending.name) {
      throw StateError('Only pending settlements can be cancelled.');
    }
    if (actorUserId != settlement.debtorUserId && actorUserId != settlement.creditorUserId) {
      throw StateError('Only the debtor or creditor can cancel settlement.');
    }
    await (_database.update(
      _database.settlements,
    )..where((Settlements row) => row.id.equals(settlementId))).write(
      SettlementsCompanion(
        status: Value<String>(SettlementStatus.cancelled.name),
        cancelledAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> reconcileRecurringBillsOnLaunch(String householdId) async {
    final templates = await (_database.select(_database.expenses)
          ..where(
            (Expenses row) =>
                row.householdId.equals(householdId) &
                row.isRecurringTemplate.equals(true),
          ))
        .get();
    if (templates.isEmpty) {
      return;
    }

    var generatedAny = false;
    final now = DateTime.now();
    await _database.transaction(() async {
      for (final template in templates) {
        final recurrence = template.recurrenceRuleJson == null
            ? null
            : RecurrenceRule.fromJsonString(template.recurrenceRuleJson!);
        if (recurrence == null) {
          continue;
        }
        var nextDue = template.nextDueAt ?? template.expenseDate;
        var lastGeneratedAt = template.lastGeneratedAt;
        while (!nextDue.isAfter(now)) {
          await _database.into(_database.expenses).insert(
                ExpensesCompanion.insert(
                  id: _uuid.v4(),
                  householdId: template.householdId,
                  title: template.title,
                  amountCents: template.amountCents,
                  category: template.category,
                  paidByUserId: template.paidByUserId,
                  expenseDate: nextDue,
                  splitRuleJson: template.splitRuleJson,
                  isRecurring: const Value<bool>(true),
                  isRecurringTemplate: const Value<bool>(false),
                  recurrenceRuleJson: Value<String?>(template.recurrenceRuleJson),
                  receiptReference: Value<String?>(template.receiptReference),
                  notes: Value<String?>(template.notes),
                  createdBy: template.createdBy,
                  createdAt: now,
                  updatedAt: now,
                  isSettled: const Value<bool>(false),
                  sourceRecurringExpenseId: Value<String?>(template.id),
                ),
              );
          generatedAny = true;
          lastGeneratedAt = nextDue;
          nextDue = recurrence.nextAfter(nextDue);
        }
        await (_database.update(
          _database.expenses,
        )..where((Expenses row) => row.id.equals(template.id))).write(
          ExpensesCompanion(
            nextDueAt: Value<DateTime?>(nextDue),
            lastGeneratedAt: Value<DateTime?>(lastGeneratedAt),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }
    });
    if (generatedAny) {
      await _recomputeBalances(householdId);
    }
  }

  Future<List<FinanceParticipant>> _participantsForHousehold(String householdId) async {
    final query = _database.select(_database.householdMemberships).join([
      innerJoin(
        _database.users,
        _database.users.id.equalsExp(_database.householdMemberships.userId),
      ),
    ])
      ..where(_database.householdMemberships.householdId.equals(householdId));
    final rows = await query.get();
    final participants = rows
        .map(
          (TypedResult row) => FinanceParticipant(
            userId: row.readTable(_database.users).id,
            displayName: row.readTable(_database.users).displayName,
            email: row.readTable(_database.users).email,
            role: FinanceMemberRoleX.fromName(
              row.readTable(_database.householdMemberships).role,
            ),
          ),
        )
        .toList()
      ..sort(
        (FinanceParticipant left, FinanceParticipant right) =>
            left.displayName.compareTo(right.displayName),
      );
    return participants;
  }

  Future<Map<String, String>> _participantNameMap(String householdId) async {
    final participants = await _participantsForHousehold(householdId);
    return <String, String>{
      for (final participant in participants) participant.userId: participant.displayName,
    };
  }

  Future<FinanceMemberRole> _roleFor(String householdId, String userId) async {
    final membership = await (_database.select(_database.householdMemberships)
          ..where(
            (row) =>
                row.householdId.equals(householdId) & row.userId.equals(userId),
          ))
        .getSingleOrNull();
    if (membership == null) {
      throw StateError('Household access could not be verified.');
    }
    return FinanceMemberRoleX.fromName(membership.role);
  }

  Future<List<SettlementEntity>> _pendingSettlementsForHousehold(String householdId) async {
    final rows = await (_database.select(_database.settlements)
          ..where(
            (Settlements row) =>
                row.householdId.equals(householdId) &
                row.status.equals(SettlementStatus.pending.name),
          ))
        .get();
    final participantMap = await _participantNameMap(householdId);
    return rows.map((Settlement row) => _mapSettlement(row, participantMap)).toList();
  }

  Future<BalanceEntity?> _balanceForPair({
    required String householdId,
    required String debtorUserId,
    required String creditorUserId,
  }) async {
    final balances = await getBalances(householdId: householdId);
    final match = balances.where(
      (BalanceEntity balance) =>
          balance.debtorUserId == debtorUserId &&
          balance.creditorUserId == creditorUserId,
    );
    return match.isEmpty ? null : match.first;
  }

  DateTime? _effectiveNextDue(ExpenseEntity existing, ExpenseDraft draft) {
    if (!draft.isRecurringTemplate || draft.recurrenceRule == null) {
      return draft.nextDueAt;
    }
    if (existing.lastGeneratedAt == null) {
      return draft.expenseDate;
    }
    return draft.recurrenceRule!.nextAfter(existing.lastGeneratedAt!);
  }

  Future<void> _recomputeBalances(String householdId) async {
    final expenses = await (_database.select(_database.expenses)
          ..where((Expenses row) => row.householdId.equals(householdId)))
        .get();
    final settlements = await (_database.select(_database.settlements)
          ..where((Settlements row) => row.householdId.equals(householdId)))
        .get();
    final computed = _balanceEngine.compute(
      expenses: expenses
          .map(
            (Expense expense) => BalanceComputationInput(
              id: expense.id,
              paidByUserId: expense.paidByUserId,
              amountCents: expense.amountCents,
              splitRule: SplitRule.fromJsonString(expense.splitRuleJson),
              isRecurringTemplate: expense.isRecurringTemplate,
            ),
          )
          .toList(),
      settlements: settlements
          .map(
            (Settlement settlement) => SettlementComputationInput(
              debtorUserId: settlement.debtorUserId,
              creditorUserId: settlement.creditorUserId,
              amountCents: settlement.amountCents,
              status: SettlementStatus.values.firstWhere(
                (SettlementStatus status) => status.name == settlement.status,
              ),
            ),
          )
          .toList(),
    );

    final now = DateTime.now();
    await _database.transaction(() async {
      await (_database.delete(
        _database.balances,
      )..where((Balances row) => row.householdId.equals(householdId))).go();
      for (final balance in computed.where((BalanceResult entry) => entry.amountCents > 0)) {
        await _database.into(_database.balances).insert(
              BalancesCompanion.insert(
                id: _uuid.v4(),
                householdId: householdId,
                debtorUserId: balance.debtorUserId,
                creditorUserId: balance.creditorUserId,
                amountCents: balance.amountCents,
                lastUpdatedAt: now,
              ),
            );
      }
    });
    await _refreshExpenseSettlementFlags(householdId);
  }

  Future<void> _refreshExpenseSettlementFlags(String householdId) async {
    final expenses = await (_database.select(_database.expenses)
          ..where(
            (Expenses row) =>
                row.householdId.equals(householdId) &
                row.isRecurringTemplate.equals(false),
          ))
        .get();
    final balances = await (_database.select(_database.balances)
          ..where((Balances row) => row.householdId.equals(householdId)))
        .get();
    final balanceMap = <String, int>{
      for (final balance in balances)
        '${balance.debtorUserId}::${balance.creditorUserId}': balance.amountCents,
    };

    for (final expense in expenses) {
      final allocations = _splitEngine.allocate(
        totalCents: expense.amountCents,
        rule: SplitRule.fromJsonString(expense.splitRuleJson),
      );
      final unsettled = allocations.any((SplitAllocation allocation) {
        if (allocation.userId == expense.paidByUserId || allocation.amountCents == 0) {
          return false;
        }
        final key = '${allocation.userId}::${expense.paidByUserId}';
        return (balanceMap[key] ?? 0) > 0;
      });
      await (_database.update(
        _database.expenses,
      )..where((Expenses row) => row.id.equals(expense.id))).write(
        ExpensesCompanion(isSettled: Value<bool>(!unsettled)),
      );
    }
  }

  ExpenseEntity _mapExpense(
    Expense row, {
    String? paidByDisplayName,
  }) {
    return ExpenseEntity(
      id: row.id,
      householdId: row.householdId,
      title: row.title,
      amountCents: row.amountCents,
      category: FinanceCategoryX.fromName(row.category),
      paidByUserId: row.paidByUserId,
      expenseDate: row.expenseDate,
      splitRule: SplitRule.fromJsonString(row.splitRuleJson),
      isRecurring: row.isRecurring,
      isRecurringTemplate: row.isRecurringTemplate,
      recurrenceRule:
          row.recurrenceRuleJson == null ? null : RecurrenceRule.fromJsonString(row.recurrenceRuleJson!),
      receiptReference: row.receiptReference,
      notes: row.notes,
      createdByUserId: row.createdBy,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isSettled: row.isSettled,
      sourceRecurringExpenseId: row.sourceRecurringExpenseId,
      nextDueAt: row.nextDueAt,
      lastGeneratedAt: row.lastGeneratedAt,
      paidByDisplayName: paidByDisplayName,
    );
  }

  SettlementEntity _mapSettlement(
    Settlement row,
    Map<String, String> participantMap,
  ) {
    return SettlementEntity(
      id: row.id,
      householdId: row.householdId,
      debtorUserId: row.debtorUserId,
      creditorUserId: row.creditorUserId,
      amountCents: row.amountCents,
      status: SettlementStatus.values.firstWhere(
        (SettlementStatus status) => status.name == row.status,
      ),
      initiatedByUserId: row.initiatedByUserId,
      confirmedByUserId: row.confirmedByUserId,
      createdAt: row.createdAt,
      completedAt: row.completedAt,
      cancelledAt: row.cancelledAt,
      sourceExpenseId: row.sourceExpenseId,
      debtorDisplayName: participantMap[row.debtorUserId] ?? 'Unknown',
      creditorDisplayName: participantMap[row.creditorUserId] ?? 'Unknown',
    );
  }
}
