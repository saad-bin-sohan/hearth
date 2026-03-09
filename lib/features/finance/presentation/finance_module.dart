import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_badge.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_progress_bar.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/finance/presentation/finance_notifier.dart';
import 'package:hearth/features/finance/presentation/widgets/add_expense_sheet.dart';
import 'package:hearth/features/finance/presentation/widgets/balance_settlement_sheet.dart';
import 'package:hearth/features/finance/presentation/widgets/budget_editor_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

class FinanceModule extends ConsumerStatefulWidget {
  const FinanceModule({super.key});

  static const String routePath = '/finance';

  @override
  ConsumerState<FinanceModule> createState() => _FinanceModuleState();
}

class _FinanceModuleState extends ConsumerState<FinanceModule> {
  ProviderSubscription<FinanceActionState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<FinanceActionState>(
      financeNotifierProvider,
      (FinanceActionState? previous, FinanceActionState next) {
        if (!mounted || next.message == null) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message!)),
        );
        ref.read(financeNotifierProvider.notifier).clearMessage();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(financeBootstrapProvider);
    final financeContext = ref.watch(financeContextProvider);
    final dashboardAsync = ref.watch(financeDashboardProvider);
    return financeContext.when(
      data: (FinanceContext? value) {
        if (value == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Finance Ledger'),
              automaticallyImplyLeading: false,
            ),
            body: const Center(
              child: Text('Create or join a household to use finance tools.'),
            ),
          );
        }
        return dashboardAsync.when(
          data: (FinanceDashboardData? data) {
            if (data == null) {
              return const SizedBox.shrink();
            }
            return DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Finance Ledger'),
                  automaticallyImplyLeading: false,
                ),
                body: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _FinanceSummaryCard(
                        dashboard: data,
                        currencyCode: value.currencyCode,
                      ),
                    ),
                    const TabBar(
                      tabs: <Widget>[
                        Tab(text: 'Expenses'),
                        Tab(text: 'Bills'),
                        Tab(text: 'Budget'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: <Widget>[
                          _ExpensesTab(
                            contextValue: value,
                            dashboard: data,
                          ),
                          _BillsTab(contextValue: value),
                          _BudgetTab(contextValue: value),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => Scaffold(
            appBar: AppBar(
              title: const Text('Finance Ledger'),
              automaticallyImplyLeading: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (Object error, _) => Scaffold(
            appBar: AppBar(
              title: const Text('Finance Ledger'),
              automaticallyImplyLeading: false,
            ),
            body: Center(child: Text('$error')),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Finance Ledger'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Finance Ledger'),
          automaticallyImplyLeading: false,
        ),
        body: Center(child: Text('$error')),
      ),
    );
  }
}

class _FinanceSummaryCard extends StatelessWidget {
  const _FinanceSummaryCard({
    required this.dashboard,
    required this.currencyCode,
  });

  final FinanceDashboardData dashboard;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final netLabel = switch (dashboard.summary.netCents.sign) {
      -1 => 'You owe',
      0 => 'All square',
      _ => 'You are owed',
    };
    final netValue = AppFormatters.currencyFromCents(
      amountCents: dashboard.summary.netCents.abs(),
      currencyCode: currencyCode,
    );
    return HearthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Active balance summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (dashboard.pendingSettlements.isNotEmpty)
                HearthBadge(count: dashboard.pendingSettlements.length),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            netLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryFor(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          HearthNumberTicker(
            value: netValue,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.primaryFor(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniStat(
                  label: 'Incoming',
                  value: AppFormatters.currencyFromCents(
                    amountCents: dashboard.summary.incomingCents,
                    currencyCode: currencyCode,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MiniStat(
                  label: 'Outgoing',
                  value: AppFormatters.currencyFromCents(
                    amountCents: dashboard.summary.outgoingCents,
                    currencyCode: currencyCode,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({
    required this.contextValue,
    required this.dashboard,
  });

  final FinanceContext contextValue;
  final FinanceDashboardData dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        const HearthSectionHeader(
          title: 'Outstanding balances',
          subtitle: 'Net pair balances stay simplified after every expense and settlement.',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (dashboard.balances.isEmpty)
          const HearthEmptyState(
            icon: HugeIcons.strokeRoundedComputerDollar,
            title: 'No balances are outstanding',
            body: 'Add the first shared expense to start tracking who owes whom.',
          )
        else
          Column(
            children: dashboard.balances.map((BalanceEntity balance) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: HearthCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${balance.debtorDisplayName} owes ${balance.creditorDisplayName}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              AppFormatters.currencyFromCents(
                                amountCents: balance.amountCents,
                                currencyCode: contextValue.currencyCode,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondaryFor(brightness),
                              ),
                            ),
                          ],
                        ),
                      ),
                      HearthButton(
                        label: 'Settle',
                        expanded: false,
                        onPressed: contextValue.canEdit
                            ? () => showBalanceSettlementSheet(
                                  context,
                                  balance: balance,
                                )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: AppSpacing.lg),
        HearthSectionHeader(
          title: 'Recent expenses',
          subtitle: 'Tap any item for the full split breakdown.',
          actionLabel: contextValue.canEdit ? 'Add expense' : null,
          onActionPressed: contextValue.canEdit
              ? () => showAddExpenseSheet(context)
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (dashboard.recentExpenses.isEmpty)
          HearthEmptyState(
            icon: HugeIcons.strokeRoundedInvoice03,
            title: 'No expenses yet',
            body: 'Shared purchases and reimbursements will appear here.',
            ctaLabel: contextValue.canEdit ? 'Add Expense' : null,
            onCtaPressed: contextValue.canEdit ? () => showAddExpenseSheet(context) : null,
          )
        else
          Column(
            children: List<Widget>.generate(
              dashboard.recentExpenses.length,
              (int index) {
                final expense = dashboard.recentExpenses[index];
                final canDelete = expense.createdByUserId == contextValue.currentUserId;
                return HearthListItemEntry(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: HearthSwipeToAction(
                      trailingAction: canDelete
                          ? HearthSwipeAction(
                              icon: HugeIcons.strokeRoundedDelete02,
                              label: 'Delete',
                              color: AppColors.errorFor(brightness),
                              onTriggered: () {
                                ref
                                    .read(financeNotifierProvider.notifier)
                                    .deleteExpense(expense.id);
                              },
                            )
                          : null,
                      child: HearthCard(
                        onTap: () => context.push('${FinanceModule.routePath}/expense/${expense.id}'),
                        child: Row(
                          children: <Widget>[
                            const Icon(HugeIcons.strokeRoundedWallet03),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    expense.title,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${expense.category.label} • ${AppFormatters.shortDate(expense.expenseDate)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              AppFormatters.currencyFromCents(
                                amountCents: expense.amountCents,
                                currencyCode: contextValue.currencyCode,
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BillsTab extends ConsumerWidget {
  const _BillsTab({
    required this.contextValue,
  });

  final FinanceContext contextValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(financeRecurringTemplatesProvider);
    final brightness = Theme.of(context).brightness;
    return billsAsync.when(
      data: (List<ExpenseEntity> bills) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            HearthSectionHeader(
              title: 'Recurring bills',
              subtitle: 'Templates generate due instances whenever the app boots.',
              actionLabel: contextValue.canEdit ? 'Add bill' : null,
              onActionPressed: contextValue.canEdit
                  ? () => showAddExpenseSheet(
                        context,
                        startAsRecurring: true,
                      )
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (bills.isEmpty)
              HearthEmptyState(
                icon: HugeIcons.strokeRoundedCalendarSetting01,
                title: 'No recurring bills yet',
                body: 'Create rent, utilities, or subscription templates here.',
                ctaLabel: contextValue.canEdit ? 'Add Bill' : null,
                onCtaPressed: contextValue.canEdit
                    ? () => showAddExpenseSheet(
                          context,
                          startAsRecurring: true,
                        )
                    : null,
              )
            else
              Column(
                children: bills.map((ExpenseEntity bill) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: HearthSwipeToAction(
                      trailingAction: bill.createdByUserId == contextValue.currentUserId
                          ? HearthSwipeAction(
                              icon: HugeIcons.strokeRoundedDelete02,
                              label: 'Delete',
                              color: AppColors.errorFor(brightness),
                              onTriggered: () {
                                ref.read(financeNotifierProvider.notifier).deleteExpense(bill.id);
                              },
                            )
                          : null,
                      child: HearthCard(
                        onTap: contextValue.canEdit
                            ? () => showAddExpenseSheet(
                                  context,
                                  initialExpense: bill,
                                )
                            : null,
                        child: Row(
                          children: <Widget>[
                            const Icon(HugeIcons.strokeRoundedRepeat),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    bill.title,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    bill.nextDueAt == null
                                        ? 'No next due date'
                                        : 'Next due ${AppFormatters.shortDate(bill.nextDueAt!)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              AppFormatters.currencyFromCents(
                                amountCents: bill.amountCents,
                                currencyCode: contextValue.currencyCode,
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, _) => Center(child: Text('$error')),
    );
  }
}

class _BudgetTab extends ConsumerWidget {
  const _BudgetTab({
    required this.contextValue,
  });

  final FinanceContext contextValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(financeBudgetProgressProvider);
    return budgetsAsync.when(
      data: (List<BudgetProgress> progressItems) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            HearthSectionHeader(
              title: 'Category budgets',
              subtitle: contextValue.canManageBudgets
                  ? 'Admin-only monthly limits live here.'
                  : 'Only admins can edit the monthly limits.',
            ),
            const SizedBox(height: AppSpacing.sm),
            ...progressItems.map((BudgetProgress progress) {
              final limitLabel = progress.limitCents == null
                  ? 'No budget set'
                  : AppFormatters.currencyFromCents(
                      amountCents: progress.limitCents!,
                      currencyCode: contextValue.currencyCode,
                    );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: HearthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              progress.category.label,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (contextValue.canManageBudgets)
                            HearthButton(
                              label: progress.limitCents == null ? 'Set' : 'Edit',
                              expanded: false,
                              variant: HearthButtonVariant.ghost,
                              onPressed: () {
                                showHearthBottomSheet<void>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BudgetEditorSheet(progress: progress);
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Spent ${AppFormatters.currencyFromCents(amountCents: progress.spentCents, currencyCode: contextValue.currencyCode)} of $limitLabel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      HearthProgressBar(progress: progress.progress),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, _) => Center(child: Text('$error')),
    );
  }
}
