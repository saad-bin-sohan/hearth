import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/chores/presentation/widgets/chores_summary_card.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/finance/presentation/expense_detail_screen.dart';
import 'package:hearth/features/finance/presentation/finance_notifier.dart';
import 'package:hearth/features/home/presentation/widgets/summary_card.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final householdAsync = ref.watch(currentHouseholdProvider);
    final financeSummaryAsync = ref.watch(financeHomeSummaryProvider);
    final financeActivityAsync = ref.watch(financeActivityProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          userAsync.when(
            data: (user) => householdAsync.when(
              data: (household) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Good morning, ${user?.displayName ?? 'there'}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    household?.name ?? 'Set up your household',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Text('$error'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => Text('$error'),
          ),
          const SizedBox(height: AppSpacing.xl),
          const HearthSectionHeader(
            title: 'Quick Summary',
            subtitle: 'A warm snapshot of what is active in your home.',
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 128,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                financeSummaryAsync.when(
                  data: (FinanceHomeSummary? summary) => SummaryCard(
                    title: 'Finance Ledger',
                    metric: '${summary?.dueBillsThisWeek ?? 0}',
                    caption: 'Bills due this week',
                    accentColor: AppColors.primary,
                  ),
                  loading: () => const SummaryCard(
                    title: 'Finance Ledger',
                    metric: '...',
                    caption: 'Bills due this week',
                    accentColor: AppColors.primary,
                  ),
                  error: (_, __) => const SummaryCard(
                    title: 'Finance Ledger',
                    metric: '0',
                    caption: 'Bills due this week',
                    accentColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                financeSummaryAsync.when(
                  data: (FinanceHomeSummary? summary) => SummaryCard(
                    title: 'Open Balances',
                    metric: '${summary?.openBalanceCount ?? 0}',
                    caption: 'Pairs still to settle',
                    accentColor: AppColors.secondary,
                  ),
                  loading: () => const SummaryCard(
                    title: 'Open Balances',
                    metric: '...',
                    caption: 'Pairs still to settle',
                    accentColor: AppColors.secondary,
                  ),
                  error: (_, __) => const SummaryCard(
                    title: 'Open Balances',
                    metric: '0',
                    caption: 'Pairs still to settle',
                    accentColor: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const ChoresSummaryCard(),
                const SizedBox(width: AppSpacing.md),
                const SummaryCard(
                  title: 'Document Vault',
                  metric: '0',
                  caption: 'Files uploaded',
                  accentColor: AppColors.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const HearthSectionHeader(
            title: 'Activity Feed',
            subtitle: 'Recent household finance activity lands here first.',
          ),
          const SizedBox(height: AppSpacing.md),
          financeActivityAsync.when(
            data: (List<FinanceActivityItem> activity) {
              if (activity.isEmpty) {
                return const HearthListItemEntry(
                  child: SizedBox(
                    height: 280,
                    child: HearthEmptyState(
                      icon: HugeIcons.strokeRoundedDashboardSquare02,
                      title: 'The feed is ready for your household',
                      body:
                          'Create expenses or settle balances to start building the activity timeline.',
                    ),
                  ),
                );
              }
              return Column(
                children: List<Widget>.generate(activity.length, (int index) {
                  final item = activity[index];
                  return HearthListItemEntry(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: HearthCard(
                        onTap: item.expenseId == null
                            ? null
                            : () => context.push(
                                '${ExpenseDetailScreen.routePath}/${item.expenseId}',
                              ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              item.type == FinanceActivityType.expense
                                  ? HugeIcons.strokeRoundedWallet03
                                  : HugeIcons.strokeRoundedTick02,
                              color: item.type == FinanceActivityType.expense
                                  ? AppColors.primaryFor(brightness)
                                  : AppColors.secondaryFor(brightness),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    item.subtitle,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondaryFor(
                                            brightness,
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    AppFormatters.shortDate(item.occurredAt),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textTertiaryFor(
                                            brightness,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              AppFormatters.currencyFromCents(
                                amountCents: item.amountCents,
                                currencyCode:
                                    householdAsync.valueOrNull?.currencyCode ??
                                    'USD',
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('$error'),
          ),
        ],
      ),
    );
  }
}
