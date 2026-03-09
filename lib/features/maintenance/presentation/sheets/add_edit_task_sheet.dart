import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/presentation/providers/asset_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_task_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/vendor_providers.dart';
import 'package:uuid/uuid.dart';

Future<void> showAddEditTaskSheet(
  BuildContext context, {
  MaintenanceTask? initialTask,
  String? lockedAssetId,
}) {
  return showHearthBottomSheet<void>(
    context: context,
    initialChildSize: 0.88,
    maxChildSize: 0.96,
    builder: (BuildContext context) {
      return AddEditTaskSheet(
        initialTask: initialTask,
        lockedAssetId: lockedAssetId,
      );
    },
  );
}

class AddEditTaskSheet extends ConsumerStatefulWidget {
  const AddEditTaskSheet({
    this.initialTask,
    this.lockedAssetId,
    super.key,
  });

  final MaintenanceTask? initialTask;
  final String? lockedAssetId;

  @override
  ConsumerState<AddEditTaskSheet> createState() => _AddEditTaskSheetState();
}

class _AddEditTaskSheetState extends ConsumerState<AddEditTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _estimatedCostController = TextEditingController();
  final TextEditingController _customDaysController = TextEditingController();

  MaintenanceRecurrence _recurrence = MaintenanceRecurrence.none;
  DateTime? _dueDate;
  String? _selectedAssetId;
  String? _selectedVendorId;
  String? _selectedAssigneeId;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdId = ref.watch(maintenanceHouseholdIdProvider);
    final userId = ref.watch(maintenanceCurrentUserIdProvider);
    if (!_initialized) {
      _initialize();
    }
    if (householdId == null || userId == null) {
      return const SizedBox.shrink();
    }
    final assetsAsync = ref.watch(assetsProvider(householdId));
    final vendorsAsync = ref.watch(vendorsProvider(householdId));
    final membersAsync = ref.watch(maintenanceMembersProvider);
    final notifierState = ref.watch(maintenanceTaskNotifierProvider);
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.initialTask == null ? 'Add Task' : 'Edit Task',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        HearthTextField(label: 'Title', controller: _titleController),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Description',
          controller: _descriptionController,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Link to Asset',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        assetsAsync.when(
          data: (assets) {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                HearthChip(
                  label: 'No asset',
                  selected: _selectedAssetId == null,
                  onTap: widget.lockedAssetId != null
                      ? () {}
                      : () {
                          setState(() {
                            _selectedAssetId = null;
                          });
                        },
                ),
                ...assets.map((asset) {
                  return HearthChip(
                    label: asset.name,
                    selected: _selectedAssetId == asset.id,
                    onTap: widget.lockedAssetId != null
                        ? () {}
                        : () {
                            setState(() {
                              _selectedAssetId = asset.id;
                            });
                          },
                  );
                }),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (Object error, _) => Text('$error'),
        ),
        const SizedBox(height: AppSpacing.md),
        _TaskDateRow(
          label: 'Due Date',
          value: _dueDate,
          onPressed: () => _pickDate((DateTime value) {
            setState(() {
              _dueDate = value;
            });
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Recurrence',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: MaintenanceRecurrence.values.map((MaintenanceRecurrence recurrence) {
            return HearthChip(
              label: recurrence.label,
              selected: _recurrence == recurrence,
              onTap: () {
                setState(() {
                  _recurrence = recurrence;
                });
              },
            );
          }).toList(),
        ),
        if (_recurrence == MaintenanceRecurrence.custom) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          HearthTextField(
            label: 'Every X days',
            controller: _customDaysController,
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Assign To',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        membersAsync.when(
          data: (members) {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                HearthChip(
                  label: 'Unassigned',
                  selected: _selectedAssigneeId == null,
                  onTap: () {
                    setState(() {
                      _selectedAssigneeId = null;
                    });
                  },
                ),
                ...members.map((member) {
                  return HearthChip(
                    label: member.displayName,
                    selected: _selectedAssigneeId == member.userId,
                    onTap: () {
                      setState(() {
                        _selectedAssigneeId = member.userId;
                      });
                    },
                  );
                }),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (Object error, _) => Text('$error'),
        ),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Estimated Cost',
          controller: _estimatedCostController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Link to Vendor',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        vendorsAsync.when(
          data: (vendors) {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                HearthChip(
                  label: 'No vendor',
                  selected: _selectedVendorId == null,
                  onTap: () {
                    setState(() {
                      _selectedVendorId = null;
                    });
                  },
                ),
                ...vendors.map((Vendor vendor) {
                  return HearthChip(
                    label: vendor.businessName,
                    selected: _selectedVendorId == vendor.id,
                    onTap: () {
                      setState(() {
                        _selectedVendorId = vendor.id;
                      });
                    },
                  );
                }),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (Object error, _) => Text('$error'),
        ),
        const SizedBox(height: AppSpacing.xl),
        HearthButton(
          label: 'Save Task',
          isLoading: notifierState.isLoading,
          onPressed: () => _save(householdId, userId),
        ),
        const SizedBox(height: AppSpacing.sm),
        HearthButton(
          label: 'Cancel',
          variant: HearthButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  void _initialize() {
    final initial = widget.initialTask;
    if (initial != null) {
      _titleController.text = initial.title;
      _descriptionController.text = initial.description ?? '';
      _estimatedCostController.text = initial.estimatedCost?.toString() ?? '';
      _recurrence = initial.recurrence;
      _dueDate = initial.dueDate;
      _selectedAssetId = widget.lockedAssetId ?? initial.assetId;
      _selectedVendorId = initial.vendorId;
      _selectedAssigneeId = initial.assignedToUserId;
      if (initial.recurrence == MaintenanceRecurrence.custom &&
          initial.recurrenceRule != null) {
        _customDaysController.text = RegExp(r'(\d+)')
                .firstMatch(initial.recurrenceRule!)
                ?.group(1) ??
            '';
      }
    } else if (widget.lockedAssetId != null) {
      _selectedAssetId = widget.lockedAssetId;
    }
    _initialized = true;
  }

  Future<void> _pickDate(ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      initialDate: _dueDate ?? DateTime.now(),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _save(String householdId, String userId) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    final recurrenceRule = switch (_recurrence) {
      MaintenanceRecurrence.none => 'none',
      MaintenanceRecurrence.monthly => 'monthly',
      MaintenanceRecurrence.quarterly => 'quarterly',
      MaintenanceRecurrence.annually => 'annually',
      MaintenanceRecurrence.custom =>
        'every_${int.tryParse(_customDaysController.text.trim()) ?? 30}_days',
    };

    final task = MaintenanceTask(
      id: widget.initialTask?.id ?? const Uuid().v4(),
      householdId: householdId,
      assetId: _selectedAssetId,
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      assignedToUserId: _selectedAssigneeId,
      dueDate: _dueDate,
      recurrence: _recurrence,
      recurrenceRule: recurrenceRule,
      estimatedCost: double.tryParse(_estimatedCostController.text.trim()),
      status: widget.initialTask?.status ?? MaintenanceTaskStatus.pending,
      completedAt: widget.initialTask?.completedAt,
      completedByUserId: widget.initialTask?.completedByUserId,
      actualCost: widget.initialTask?.actualCost,
      vendorId: _selectedVendorId,
      completionNotes: widget.initialTask?.completionNotes,
      completionPhotoPath: widget.initialTask?.completionPhotoPath,
      createdAt: widget.initialTask?.createdAt ?? DateTime.now(),
      createdByUserId: widget.initialTask?.createdByUserId ?? userId,
    );

    try {
      if (widget.initialTask == null) {
        await ref.read(maintenanceTaskNotifierProvider.notifier).addTask(task);
      } else {
        await ref.read(maintenanceTaskNotifierProvider.notifier).updateTask(task);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save task right now.')),
      );
    }
  }
}

class _TaskDateRow extends StatelessWidget {
  const _TaskDateRow({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryFor(Theme.of(context).brightness),
            ),
          ),
        ),
        HearthButton(
          label: value == null ? 'Set date' : '${value!.day}/${value!.month}/${value!.year}',
          expanded: false,
          variant: HearthButtonVariant.ghost,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
