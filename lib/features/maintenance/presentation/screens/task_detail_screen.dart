import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/presentation/providers/asset_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_task_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/vendor_providers.dart';
import 'package:hearth/features/maintenance/presentation/sheets/add_edit_task_sheet.dart';
import 'package:hearth/features/maintenance/presentation/sheets/complete_task_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));
    final memberLookupAsync = ref.watch(maintenanceMemberLookupProvider);
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(
        title: taskAsync.when(
          data: (task) => Text(
            task?.title ?? 'Task',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          loading: () => Text(
            'Task',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          error: (_, __) => Text(
            'Task',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
        ),
        actions: <Widget>[
          taskAsync.when(
            data: (task) => task == null
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: () => showAddEditTaskSheet(
                      context,
                      initialTask: task,
                    ),
                    icon: const Icon(HugeIcons.strokeRoundedEdit02),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: taskAsync.when(
        data: (task) {
          if (task == null) {
            return const Center(child: Text('Task not found.'));
          }
          final assetAsync = task.assetId == null
              ? const AsyncValue.data(null)
              : ref.watch(assetDetailProvider(task.assetId!));
          final vendorAsync = task.vendorId == null
              ? const AsyncValue.data(null)
              : ref.watch(vendorDetailProvider(task.vendorId!));
          final completedBy =
              memberLookupAsync.valueOrNull?[task.completedByUserId]?.displayName;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              HearthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: switch (task.status) {
                          MaintenanceTaskStatus.pending =>
                            AppColors.primaryContainerFor(brightness),
                          MaintenanceTaskStatus.overdue => AppColors.errorContainer,
                          MaintenanceTaskStatus.completed => AppColors.successContainer,
                        },
                        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                      ),
                      child: Text(
                        task.status.label,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: switch (task.status) {
                            MaintenanceTaskStatus.pending =>
                              AppColors.primaryFor(brightness),
                            MaintenanceTaskStatus.overdue =>
                              AppColors.errorFor(brightness),
                            MaintenanceTaskStatus.completed =>
                              AppColors.successFor(brightness),
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (task.dueDate != null)
                      _DetailRow(
                        icon: HugeIcons.strokeRoundedCalendar01,
                        label: 'Due',
                        value: AppFormatters.shortDate(task.dueDate!),
                      ),
                    if (task.recurrence != MaintenanceRecurrence.none)
                      _DetailRow(
                        icon: HugeIcons.strokeRoundedRepeat,
                        label: 'Recurrence',
                        value: task.recurrence.label,
                      ),
                    if (task.assetId != null)
                      _DetailRow(
                        icon: HugeIcons.strokeRoundedWrench01,
                        label: 'Linked Asset',
                        value: assetAsync.valueOrNull?.name ?? 'Linked asset',
                        onTap: () => context.push('/maintenance/assets/${task.assetId}'),
                      ),
                    if (task.assignedToUserId != null)
                      _DetailRow(
                        icon: HugeIcons.strokeRoundedUserGroup,
                        label: 'Assigned To',
                        value:
                            memberLookupAsync.valueOrNull?[task.assignedToUserId]
                                ?.displayName ??
                            'Member',
                      ),
                    if (task.estimatedCost != null)
                      _DetailRow(
                        icon: HugeIcons.strokeRoundedInvoice03,
                        label: 'Estimated Cost',
                        value: '\$${task.estimatedCost!.toStringAsFixed(2)}',
                      ),
                    if (task.vendorId != null)
                      _DetailRow(
                        icon: HugeIcons.strokeRoundedStore01,
                        label: 'Vendor',
                        value: vendorAsync.valueOrNull?.businessName ?? 'Vendor',
                        onTap: () =>
                            context.push('/maintenance/vendors/${task.vendorId}'),
                      ),
                    if (task.status == MaintenanceTaskStatus.completed) ...<Widget>[
                      const Divider(height: AppSpacing.xl),
                      if (task.completedAt != null)
                        _DetailRow(
                          icon: HugeIcons.strokeRoundedTick02,
                          label: 'Completed',
                          value:
                              '${AppFormatters.shortDate(task.completedAt!)}${completedBy == null ? '' : ' by $completedBy'}',
                        ),
                      if (task.actualCost != null)
                        _DetailRow(
                          icon: HugeIcons.strokeRoundedInvoice03,
                          label: 'Actual Cost',
                          value: '\$${task.actualCost!.toStringAsFixed(2)}',
                        ),
                      if (task.completionNotes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(task.completionNotes!),
                        ),
                      if (task.completionPhotoPath != null &&
                          File(task.completionPhotoPath!).existsSync()) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                          child: Image.file(
                            File(task.completionPhotoPath!),
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Center(child: Text('$error')),
      ),
      bottomNavigationBar: taskAsync.when(
        data: (task) {
          if (task == null) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            minimum: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                if (task.status != MaintenanceTaskStatus.completed)
                  Expanded(
                    child: HearthButton(
                      label: 'Mark Complete',
                      onPressed: () async {
                        final assetName = task.assetId == null
                            ? null
                            : (await ref.read(assetDetailProvider(task.assetId!).future))
                                  ?.name;
                        if (!context.mounted) {
                          return;
                        }
                        final nextDue = await showCompleteTaskSheet(
                          context,
                          task: task,
                          assetName: assetName,
                        );
                        if (!context.mounted || nextDue == null) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Next task scheduled for ${AppFormatters.shortDate(nextDue)}.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (task.status != MaintenanceTaskStatus.completed)
                  const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: HearthButton(
                    label: task.status == MaintenanceTaskStatus.completed
                        ? 'Edit Details'
                        : 'Edit',
                    variant: HearthButtonVariant.ghost,
                    onPressed: () => showAddEditTaskSheet(
                      context,
                      initialTask: task,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final child = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.textSecondaryFor(brightness)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) const Icon(HugeIcons.strokeRoundedArrowRight01),
        ],
      ),
    );
    if (onTap == null) {
      return child;
    }
    return InkWell(onTap: onTap, child: child);
  }
}
