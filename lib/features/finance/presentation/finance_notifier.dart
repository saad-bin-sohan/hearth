import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/features/finance/data/local_finance_repository.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';

class FinanceActionState {
  const FinanceActionState({this.isLoading = false, this.message});

  final bool isLoading;
  final String? message;

  FinanceActionState copyWith({
    bool? isLoading,
    String? message,
    bool clearMessage = false,
  }) {
    return FinanceActionState(
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceActionState> {
  FinanceNotifier(this.ref) : super(const FinanceActionState());

  final Ref ref;

  Future<ExpenseEntity> addExpense(ExpenseDraft draft) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to add an expense.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final expense = await ref
          .read(financeRepositoryProvider)
          .addExpense(actorUserId: actorUserId, draft: draft);
      _invalidateFinanceData();
      state = state.copyWith(isLoading: false, clearMessage: true);
      return expense;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<ExpenseEntity> updateExpense(ExpenseDraft draft) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to edit an expense.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final expense = await ref
          .read(financeRepositoryProvider)
          .updateExpense(actorUserId: actorUserId, draft: draft);
      _invalidateFinanceData();
      ref.invalidate(financeExpenseProvider(expense.id));
      state = state.copyWith(isLoading: false, clearMessage: true);
      return expense;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to delete an expense.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref
          .read(financeRepositoryProvider)
          .deleteExpense(actorUserId: actorUserId, expenseId: expenseId);
      _invalidateFinanceData();
      ref.invalidate(financeExpenseProvider(expenseId));
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> setBudget({
    required FinanceCategory category,
    required int? limitCents,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final householdId = session.activeHouseholdId;
    final actorUserId = session.userId;
    if (householdId == null || actorUserId == null) {
      throw StateError('Household context is missing.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref
          .read(financeRepositoryProvider)
          .setBudget(
            actorUserId: actorUserId,
            householdId: householdId,
            category: category,
            limitCents: limitCents,
          );
      _invalidateFinanceData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<SettlementEntity> requestSettlement({
    required String debtorUserId,
    required String creditorUserId,
    required int amountCents,
    String? sourceExpenseId,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final householdId = session.activeHouseholdId;
    final actorUserId = session.userId;
    if (householdId == null || actorUserId == null) {
      throw StateError('Household context is missing.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final settlement = await ref
          .read(financeRepositoryProvider)
          .requestSettlement(
            actorUserId: actorUserId,
            householdId: householdId,
            debtorUserId: debtorUserId,
            creditorUserId: creditorUserId,
            amountCents: amountCents,
            sourceExpenseId: sourceExpenseId,
          );
      _invalidateFinanceData();
      state = state.copyWith(isLoading: false, clearMessage: true);
      return settlement;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<SettlementEntity> confirmSettlement(String settlementId) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to confirm settlement.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final settlement = await ref
          .read(financeRepositoryProvider)
          .confirmSettlement(
            actorUserId: actorUserId,
            settlementId: settlementId,
          );
      _invalidateFinanceData();
      state = state.copyWith(isLoading: false, clearMessage: true);
      return settlement;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> cancelSettlement(String settlementId) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to cancel settlement.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref
          .read(financeRepositoryProvider)
          .cancelSettlement(
            actorUserId: actorUserId,
            settlementId: settlementId,
          );
      _invalidateFinanceData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  void _invalidateFinanceData() {
    ref.invalidate(financeContextProvider);
    ref.invalidate(financeDashboardProvider);
    ref.invalidate(financeHomeSummaryProvider);
    ref.invalidate(financeActivityProvider);
    ref.invalidate(financeRecentExpensesProvider);
    ref.invalidate(financeRecurringTemplatesProvider);
    ref.invalidate(financeBudgetProgressProvider);
    ref.invalidate(financeBalancesProvider);
    ref.invalidate(financePendingSettlementsProvider);
  }
}

final financeNotifierProvider =
    StateNotifierProvider<FinanceNotifier, FinanceActionState>((Ref ref) {
      return FinanceNotifier(ref);
    });

final financeHouseholdIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).activeHouseholdId;
});

final financeCurrentUserIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).userId;
});

final financeContextProvider = FutureProvider<FinanceContext?>((Ref ref) async {
  final householdId = ref.watch(financeHouseholdIdProvider);
  final userId = ref.watch(financeCurrentUserIdProvider);
  if (householdId == null || userId == null) {
    return null;
  }
  return ref
      .watch(financeRepositoryProvider)
      .getContext(householdId: householdId, userId: userId);
});

final financeBootstrapProvider = FutureProvider<void>((Ref ref) async {
  final householdId = ref.watch(financeHouseholdIdProvider);
  if (householdId == null) {
    return;
  }
  await ref
      .watch(financeRepositoryProvider)
      .reconcileRecurringBillsOnLaunch(householdId);
  ref.invalidate(financeDashboardProvider);
  ref.invalidate(financeRecentExpensesProvider);
  ref.invalidate(financeRecurringTemplatesProvider);
  ref.invalidate(financeBalancesProvider);
  ref.invalidate(financeBudgetProgressProvider);
  ref.invalidate(financeHomeSummaryProvider);
  ref.invalidate(financeActivityProvider);
});

final financeDashboardProvider = FutureProvider<FinanceDashboardData?>((
  Ref ref,
) async {
  final householdId = ref.watch(financeHouseholdIdProvider);
  final userId = ref.watch(financeCurrentUserIdProvider);
  if (householdId == null || userId == null) {
    return null;
  }
  return ref
      .watch(financeRepositoryProvider)
      .getDashboard(householdId: householdId, userId: userId);
});

final financeHomeSummaryProvider = FutureProvider<FinanceHomeSummary?>((
  Ref ref,
) async {
  final householdId = ref.watch(financeHouseholdIdProvider);
  final userId = ref.watch(financeCurrentUserIdProvider);
  if (householdId == null || userId == null) {
    return null;
  }
  return ref
      .watch(financeRepositoryProvider)
      .getHomeSummary(householdId: householdId, userId: userId);
});

final financeActivityProvider = FutureProvider<List<FinanceActivityItem>>((
  Ref ref,
) async {
  final householdId = ref.watch(financeHouseholdIdProvider);
  if (householdId == null) {
    return const <FinanceActivityItem>[];
  }
  return ref
      .watch(financeRepositoryProvider)
      .getRecentActivity(householdId: householdId);
});

final financeRecentExpensesProvider = FutureProvider<List<ExpenseEntity>>((
  Ref ref,
) async {
  final householdId = ref.watch(financeHouseholdIdProvider);
  if (householdId == null) {
    return const <ExpenseEntity>[];
  }
  return ref
      .watch(financeRepositoryProvider)
      .getRecentExpenses(householdId: householdId);
});

final financeRecurringTemplatesProvider = FutureProvider<List<ExpenseEntity>>((
  Ref ref,
) async {
  final householdId = ref.watch(financeHouseholdIdProvider);
  if (householdId == null) {
    return const <ExpenseEntity>[];
  }
  return ref
      .watch(financeRepositoryProvider)
      .getRecurringTemplates(householdId: householdId);
});

final financeExpenseProvider = FutureProvider.family<ExpenseEntity?, String>((
  Ref ref,
  String expenseId,
) {
  return ref.watch(financeRepositoryProvider).getExpenseById(expenseId);
});

final financeBalancesProvider = FutureProvider<List<BalanceEntity>>((
  Ref ref,
) async {
  final householdId = ref.watch(financeHouseholdIdProvider);
  if (householdId == null) {
    return const <BalanceEntity>[];
  }
  return ref
      .watch(financeRepositoryProvider)
      .getBalances(householdId: householdId);
});

final financeBudgetProgressProvider = FutureProvider<List<BudgetProgress>>((
  Ref ref,
) async {
  final householdId = ref.watch(financeHouseholdIdProvider);
  if (householdId == null) {
    return const <BudgetProgress>[];
  }
  return ref
      .watch(financeRepositoryProvider)
      .getBudgetProgress(householdId: householdId);
});

final financePendingSettlementsProvider =
    FutureProvider<List<SettlementEntity>>((Ref ref) async {
      final dashboard = await ref.watch(financeDashboardProvider.future);
      return dashboard?.pendingSettlements ?? const <SettlementEntity>[];
    });

final financePendingSettlementForBalanceProvider =
    FutureProvider.family<SettlementEntity?, BalanceEntity>((
      Ref ref,
      BalanceEntity balance,
    ) async {
      final householdId = ref.watch(financeHouseholdIdProvider);
      if (householdId == null) {
        return null;
      }
      return ref
          .watch(financeRepositoryProvider)
          .getPendingSettlementForPair(
            householdId: householdId,
            debtorUserId: balance.debtorUserId,
            creditorUserId: balance.creditorUserId,
          );
    });
