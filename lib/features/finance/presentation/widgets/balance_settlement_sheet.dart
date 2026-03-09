import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/finance/presentation/finance_notifier.dart';

Future<void> showBalanceSettlementSheet(
  BuildContext context, {
  required BalanceEntity balance,
  String? sourceExpenseId,
}) {
  return showHearthBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return BalanceSettlementSheet(
        balance: balance,
        sourceExpenseId: sourceExpenseId,
      );
    },
  );
}

class BalanceSettlementSheet extends ConsumerWidget {
  const BalanceSettlementSheet({
    required this.balance,
    this.sourceExpenseId,
    super.key,
  });

  final BalanceEntity balance;
  final String? sourceExpenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(financePendingSettlementForBalanceProvider(balance));
    final financeContext = ref.watch(financeContextProvider);
    final financeState = ref.watch(financeNotifierProvider);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.lg,
      ),
      child: financeContext.when(
        data: (FinanceContext? contextValue) {
          if (contextValue == null) {
            return const SizedBox.shrink();
          }
          return pendingAsync.when(
            data: (SettlementEntity? pending) {
              final currentUserId = contextValue.currentUserId;
              final isAwaitingCounterparty = pending != null &&
                  pending.initiatedByUserId == currentUserId;
              final isCounterparty = pending != null &&
                  pending.initiatedByUserId != currentUserId;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Settle Balance',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${balance.debtorDisplayName} owes ${balance.creditorDisplayName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppFormatters.currencyFromCents(
                      amountCents: balance.amountCents,
                      currencyCode: contextValue.currencyCode,
                    ),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (pending == null)
                    Text(
                      'First confirmation creates a pending settlement request. The counterparty completes it on the same device for now.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else if (isAwaitingCounterparty)
                    Text(
                      'Waiting for ${currentUserId == pending.debtorUserId ? pending.creditorDisplayName : pending.debtorDisplayName} to confirm.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Text(
                      'Confirm this request to complete the settlement and recalculate balances.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  if (pending == null)
                    HearthButton(
                      label: 'Request Settlement',
                      isLoading: financeState.isLoading,
                      onPressed: contextValue.canEdit
                          ? () async {
                              await ref.read(financeNotifierProvider.notifier).requestSettlement(
                                    debtorUserId: balance.debtorUserId,
                                    creditorUserId: balance.creditorUserId,
                                    amountCents: balance.amountCents,
                                    sourceExpenseId: sourceExpenseId,
                                  );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                    )
                  else ...<Widget>[
                    HearthButton(
                      label: isCounterparty ? 'Confirm Settlement' : 'Pending Confirmation',
                      isLoading: financeState.isLoading,
                      onPressed: isCounterparty
                          ? () async {
                              await ref
                                  .read(financeNotifierProvider.notifier)
                                  .confirmSettlement(pending.id);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    HearthButton(
                      label: 'Cancel Request',
                      variant: HearthButtonVariant.ghost,
                      onPressed: () async {
                        await ref
                            .read(financeNotifierProvider.notifier)
                            .cancelSettlement(pending.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, _) => Text('$error'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Text('$error'),
      ),
    );
  }
}
