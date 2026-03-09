import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_celebration.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/chores/presentation/chore_list_screen.dart';
import 'package:hearth/features/chores/presentation/chore_notifier.dart';
import 'package:hearth/features/chores/presentation/fairness_score_screen.dart';
import 'package:hearth/features/chores/presentation/widgets/chore_card.dart';
import 'package:hearth/features/chores/presentation/widgets/fairness_bar.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hugeicons/hugeicons.dart';

class ChoresDashboardScreen extends ConsumerStatefulWidget {
  const ChoresDashboardScreen({super.key});

  static const String routePath = '/chores';

  @override
  ConsumerState<ChoresDashboardScreen> createState() =>
      _ChoresDashboardScreenState();
}

class _ChoresDashboardScreenState extends ConsumerState<ChoresDashboardScreen> {
  ProviderSubscription<ChoreActionState>? _subscription;
  final Set<String> _animatedCompletions = <String>{};
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
    final todaysChoresAsync = ref.watch(todaysChoresProvider);
    final thisWeekChoresAsync = ref.watch(thisWeekChoresProvider);
    final membersAsync = ref.watch(choreMemberLookupProvider);
    final fairnessEntriesAsync = ref.watch(fairnessEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chores',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push(FairnessScoreScreen.routePath),
            icon: const Icon(HugeIcons.strokeRoundedChartLineData01),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              const HearthSectionHeader(
                title: 'My Tasks Today',
                subtitle: 'The work already sitting on your side of the home.',
              ),
              const SizedBox(height: AppSpacing.sm),
              membersAsync.when(
                data: (Map<String, HouseholdMember> memberLookup) {
                  final names = memberLookup.map<String, String>(
                    (String key, HouseholdMember value) =>
                        MapEntry<String, String>(key, value.displayName),
                  );
                  return todaysChoresAsync.when(
                    data: (List<ChoreEntity> chores) {
                      if (chores.isEmpty) {
                        return SizedBox(
                          height: 180,
                          child: HearthCard(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  HugeIcons.strokeRoundedTickDouble02,
                                  color: AppColors.successFor(brightness),
                                  size: 28,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Nothing due today',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.textPrimaryFor(brightness),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'A quiet board is a good board.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondaryFor(
                                      brightness,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 178,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: chores.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (BuildContext context, int index) {
                            final chore = chores[index];
                            return SizedBox(
                              width: 300,
                              child: ChoreCard(
                                chore: chore,
                                memberDisplayNames: names,
                                animateCompletion: _animatedCompletions
                                    .contains(chore.id),
                                onTap: () => context.push(
                                  '${ChoresDashboardScreen.routePath}/${chore.id}',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (Object error, _) => Text('$error'),
                  );
                },
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object error, _) => Text('$error'),
              ),
              const SizedBox(height: AppSpacing.xl),
              HearthSectionHeader(
                title: 'This Week',
                subtitle: 'Swipe to close loops quickly or defer responsibly.',
                actionLabel: 'See All',
                onActionPressed: () => context.push(ChoreListScreen.routePath),
              ),
              const SizedBox(height: AppSpacing.sm),
              membersAsync.when(
                data: (Map<String, HouseholdMember> memberLookup) {
                  final names = memberLookup.map<String, String>(
                    (String key, HouseholdMember value) =>
                        MapEntry<String, String>(key, value.displayName),
                  );
                  return thisWeekChoresAsync.when(
                    data: (List<ChoreEntity> chores) {
                      if (chores.isEmpty) {
                        return const SizedBox(
                          height: 280,
                          child: HearthEmptyState(
                            icon: HugeIcons.strokeRoundedCheckList,
                            title: 'No chores lined up this week',
                            body:
                                'Add a recurring routine to keep the household steady.',
                          ),
                        );
                      }
                      final grouped = _groupByDay(chores);
                      var index = 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: grouped.entries.expand((
                          MapEntry<String, List<ChoreEntity>> entry,
                        ) {
                          final children = <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                entry.key,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.textSecondaryFor(brightness),
                                ),
                              ),
                            ),
                          ];
                          for (final chore in entry.value) {
                            children.add(
                              HearthListItemEntry(
                                index: index++,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: HearthSwipeToAction(
                                    leadingAction: HearthSwipeAction(
                                      icon: HugeIcons.strokeRoundedTick02,
                                      label: 'Complete',
                                      color: AppColors.successFor(brightness),
                                      onTriggered: () =>
                                          _completeFromSwipe(chore),
                                    ),
                                    trailingAction: HearthSwipeAction(
                                      icon: HugeIcons.strokeRoundedClock01,
                                      label: 'Defer',
                                      color: AppColors.accentFor(brightness),
                                      onTriggered: () => _deferChore(chore),
                                    ),
                                    child: ChoreCard(
                                      chore: chore,
                                      memberDisplayNames: names,
                                      animateCompletion: _animatedCompletions
                                          .contains(chore.id),
                                      onTap: () => context.push(
                                        '${ChoresDashboardScreen.routePath}/${chore.id}',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return children;
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (Object error, _) => Text('$error'),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, _) => Text('$error'),
              ),
              const SizedBox(height: AppSpacing.lg),
              HearthSectionHeader(
                title: 'Fairness Score',
                subtitle: 'A live view of how the household load is landing.',
                actionLabel: 'Full View',
                onActionPressed: () =>
                    context.push(FairnessScoreScreen.routePath),
              ),
              const SizedBox(height: AppSpacing.sm),
              fairnessEntriesAsync.when(
                data: (List<FairnessScoreEntry> entries) {
                  if (entries.isEmpty) {
                    return HearthCard(
                      child: Text(
                        'Once chores start getting completed, fairness scores will settle in here.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryFor(brightness),
                        ),
                      ),
                    );
                  }
                  return HearthCard(
                    child: Column(
                      children: List<Widget>.generate(entries.take(4).length, (
                        int index,
                      ) {
                        final entry = entries[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == entries.take(4).length - 1
                                ? 0
                                : AppSpacing.md,
                          ),
                          child: Row(
                            children: <Widget>[
                              HearthAvatar(
                                displayName: entry.displayName,
                                size: 40,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      entry.displayName,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.textPrimaryFor(
                                          brightness,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    FairnessBar(
                                      score: entry.score,
                                      compact: true,
                                      delay: Duration(
                                        milliseconds: index * 100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, _) => Text('$error'),
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
    );
  }

  Map<String, List<ChoreEntity>> _groupByDay(List<ChoreEntity> chores) {
    final map = <String, List<ChoreEntity>>{};
    for (final chore in chores) {
      final label = _dayLabel(chore.nextDueAt);
      map.putIfAbsent(label, () => <ChoreEntity>[]).add(chore);
    }
    return map;
  }

  String _dayLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final diff = target.difference(today).inDays;
    if (diff < 0) {
      return 'Overdue';
    }
    if (diff == 0) {
      return 'Today';
    }
    if (diff == 1) {
      return 'Tomorrow';
    }
    return switch (target.weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      _ => 'Sunday',
    };
  }

  Future<void> _completeFromSwipe(ChoreEntity chore) async {
    setState(() {
      _animatedCompletions.add(chore.id);
    });
    try {
      final outcome = await ref
          .read(choreNotifierProvider.notifier)
          .completeChore(choreId: chore.id);
      if (outcome.milestoneReached && mounted) {
        setState(() {
          _showCelebration = true;
        });
      }
      unawaited(
        Future<void>.delayed(AppAnimations.standard, () {
          if (mounted) {
            setState(() {
              _animatedCompletions.remove(chore.id);
            });
          }
        }),
      );
    } on StateError {
      if (mounted) {
        setState(() {
          _animatedCompletions.remove(chore.id);
        });
      }
    }
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
      // Message is handled by the notifier listener.
    }
  }
}
