import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/finance/domain/split_engine.dart';
import 'package:hearth/features/finance/presentation/finance_notifier.dart';
import 'package:hearth/features/finance/presentation/widgets/add_expense_sheet.dart';
import 'package:hearth/features/finance/presentation/widgets/balance_settlement_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({
    required this.expenseId,
    super.key,
  });

  final String expenseId;

  static const String routePath = '/finance/expense';

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
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
    final expenseAsync = ref.watch(financeExpenseProvider(widget.expenseId));
    final financeContext = ref.watch(financeContextProvider);
    final balancesAsync = ref.watch(financeBalancesProvider);
    final currentUserId = ref.watch(financeCurrentUserIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Detail'),
        actions: <Widget>[
          expenseAsync.when(
            data: (expense) {
              if (expense == null || expense.createdByUserId != currentUserId) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: () => showAddExpenseSheet(
                  context,
                  initialExpense: expense,
                ),
                icon: const Icon(HugeIcons.strokeRoundedEdit02),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          expenseAsync.when(
            data: (expense) {
              if (expense == null || expense.createdByUserId != currentUserId) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete expense?'),
                        content: const Text('This recalculates balances immediately.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirmed != true) {
                    return;
                  }
                  await ref.read(financeNotifierProvider.notifier).deleteExpense(expense.id);
                  if (context.mounted) {
                    context.pop();
                  }
                },
                icon: const Icon(HugeIcons.strokeRoundedDelete02),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: financeContext.when(
        data: (FinanceContext? value) {
          if (value == null) {
            return const Center(child: Text('No finance context found.'));
          }
          return expenseAsync.when(
            data: (expense) {
              if (expense == null) {
                return const Center(child: Text('Expense not found.'));
              }
              return balancesAsync.when(
                data: (balances) {
                  final allocations = const SplitEngine().allocate(
                    totalCents: expense.amountCents,
                    rule: expense.splitRule,
                  );
                  final participants = <String, FinanceParticipant>{
                    for (final participant in value.participants) participant.userId: participant,
                  };
                  final relatedBalances = balances.where((balance) {
                    return expense.splitRule.participantUserIds.contains(balance.debtorUserId) &&
                        expense.splitRule.participantUserIds.contains(balance.creditorUserId);
                  }).toList();
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: <Widget>[
                      HearthCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              expense.title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              AppFormatters.currencyFromCents(
                                amountCents: expense.amountCents,
                                currencyCode: value.currencyCode,
                              ),
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: AppColors.primaryFor(Theme.of(context).brightness),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${expense.category.label} • ${AppFormatters.shortDate(expense.expenseDate)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Paid by ${expense.paidByDisplayName ?? participants[expense.paidByUserId]?.displayName ?? 'Unknown'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      HearthCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Split breakdown', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.md),
                            for (final allocation in allocations) ...<Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      participants[allocation.userId]?.displayName ?? 'Unknown',
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.currencyFromCents(
                                      amountCents: allocation.amountCents,
                                      currencyCode: value.currencyCode,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      HearthCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Receipt', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              expense.receiptReference == null
                                  ? 'Receipt capture arrives in a later phase. This expense is schema-ready for it.'
                                  : expense.receiptReference!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (expense.notes != null && expense.notes!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        HearthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Notes', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: AppSpacing.sm),
                              Text(expense.notes!, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      HearthCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Settlement', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.sm),
                            if (relatedBalances.isEmpty)
                              Text(
                                expense.isSettled
                                    ? 'This expense is currently settled.'
                                    : 'No outstanding net balance remains for this expense pair.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            else
                              Column(
                                children: relatedBalances.map((balance) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            '${balance.debtorDisplayName} owes ${balance.creditorDisplayName}',
                                          ),
                                        ),
                                        HearthButton(
                                          label: 'Settle',
                                          expanded: false,
                                          onPressed: () => showBalanceSettlementSheet(
                                            context,
                                            balance: balance,
                                            sourceExpenseId: expense.id,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, _) => Center(child: Text('$error')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, _) => Center(child: Text('$error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
