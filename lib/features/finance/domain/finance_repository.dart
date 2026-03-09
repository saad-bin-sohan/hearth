import 'package:hearth/features/finance/domain/finance_models.dart';

abstract class FinanceRepository {
  Future<FinanceContext?> getContext({
    required String householdId,
    required String userId,
  });

  Future<FinanceDashboardData> getDashboard({
    required String householdId,
    required String userId,
  });

  Future<FinanceHomeSummary> getHomeSummary({
    required String householdId,
    required String userId,
  });

  Future<List<FinanceActivityItem>> getRecentActivity({
    required String householdId,
    int limit = 10,
  });

  Future<List<ExpenseEntity>> getRecentExpenses({
    required String householdId,
    int limit = 20,
  });

  Future<List<ExpenseEntity>> getRecurringTemplates({
    required String householdId,
  });

  Future<ExpenseEntity?> getExpenseById(String expenseId);

  Future<List<BalanceEntity>> getBalances({
    required String householdId,
  });

  Future<BalanceSummary> getBalanceSummary({
    required String householdId,
    required String userId,
  });

  Future<List<BudgetProgress>> getBudgetProgress({
    required String householdId,
  });

  Future<List<SettlementEntity>> getSettlementsForPair({
    required String householdId,
    required String debtorUserId,
    required String creditorUserId,
  });

  Future<SettlementEntity?> getPendingSettlementForPair({
    required String householdId,
    required String debtorUserId,
    required String creditorUserId,
  });

  Future<ExpenseEntity> addExpense({
    required String actorUserId,
    required ExpenseDraft draft,
  });

  Future<ExpenseEntity> updateExpense({
    required String actorUserId,
    required ExpenseDraft draft,
  });

  Future<void> deleteExpense({
    required String actorUserId,
    required String expenseId,
  });

  Future<void> setBudget({
    required String actorUserId,
    required String householdId,
    required FinanceCategory category,
    required int? limitCents,
  });

  Future<SettlementEntity> requestSettlement({
    required String actorUserId,
    required String householdId,
    required String debtorUserId,
    required String creditorUserId,
    required int amountCents,
    String? sourceExpenseId,
  });

  Future<SettlementEntity> confirmSettlement({
    required String actorUserId,
    required String settlementId,
  });

  Future<void> cancelSettlement({
    required String actorUserId,
    required String settlementId,
  });

  Future<void> reconcileRecurringBillsOnLaunch(String householdId);
}
