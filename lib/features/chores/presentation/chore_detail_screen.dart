import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_celebration.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/chores/presentation/chore_notifier.dart';
import 'package:hearth/features/chores/presentation/widgets/chore_streak_badge.dart';
import 'package:hearth/features/chores/presentation/widgets/complete_chore_sheet.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hugeicons/hugeicons.dart';

class ChoreDetailScreen extends ConsumerStatefulWidget {
  const ChoreDetailScreen({required this.choreId, super.key});

  static const String routeBasePath = '/chores';

  final String choreId;

  @override
  ConsumerState<ChoreDetailScreen> createState() => _ChoreDetailScreenState();
}

class _ChoreDetailScreenState extends ConsumerState<ChoreDetailScreen> {
  ProviderSubscription<ChoreActionState>? _subscription;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<ChoreActionState>(choreNotifierProvider, (
      ChoreActionState? previous,
      ChoreActionState next,
    ) {
      if (!mounted || next.message == null) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.message!)));
      ref.read(choreNotifierProvider.notifier).clearMessage();
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final choreAsync = ref.watch(choreDetailProvider(widget.choreId));
    final membersAsync = ref.watch(choreMemberLookupProvider);
    final completionsAsync = ref.watch(
      choreCompletionsProvider(widget.choreId),
    );
    final roleAsync = ref.watch(currentHouseholdRoleProvider);
    return choreAsync.when(
      data: (ChoreEntity? chore) {
        if (chore == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chore Detail')),
            body: const Center(child: Text('Chore not found.')),
          );
        }
        return membersAsync.when(
          data: (Map<String, HouseholdMember> memberLookup) {
            final memberNames = memberLookup.map<String, String>(
              (String key, HouseholdMember value) =>
                  MapEntry<String, String>(key, value.displayName),
            );
            return Scaffold(
              body: Stack(
                children: <Widget>[
                  CustomScrollView(
                    slivers: <Widget>[
                      SliverAppBar(
                        pinned: true,
                        expandedHeight: 190,
                        backgroundColor: AppColors.surfaceVariantFor(
                          brightness,
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          title: Text(
                            chore.title,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.textPrimaryFor(brightness),
                            ),
                          ),
                          background: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: <Widget>[
                                  _TagPill(label: chore.areaTag.label),
                                  _TagPill(label: chore.frequency.label),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(<Widget>[
                            HearthCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _DetailRow(
                                    label: 'Estimated time',
                                    value: '~${chore.estimatedMinutes} minutes',
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _DetailRow(
                                    label: 'Frequency',
                                    value: _frequencyDescription(chore),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Assignment',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.textSecondaryFor(
                                        brightness,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: chore.assignedToUserIds.map((
                                      String userId,
                                    ) {
                                      final isCurrent =
                                          userId == chore.currentAssigneeUserId;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? AppColors.primaryContainerFor(
                                                  brightness,
                                                )
                                              : AppColors.surfaceVariantFor(
                                                  brightness,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.radiusFull,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            HearthAvatar(
                                              displayName:
                                                  memberNames[userId] ??
                                                  'House',
                                              size: 32,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Text(
                                              memberNames[userId] ?? 'Unknown',
                                              style: AppTextStyles.labelLarge
                                                  .copyWith(
                                                    color: isCurrent
                                                        ? AppColors.primaryFor(
                                                            brightness,
                                                          )
                                                        : AppColors.textSecondaryFor(
                                                            brightness,
                                                          ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _DetailRow(
                                    label: 'Next due',
                                    value: _dueDescription(chore.nextDueAt),
                                    valueColor: _daysUntil(chore.nextDueAt) < 3
                                        ? AppColors.accentFor(brightness)
                                        : AppColors.textPrimaryFor(brightness),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ChoreStreakBadge(
                                    streakCount: chore.streakCount,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const HearthSectionHeader(
                              title: 'Completion History',
                              subtitle:
                                  'Every cleanup pass and proof captured so far.',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            completionsAsync.when(
                              data: (List<ChoreCompletionEntity> completions) {
                                if (completions.isEmpty) {
                                  return HearthCard(
                                    child: Text(
                                      'No completion history yet.',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondaryFor(
                                          brightness,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return Column(
                                  children: List<Widget>.generate(completions.length, (
                                    int index,
                                  ) {
                                    final completion = completions[index];
                                    return HearthListItemEntry(
                                      index: index,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.md,
                                        ),
                                        child: HearthCard(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              HearthAvatar(
                                                displayName:
                                                    memberNames[completion
                                                        .completedByUserId] ??
                                                    'Unknown',
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.md,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      memberNames[completion
                                                              .completedByUserId] ??
                                                          'Unknown',
                                                      style: AppTextStyles
                                                          .titleLarge
                                                          .copyWith(
                                                            color:
                                                                AppColors.textPrimaryFor(
                                                                  brightness,
                                                                ),
                                                          ),
                                                    ),
                                                    const SizedBox(
                                                      height: AppSpacing.xs,
                                                    ),
                                                    Text(
                                                      _dateTimeLabel(
                                                        completion.completedAt,
                                                      ),
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                            color:
                                                                AppColors.textSecondaryFor(
                                                                  brightness,
                                                                ),
                                                          ),
                                                    ),
                                                    if (completion.notes !=
                                                        null) ...<Widget>[
                                                      const SizedBox(
                                                        height: AppSpacing.sm,
                                                      ),
                                                      Text(
                                                        completion.notes!,
                                                        style: AppTextStyles
                                                            .bodyMedium
                                                            .copyWith(
                                                              color:
                                                                  AppColors.textPrimaryFor(
                                                                    brightness,
                                                                  ),
                                                            ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: <Widget>[
                                                  _StatusPill(
                                                    label: completion.wasOnTime
                                                        ? 'On time'
                                                        : 'Late',
                                                    color: completion.wasOnTime
                                                        ? AppColors.successFor(
                                                            brightness,
                                                          )
                                                        : AppColors.accentFor(
                                                            brightness,
                                                          ),
                                                  ),
                                                  if (completion
                                                          .photoLocalPath !=
                                                      null) ...<Widget>[
                                                    const SizedBox(
                                                      height: AppSpacing.sm,
                                                    ),
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppRadius.radiusSm,
                                                          ),
                                                      child: Image.file(
                                                        File(
                                                          completion
                                                              .photoLocalPath!,
                                                        ),
                                                        width: 56,
                                                        height: 56,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, __, ___) =>
                                                                const SizedBox.shrink(),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (Object error, _) => Text('$error'),
                            ),
                            const SizedBox(height: 120),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  if (_showCelebration)
                    Positioned.fill(
                      child: HearthCelebration(
                        onCompleted: () {
                          if (mounted) {
                            setState(() {
                              _showCelebration = false;
                            });
                          }
                        },
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: roleAsync.when(
                    data: (HouseholdRole? role) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          HearthButton(
                            label: 'Mark Complete',
                            icon: const Icon(HugeIcons.strokeRoundedTick02),
                            onPressed: () async {
                              final outcome = await showCompleteChoreSheet(
                                context,
                                chore: chore,
                              );
                              if (outcome?.milestoneReached == true &&
                                  mounted) {
                                setState(() {
                                  _showCelebration = true;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          HearthButton(
                            label: 'Defer',
                            variant: HearthButtonVariant.secondary,
                            icon: const Icon(HugeIcons.strokeRoundedClock01),
                            onPressed: () => _deferChore(chore),
                          ),
                          if (role == HouseholdRole.admin) ...<Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            HearthButton(
                              label: 'Delete Chore',
                              variant: HearthButtonVariant.destructive,
                              icon: const Icon(HugeIcons.strokeRoundedDelete02),
                              onPressed: () => _deleteChore(chore.id),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (Object error, _) =>
              Scaffold(body: Center(child: Text('$error'))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, _) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  String _frequencyDescription(ChoreEntity chore) {
    return switch (chore.frequency) {
      ChoreFrequency.daily => 'Daily',
      ChoreFrequency.weekly => 'Every ${_weekday(chore.nextDueAt.weekday)}',
      ChoreFrequency.biweekly =>
        'Every other ${_weekday(chore.nextDueAt.weekday)}',
      ChoreFrequency.monthly => 'Monthly on day ${chore.nextDueAt.day}',
      ChoreFrequency.custom => 'Custom schedule',
    };
  }

  String _dueDescription(DateTime dueAt) {
    final daysUntil = _daysUntil(dueAt);
    final date = '${dueAt.day}/${dueAt.month}/${dueAt.year}';
    if (daysUntil < 0) {
      return '$date • ${daysUntil.abs()} days overdue';
    }
    if (daysUntil == 0) {
      return '$date • due today';
    }
    return '$date • in $daysUntil days';
  }

  int _daysUntil(DateTime dueAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueAt.year, dueAt.month, dueAt.day);
    return target.difference(today).inDays;
  }

  String _dateTimeLabel(DateTime value) {
    final hour = value.hour == 0 || value.hour == 12 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} • $hour:$minute $period';
  }

  String _weekday(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      _ => 'Sunday',
    };
  }

  Future<void> _deferChore(ChoreEntity chore) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: chore.nextDueAt.isBefore(DateTime.now())
          ? DateTime.now()
          : chore.nextDueAt,
    );
    if (picked == null) {
      return;
    }
    final newDueAt = DateTime(picked.year, picked.month, picked.day, 9);
    try {
      await ref
          .read(choreNotifierProvider.notifier)
          .deferChore(choreId: chore.id, newDueAt: newDueAt);
    } on StateError {
      // handled through notifier listener
    }
  }

  Future<void> _deleteChore(String choreId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete chore?'),
          content: const Text(
            'This removes the chore and its completion history.',
          ),
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
    try {
      await ref.read(choreNotifierProvider.notifier).deleteChore(choreId);
      if (!mounted) {
        return;
      }
      context.pop();
    } on StateError {
      // handled through notifier listener
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondaryFor(brightness),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.titleLarge.copyWith(
              color: valueColor ?? AppColors.textPrimaryFor(brightness),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(brightness),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondaryFor(brightness),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }
}
