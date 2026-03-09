import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/chores/presentation/chore_notifier.dart';
import 'package:hearth/features/chores/presentation/widgets/fairness_bar.dart';

class FairnessScoreScreen extends ConsumerWidget {
  const FairnessScoreScreen({super.key});

  static const String routePath = '/chores/fairness';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final entriesAsync = ref.watch(fairnessEntriesProvider);
    final snapshotAsync = ref.watch(fairnessScoreSnapshotProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Fairness Score',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimaryFor(brightness),
              ),
            ),
            Text(
              'Last 30 days',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: snapshotAsync.when(
          data: (FairnessScoreSnapshot? snapshot) {
            return entriesAsync.when(
              data: (List<FairnessScoreEntry> entries) {
                final scores = entries
                    .map((FairnessScoreEntry entry) => entry.score)
                    .toList();
                final allBalanced =
                    scores.isNotEmpty &&
                    scores.every((double score) => score >= 80);
                final hasImbalance = scores.any((double score) => score < 60);
                final headlineColor = allBalanced
                    ? AppColors.successFor(brightness)
                    : hasImbalance
                    ? AppColors.accentFor(brightness)
                    : AppColors.textPrimaryFor(brightness);
                final headlineText = allBalanced
                    ? 'Great balance! 🏠'
                    : hasImbalance
                    ? 'Imbalance detected'
                    : 'Balance is moving in the right direction';
                return ListView(
                  children: <Widget>[
                    HearthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Household Balance',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.textPrimaryFor(brightness),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            headlineText,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: headlineColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          HearthNumberTicker(
                            value: '${snapshot?.totalMinutes ?? 0}',
                            suffix: ' min',
                            style: AppTextStyles.numericLarge.copyWith(
                              color: AppColors.primaryFor(brightness),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...List<Widget>.generate(entries.length, (int index) {
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: HearthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  HearthAvatar(
                                    displayName: entry.displayName,
                                    size: 48,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          entry.displayName,
                                          style: AppTextStyles.titleLarge
                                              .copyWith(
                                                color: AppColors.textPrimaryFor(
                                                  brightness,
                                                ),
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '${entry.minutesCompleted} task-minutes this month',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color:
                                                    AppColors.textSecondaryFor(
                                                      brightness,
                                                    ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FairnessBar(
                                score: entry.score,
                                delay: Duration(milliseconds: index * 100),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    HearthCard(
                      child: Text(
                        'Score is based on completed task-minutes versus your fair share of household work over the last 30 days.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryFor(brightness),
                        ),
                      ),
                    ),
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
      ),
    );
  }
}
