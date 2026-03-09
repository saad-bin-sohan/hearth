import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
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
              children: const <Widget>[
                SummaryCard(
                  title: 'Finance Ledger',
                  metric: '0',
                  caption: 'Bills due this week',
                  accentColor: AppColors.primary,
                ),
                SizedBox(width: AppSpacing.md),
                SummaryCard(
                  title: 'Chore Manager',
                  metric: '0',
                  caption: 'Tasks overdue',
                  accentColor: AppColors.secondary,
                ),
                SizedBox(width: AppSpacing.md),
                SummaryCard(
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
            subtitle: 'Recent household events will land here as modules come online.',
          ),
          const SizedBox(height: AppSpacing.md),
          const HearthListItemEntry(
            child: SizedBox(
              height: 280,
              child: HearthEmptyState(
                icon: HugeIcons.strokeRoundedDashboardSquare02,
                title: 'The feed is ready for your household',
                body:
                    'Create your household, invite members, and future modules will start filling this space with activity.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
