import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/chores/presentation/chore_notifier.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hugeicons/hugeicons.dart';

Future<void> showAddEditChoreSheet(
  BuildContext context, {
  ChoreEntity? initialChore,
}) {
  return showHearthBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return AddEditChoreSheet(initialChore: initialChore);
    },
  );
}

class AddEditChoreSheet extends ConsumerStatefulWidget {
  const AddEditChoreSheet({this.initialChore, super.key});

  final ChoreEntity? initialChore;

  @override
  ConsumerState<AddEditChoreSheet> createState() => _AddEditChoreSheetState();
}

class _AddEditChoreSheetState extends ConsumerState<AddEditChoreSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  static const List<int> _minutePresets = <int>[
    5,
    10,
    15,
    20,
    30,
    45,
    60,
    90,
    120,
  ];
  static const List<int> _weekdays = <int>[1, 2, 3, 4, 5, 6, 7];

  ChoreAreaTag _selectedAreaTag = ChoreAreaTag.general;
  int _selectedMinutes = 15;
  ChoreFrequency _selectedFrequency = ChoreFrequency.weekly;
  ChoreAssignmentType _assignmentType = ChoreAssignmentType.fixed;
  DateTime _startDate = DateTime.now();
  int _selectedWeekday = DateTime.now().weekday;
  int _selectedDayOfMonth = DateTime.now().day;
  List<String> _selectedUserIds = <String>[];
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(currentHouseholdProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final actionState = ref.watch(choreNotifierProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: householdAsync.when(
          data: (household) => membersAsync.when(
            data: (members) {
              if (household == null) {
                return const SizedBox.shrink();
              }
              _initialize(members);
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.initialChore == null ? 'Save Chore' : 'Edit Chore',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimaryFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Create a shared routine with clear ownership, timing, and a visible fairness impact.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HearthTextField(
                      label: 'Title',
                      controller: _titleController,
                      validator: (String? value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Use at least 3 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    HearthTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Area',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimaryFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: ChoreAreaTag.values.map((ChoreAreaTag areaTag) {
                        return HearthChip(
                          label: areaTag.label,
                          selected: areaTag == _selectedAreaTag,
                          onTap: () {
                            setState(() {
                              _selectedAreaTag = areaTag;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Estimated Minutes',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimaryFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _minutePresets.map((int minutes) {
                        return HearthChip(
                          label: '$minutes min',
                          selected: minutes == _selectedMinutes,
                          onTap: () {
                            setState(() {
                              _selectedMinutes = minutes;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Frequency',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimaryFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children:
                          <ChoreFrequency>[
                            ChoreFrequency.daily,
                            ChoreFrequency.weekly,
                            ChoreFrequency.biweekly,
                            ChoreFrequency.monthly,
                          ].map((ChoreFrequency frequency) {
                            return HearthChip(
                              label: frequency.label,
                              selected: frequency == _selectedFrequency,
                              onTap: () {
                                setState(() {
                                  _selectedFrequency = frequency;
                                });
                              },
                            );
                          }).toList(),
                    ),
                    if (_selectedFrequency == ChoreFrequency.weekly ||
                        _selectedFrequency ==
                            ChoreFrequency.biweekly) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Day of week',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondaryFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _weekdays.map((int weekday) {
                          return HearthChip(
                            label: _weekdayLabel(weekday),
                            selected: weekday == _selectedWeekday,
                            onTap: () {
                              setState(() {
                                _selectedWeekday = weekday;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    if (_selectedFrequency ==
                        ChoreFrequency.monthly) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Day of month',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondaryFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: List<Widget>.generate(12, (int index) {
                          final day = ((index + 1) * 2).clamp(1, 28);
                          return HearthChip(
                            label: '$day',
                            selected: day == _selectedDayOfMonth,
                            onTap: () {
                              setState(() {
                                _selectedDayOfMonth = day;
                              });
                            },
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Assignment',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimaryFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: HearthButton(
                            label: 'Fixed Member',
                            variant:
                                _assignmentType == ChoreAssignmentType.fixed
                                ? HearthButtonVariant.primary
                                : HearthButtonVariant.ghost,
                            onPressed: () {
                              setState(() {
                                _assignmentType = ChoreAssignmentType.fixed;
                                if (_selectedUserIds.length > 1) {
                                  _selectedUserIds = <String>[
                                    _selectedUserIds.first,
                                  ];
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: HearthButton(
                            label: 'Rotation',
                            variant:
                                _assignmentType == ChoreAssignmentType.rotation
                                ? HearthButtonVariant.secondary
                                : HearthButtonVariant.ghost,
                            onPressed: () {
                              setState(() {
                                _assignmentType = ChoreAssignmentType.rotation;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: members.map((HouseholdMember member) {
                        final selected = _selectedUserIds.contains(
                          member.userId,
                        );
                        return InkWell(
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusFull,
                          ),
                          onTap: () => _toggleAssignee(member.userId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryContainerFor(
                                      Theme.of(context).brightness,
                                    )
                                  : AppColors.surfaceVariantFor(
                                      Theme.of(context).brightness,
                                    ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.radiusFull,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                HearthAvatar(
                                  displayName: member.displayName,
                                  size: 32,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  member.displayName,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: selected
                                        ? AppColors.primaryFor(
                                            Theme.of(context).brightness,
                                          )
                                        : AppColors.textSecondaryFor(
                                            Theme.of(context).brightness,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_assignmentType == ChoreAssignmentType.rotation &&
                        _selectedUserIds.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Rotation order',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondaryFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: _reorderAssignees,
                        children: List<Widget>.generate(
                          _selectedUserIds.length,
                          (int index) {
                            final member = members.firstWhere(
                              (HouseholdMember entry) =>
                                  entry.userId == _selectedUserIds[index],
                            );
                            return Container(
                              key: ValueKey<String>(member.userId),
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariantFor(
                                  Theme.of(context).brightness,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.radiusMd,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  HearthAvatar(
                                    displayName: member.displayName,
                                    size: 36,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      '${index + 1}. ${member.displayName}',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.textPrimaryFor(
                                          Theme.of(context).brightness,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Icon(
                                      HugeIcons.strokeRoundedMove,
                                      color: AppColors.textSecondaryFor(
                                        Theme.of(context).brightness,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Start Date',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimaryFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    HearthButton(
                      label: _startDateLabel(),
                      expanded: false,
                      variant: HearthButtonVariant.ghost,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2100),
                          initialDate: _startDate,
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                          });
                        }
                      },
                    ),
                    if (actionState.message != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        actionState.message!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.errorFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    HearthButton(
                      label: widget.initialChore == null
                          ? 'Save Chore'
                          : 'Update Chore',
                      isLoading: actionState.isLoading,
                      onPressed: () async {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        if (_selectedUserIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Choose at least one assignee.'),
                            ),
                          );
                          return;
                        }
                        final draft = ChoreDraft(
                          id: widget.initialChore?.id,
                          householdId: household.id,
                          title: _titleController.text.trim(),
                          description:
                              _descriptionController.text.trim().isEmpty
                              ? null
                              : _descriptionController.text.trim(),
                          areaTag: _selectedAreaTag,
                          estimatedMinutes: _selectedMinutes,
                          frequency: _selectedFrequency,
                          assignmentType: _assignmentType,
                          assignedToUserIds: _selectedUserIds,
                          currentAssigneeIndex:
                              widget.initialChore?.currentAssigneeIndex ?? 0,
                          nextDueAt: _buildNextDueAt(),
                          isActive: true,
                        );
                        try {
                          if (widget.initialChore == null) {
                            await ref
                                .read(choreNotifierProvider.notifier)
                                .addChore(draft);
                          } else {
                            await ref
                                .read(choreNotifierProvider.notifier)
                                .updateChore(draft);
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } on StateError {
                          // Message is surfaced through the notifier state.
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    HearthButton(
                      label: 'Cancel',
                      variant: HearthButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, _) => Text('$error'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => Text('$error'),
        ),
      ),
    );
  }

  void _initialize(List<HouseholdMember> members) {
    if (_initialized) {
      return;
    }
    final initial = widget.initialChore;
    if (initial != null) {
      _titleController.text = initial.title;
      _descriptionController.text = initial.description ?? '';
      _selectedAreaTag = initial.areaTag;
      _selectedMinutes = initial.estimatedMinutes;
      _selectedFrequency = initial.frequency;
      _assignmentType = initial.assignmentType;
      _selectedUserIds = List<String>.from(initial.assignedToUserIds);
      _startDate = initial.nextDueAt;
      _selectedWeekday = initial.nextDueAt.weekday;
      _selectedDayOfMonth = initial.nextDueAt.day.clamp(1, 28);
    } else if (members.isNotEmpty) {
      _selectedUserIds = <String>[members.first.userId];
    }
    _initialized = true;
  }

  void _toggleAssignee(String userId) {
    setState(() {
      if (_assignmentType == ChoreAssignmentType.fixed) {
        _selectedUserIds = <String>[userId];
        return;
      }
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds = _selectedUserIds
            .where((String id) => id != userId)
            .toList();
      } else {
        _selectedUserIds = <String>[..._selectedUserIds, userId];
      }
    });
  }

  void _reorderAssignees(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final updated = List<String>.from(_selectedUserIds);
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _selectedUserIds = updated;
    });
  }

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      _ => 'Sun',
    };
  }

  String _startDateLabel() {
    return '${_startDate.day}/${_startDate.month}/${_startDate.year}';
  }

  DateTime _buildNextDueAt() {
    final anchor = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      9,
    );
    switch (_selectedFrequency) {
      case ChoreFrequency.daily:
        return anchor;
      case ChoreFrequency.weekly:
      case ChoreFrequency.biweekly:
        final delta = (_selectedWeekday - anchor.weekday + 7) % 7;
        return anchor.add(Duration(days: delta));
      case ChoreFrequency.monthly:
        var year = anchor.year;
        var month = anchor.month;
        var candidate = _buildMonthDate(
          year: year,
          month: month,
          day: _selectedDayOfMonth,
        );
        if (candidate.isBefore(anchor)) {
          month += 1;
          if (month > 12) {
            month = 1;
            year += 1;
          }
          candidate = _buildMonthDate(
            year: year,
            month: month,
            day: _selectedDayOfMonth,
          );
        }
        return candidate;
      case ChoreFrequency.custom:
        return anchor;
    }
  }

  DateTime _buildMonthDate({
    required int year,
    required int month,
    required int day,
  }) {
    final maxDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, maxDay), 9);
  }
}
