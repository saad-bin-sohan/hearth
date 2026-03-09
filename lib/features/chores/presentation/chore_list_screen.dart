import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/chores/presentation/chore_detail_screen.dart';
import 'package:hearth/features/chores/presentation/chore_notifier.dart';
import 'package:hearth/features/chores/presentation/widgets/add_edit_chore_sheet.dart';
import 'package:hearth/features/chores/presentation/widgets/chore_card.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hugeicons/hugeicons.dart';

enum _ChoreStatusFilter { active, overdue, all }

class ChoreListScreen extends ConsumerStatefulWidget {
  const ChoreListScreen({super.key});

  static const String routePath = '/chores/list';

  @override
  ConsumerState<ChoreListScreen> createState() => _ChoreListScreenState();
}

class _ChoreListScreenState extends ConsumerState<ChoreListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedAssigneeIds = <String>{};
  final Set<ChoreAreaTag> _selectedAreaTags = <ChoreAreaTag>{};
  _ChoreStatusFilter _statusFilter = _ChoreStatusFilter.all;
  final Set<String> _animatedCompletions = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final choresAsync = ref.watch(choresProvider);
    final membersAsync = ref.watch(choreMemberLookupProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Chores',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => _showFilters(context),
            icon: const Icon(HugeIcons.strokeRoundedFilterHorizontal),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: <Widget>[
            HearthTextField(
              label: 'Search chores',
              controller: _searchController,
              prefix: const Icon(HugeIcons.strokeRoundedSearch01),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: membersAsync.when(
                data: (Map<String, HouseholdMember> memberLookup) {
                  final names = memberLookup.map<String, String>(
                    (String key, HouseholdMember value) =>
                        MapEntry<String, String>(key, value.displayName),
                  );
                  return choresAsync.when(
                    data: (List<ChoreEntity> chores) {
                      final filtered = _applyFilters(chores);
                      if (filtered.isEmpty) {
                        return HearthEmptyState(
                          icon: HugeIcons.strokeRoundedCheckList,
                          title: 'No chores yet',
                          body:
                              'Add your first routine to start balancing work across the household.',
                          ctaLabel: 'Add Chore',
                          onCtaPressed: () => showAddEditChoreSheet(context),
                        );
                      }
                      final grouped = <ChoreAreaTag, List<ChoreEntity>>{};
                      for (final chore in filtered) {
                        grouped
                            .putIfAbsent(chore.areaTag, () => <ChoreEntity>[])
                            .add(chore);
                      }
                      var index = 0;
                      return ListView(
                        children: grouped.entries.expand((
                          MapEntry<ChoreAreaTag, List<ChoreEntity>> entry,
                        ) {
                          final widgets = <Widget>[
                            HearthSectionHeader(
                              title: entry.key.label,
                              subtitle: '${entry.value.length} routines',
                            ),
                          ];
                          for (final chore in entry.value) {
                            widgets.add(
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
                                          _completeChore(chore.id),
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
                                        '${ChoreDetailScreen.routeBasePath}/${chore.id}',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return widgets;
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
            ),
          ],
        ),
      ),
    );
  }

  List<ChoreEntity> _applyFilters(List<ChoreEntity> chores) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    return chores.where((ChoreEntity chore) {
      if (query.isNotEmpty &&
          !chore.title.toLowerCase().contains(query) &&
          !(chore.description ?? '').toLowerCase().contains(query)) {
        return false;
      }
      if (_selectedAssigneeIds.isNotEmpty &&
          !_selectedAssigneeIds.any(
            (String userId) => chore.assignedToUserIds.contains(userId),
          )) {
        return false;
      }
      if (_selectedAreaTags.isNotEmpty &&
          !_selectedAreaTags.contains(chore.areaTag)) {
        return false;
      }
      switch (_statusFilter) {
        case _ChoreStatusFilter.active:
          return !chore.nextDueAt.isBefore(now);
        case _ChoreStatusFilter.overdue:
          return chore.nextDueAt.isBefore(now);
        case _ChoreStatusFilter.all:
          return true;
      }
    }).toList();
  }

  Future<void> _showFilters(BuildContext context) async {
    final selectedAssigneeIds = Set<String>.from(_selectedAssigneeIds);
    final selectedAreaTags = Set<ChoreAreaTag>.from(_selectedAreaTags);
    var statusFilter = _statusFilter;
    final members = await ref.read(choreMembersProvider.future);
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: this.context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Filters', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Assignees', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: members.map((member) {
                        final selected = selectedAssigneeIds.contains(
                          member.userId,
                        );
                        return FilterChip(
                          selected: selected,
                          onSelected: (_) {
                            setModalState(() {
                              if (selected) {
                                selectedAssigneeIds.remove(member.userId);
                              } else {
                                selectedAssigneeIds.add(member.userId);
                              }
                            });
                          },
                          label: Text(member.displayName),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Areas', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: ChoreAreaTag.values.map((areaTag) {
                        final selected = selectedAreaTags.contains(areaTag);
                        return FilterChip(
                          selected: selected,
                          onSelected: (_) {
                            setModalState(() {
                              if (selected) {
                                selectedAreaTags.remove(areaTag);
                              } else {
                                selectedAreaTags.add(areaTag);
                              }
                            });
                          },
                          label: Text(areaTag.label),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Status', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children:
                          <_ChoreStatusFilter>[
                            _ChoreStatusFilter.active,
                            _ChoreStatusFilter.overdue,
                            _ChoreStatusFilter.all,
                          ].map((status) {
                            return ChoiceChip(
                              selected: status == statusFilter,
                              onSelected: (_) {
                                setModalState(() {
                                  statusFilter = status;
                                });
                              },
                              label: Text(switch (status) {
                                _ChoreStatusFilter.active => 'Active',
                                _ChoreStatusFilter.overdue => 'Overdue',
                                _ChoreStatusFilter.all => 'All',
                              }),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HearthButton(
                      label: 'Apply Filters',
                      onPressed: () {
                        setState(() {
                          _selectedAssigneeIds
                            ..clear()
                            ..addAll(selectedAssigneeIds);
                          _selectedAreaTags
                            ..clear()
                            ..addAll(selectedAreaTags);
                          _statusFilter = statusFilter;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeChore(String choreId) async {
    setState(() {
      _animatedCompletions.add(choreId);
    });
    try {
      await ref
          .read(choreNotifierProvider.notifier)
          .completeChore(choreId: choreId);
      Future<void>.delayed(AppAnimations.standard, () {
        if (mounted) {
          setState(() {
            _animatedCompletions.remove(choreId);
          });
        }
      });
    } on StateError {
      if (mounted) {
        setState(() {
          _animatedCompletions.remove(choreId);
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
      // handled by notifier state on dashboard/detail flows
    }
  }
}
