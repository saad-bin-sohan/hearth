import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/auth/data/local_auth_repository.dart';
import 'package:hearth/features/auth/data/password_hasher.dart';
import 'package:hearth/features/auth/domain/app_user.dart';
import 'package:hearth/features/finance/data/local_finance_repository.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/household/data/local_household_repository.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:uuid/uuid.dart';

import '../../test_helpers.dart';

void main() {
  late AppDatabase database;
  late LocalAuthRepository authRepository;
  late LocalHouseholdRepository householdRepository;
  late LocalFinanceRepository financeRepository;

  setUp(() {
    database = createTestDatabase();
    authRepository = LocalAuthRepository(
      database: database,
      passwordHasher: const PasswordHasher(),
      uuid: const Uuid(),
    );
    householdRepository = LocalHouseholdRepository(
      database: database,
      uuid: const Uuid(),
    );
    financeRepository = LocalFinanceRepository(
      database: database,
      uuid: const Uuid(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('add expense persists and recomputes household balances', () async {
    final setup = await _seedHousehold(
      authRepository: authRepository,
      householdRepository: householdRepository,
    );

    await financeRepository.addExpense(
      actorUserId: setup.alice.id,
      draft: ExpenseDraft(
        householdId: setup.household.id,
        title: 'Groceries',
        amountCents: 1200,
        category: FinanceCategory.groceries,
        paidByUserId: setup.alice.id,
        expenseDate: DateTime(2026, 3, 9),
        splitRule: EqualSplitRule(
          participantUserIds: <String>[setup.alice.id, setup.bob.id],
        ),
      ),
    );

    final expenses = await financeRepository.getRecentExpenses(
      householdId: setup.household.id,
    );
    final balances = await financeRepository.getBalances(
      householdId: setup.household.id,
    );

    expect(expenses, hasLength(1));
    expect(expenses.single.title, 'Groceries');
    expect(balances, hasLength(1));
    expect(balances.single.debtorUserId, setup.bob.id);
    expect(balances.single.creditorUserId, setup.alice.id);
    expect(balances.single.amountCents, 600);
  });

  test('observer cannot add expenses', () async {
    final setup = await _seedHousehold(
      authRepository: authRepository,
      householdRepository: householdRepository,
    );

    await householdRepository.updateRole(
      actingUserId: setup.alice.id,
      householdId: setup.household.id,
      memberUserId: setup.bob.id,
      role: HouseholdRole.observer,
    );

    expect(
      financeRepository.addExpense(
        actorUserId: setup.bob.id,
        draft: ExpenseDraft(
          householdId: setup.household.id,
          title: 'Utilities',
          amountCents: 5000,
          category: FinanceCategory.utilities,
          paidByUserId: setup.bob.id,
          expenseDate: DateTime(2026, 3, 9),
          splitRule: EqualSplitRule(
            participantUserIds: <String>[setup.alice.id, setup.bob.id],
          ),
        ),
      ),
      throwsStateError,
    );
  });

  test('expense owner rules are enforced for update and delete', () async {
    final setup = await _seedHousehold(
      authRepository: authRepository,
      householdRepository: householdRepository,
    );

    final created = await financeRepository.addExpense(
      actorUserId: setup.alice.id,
      draft: ExpenseDraft(
        householdId: setup.household.id,
        title: 'Dinner',
        amountCents: 4000,
        category: FinanceCategory.dining,
        paidByUserId: setup.alice.id,
        expenseDate: DateTime(2026, 3, 9),
        splitRule: EqualSplitRule(
          participantUserIds: <String>[setup.alice.id, setup.bob.id],
        ),
      ),
    );

    expect(
      financeRepository.updateExpense(
        actorUserId: setup.bob.id,
        draft: ExpenseDraft(
          id: created.id,
          householdId: setup.household.id,
          title: 'Edited dinner',
          amountCents: 4200,
          category: FinanceCategory.dining,
          paidByUserId: setup.alice.id,
          expenseDate: created.expenseDate,
          splitRule: created.splitRule,
        ),
      ),
      throwsStateError,
    );
    expect(
      financeRepository.deleteExpense(
        actorUserId: setup.bob.id,
        expenseId: created.id,
      ),
      throwsStateError,
    );

    await financeRepository.deleteExpense(
      actorUserId: setup.alice.id,
      expenseId: created.id,
    );

    final expenses = await financeRepository.getRecentExpenses(
      householdId: setup.household.id,
    );
    expect(expenses, isEmpty);
  });

  test('only admins can manage category budgets', () async {
    final setup = await _seedHousehold(
      authRepository: authRepository,
      householdRepository: householdRepository,
    );

    await financeRepository.setBudget(
      actorUserId: setup.alice.id,
      householdId: setup.household.id,
      category: FinanceCategory.groceries,
      limitCents: 25000,
    );

    expect(
      financeRepository.setBudget(
        actorUserId: setup.bob.id,
        householdId: setup.household.id,
        category: FinanceCategory.groceries,
        limitCents: 10000,
      ),
      throwsStateError,
    );

    final progress = await financeRepository.getBudgetProgress(
      householdId: setup.household.id,
    );
    final groceries = progress.firstWhere(
      (BudgetProgress entry) => entry.category == FinanceCategory.groceries,
    );

    expect(groceries.limitCents, 25000);
  });

  test('settlement confirmation clears balances after both parties confirm', () async {
    final setup = await _seedHousehold(
      authRepository: authRepository,
      householdRepository: householdRepository,
    );

    await financeRepository.addExpense(
      actorUserId: setup.alice.id,
      draft: ExpenseDraft(
        householdId: setup.household.id,
        title: 'Rent split',
        amountCents: 1200,
        category: FinanceCategory.housing,
        paidByUserId: setup.alice.id,
        expenseDate: DateTime(2026, 3, 9),
        splitRule: EqualSplitRule(
          participantUserIds: <String>[setup.alice.id, setup.bob.id],
        ),
      ),
    );

    final requested = await financeRepository.requestSettlement(
      actorUserId: setup.bob.id,
      householdId: setup.household.id,
      debtorUserId: setup.bob.id,
      creditorUserId: setup.alice.id,
      amountCents: 600,
    );

    expect(requested.isPending, isTrue);

    final confirmed = await financeRepository.confirmSettlement(
      actorUserId: setup.alice.id,
      settlementId: requested.id,
    );

    expect(confirmed.isCompleted, isTrue);
    expect(
      await financeRepository.getBalances(householdId: setup.household.id),
      isEmpty,
    );
  });

  test('recurring reconciliation generates due instances once', () async {
    final setup = await _seedHousehold(
      authRepository: authRepository,
      householdRepository: householdRepository,
    );
    final anchor = DateTime.now().subtract(const Duration(days: 15));

    await financeRepository.addExpense(
      actorUserId: setup.alice.id,
      draft: ExpenseDraft(
        householdId: setup.household.id,
        title: 'Streaming',
        amountCents: 1599,
        category: FinanceCategory.subscriptions,
        paidByUserId: setup.alice.id,
        expenseDate: anchor,
        splitRule: EqualSplitRule(
          participantUserIds: <String>[setup.alice.id, setup.bob.id],
        ),
        isRecurring: true,
        isRecurringTemplate: true,
        recurrenceRule: RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          anchorDate: anchor,
        ),
        nextDueAt: anchor,
      ),
    );

    final firstExpenseCount = (await financeRepository.getRecentExpenses(
      householdId: setup.household.id,
    )).length;

    await financeRepository.reconcileRecurringBillsOnLaunch(setup.household.id);

    final secondExpenseCount = (await financeRepository.getRecentExpenses(
      householdId: setup.household.id,
    )).length;
    final templates = await financeRepository.getRecurringTemplates(
      householdId: setup.household.id,
    );

    expect(firstExpenseCount, greaterThan(0));
    expect(secondExpenseCount, firstExpenseCount);
    expect(templates, hasLength(1));
  });
}

Future<({AppUser alice, AppUser bob, HouseholdEntity household})> _seedHousehold({
  required LocalAuthRepository authRepository,
  required LocalHouseholdRepository householdRepository,
}) async {
  final alice = await authRepository.signUp(
    email: 'alice@example.com',
    password: 'SecurePass1',
  );
  final bob = await authRepository.signUp(
    email: 'bob@example.com',
    password: 'SecurePass1',
  );
  final household = await householdRepository.createHousehold(
    userId: alice.id,
    name: 'Hearth House',
    emoji: '🏡',
    avatarColorKey: 'terracotta',
    currencyCode: 'USD',
  );
  await householdRepository.joinHousehold(
    userId: bob.id,
    inviteCode: household.inviteCode,
  );
  return (
    alice: alice,
    bob: bob,
    household: household,
  );
}
