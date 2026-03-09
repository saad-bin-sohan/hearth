import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/expiry_status.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/expiry_badge.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/documents/presentation/sheets/add_document_sheet.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/presentation/providers/asset_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_task_providers.dart';
import 'package:hearth/features/maintenance/presentation/sheets/add_edit_asset_sheet.dart';
import 'package:hearth/features/maintenance/presentation/sheets/add_edit_task_sheet.dart';
import 'package:hearth/features/maintenance/presentation/widgets/maintenance_visuals.dart';
import 'package:hearth/features/maintenance/presentation/widgets/task_card.dart';
import 'package:hugeicons/hugeicons.dart';

class AssetDetailScreen extends ConsumerWidget {
  const AssetDetailScreen({required this.assetId, super.key});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetAsync = ref.watch(assetDetailProvider(assetId));
    final roleAsync = ref.watch(currentHouseholdRoleProvider);
    final memberLookupAsync = ref.watch(maintenanceMemberLookupProvider);
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Asset',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        actions: <Widget>[
          assetAsync.when(
            data: (asset) => asset == null
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: () => showAddEditAssetSheet(context, initialAsset: asset),
                    icon: const Icon(HugeIcons.strokeRoundedEdit02),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: assetAsync.when(
        data: (asset) {
          if (asset == null) {
            return const Center(child: Text('Asset not found.'));
          }
          final badgeUrgency = {
            DateExpiryUrgency.none: ExpiryBadgeUrgency.none,
            DateExpiryUrgency.safe: ExpiryBadgeUrgency.safe,
            DateExpiryUrgency.warning: ExpiryBadgeUrgency.warning,
            DateExpiryUrgency.critical: ExpiryBadgeUrgency.critical,
            DateExpiryUrgency.expired: ExpiryBadgeUrgency.expired,
          }[asset.warrantyUrgency]!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantFor(brightness),
                  borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                ),
                clipBehavior: Clip.antiAlias,
                child: asset.photoLocalPath != null &&
                        File(asset.photoLocalPath!).existsSync()
                    ? Image.file(File(asset.photoLocalPath!), fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          iconForAssetCategory(asset.category),
                          size: 56,
                          color: AppColors.secondaryFor(brightness),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              HearthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      asset.name,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (asset.brand != null) Text(asset.brand!),
                    if (asset.modelNumber != null) Text('Model ${asset.modelNumber!}'),
                    if (asset.serialNumber != null) Text('Serial ${asset.serialNumber!}'),
                    if (asset.locationNote != null) Text(asset.locationNote!),
                    if (asset.purchaseDate != null)
                      Text(AppFormatters.shortDate(asset.purchaseDate!)),
                    if (asset.purchasePrice != null)
                      Text('\$${asset.purchasePrice!.toStringAsFixed(2)}'),
                    const SizedBox(height: AppSpacing.md),
                    if (badgeUrgency == ExpiryBadgeUrgency.none)
                      Text(
                        'No warranty recorded',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiaryFor(brightness),
                        ),
                      )
                    else
                      ExpiryBadge(
                        urgency: badgeUrgency,
                        daysUntil: asset.daysUntilWarranty,
                        date: asset.warrantyExpiry,
                        pulse: badgeUrgency == ExpiryBadgeUrgency.critical,
                        size: ExpiryBadgeSize.large,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              HearthSectionHeader(
                title: 'Linked Documents',
                actionLabel: 'Add Document',
                onActionPressed: () => showAddDocumentSheet(
                  context,
                  preselectedAssetId: asset.id,
                  preselectedAssetLabel: asset.name,
                ),
              ),
              ref.watch(linkedDocumentsForAssetProvider(asset.id)).when(
                data: (documents) {
                  if (documents.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No documents linked.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiaryFor(brightness),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        final document = documents[index];
                        return GestureDetector(
                          onTap: () => context.push('/documents/${document.id}'),
                          child: SizedBox(
                            width: 132,
                            child: HearthCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Center(
                                      child: Icon(
                                        document.mimeType == 'application/pdf'
                                            ? HugeIcons.strokeRoundedPdf01
                                            : HugeIcons.strokeRoundedFile01,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    document.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                      itemCount: documents.length,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, _) => Text('$error'),
              ),
              const SizedBox(height: AppSpacing.lg),
              HearthSectionHeader(
                title: 'Upcoming Tasks',
                actionLabel: 'Add Task',
                onActionPressed: () =>
                    showAddEditTaskSheet(context, lockedAssetId: asset.id),
              ),
              ref.watch(assetTasksProvider(asset.id)).when(
                data: (tasks) {
                  final pending = tasks
                      .where((task) => task.status != MaintenanceTaskStatus.completed)
                      .toList();
                  if (pending.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No upcoming tasks.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiaryFor(brightness),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: pending.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: TaskCard(
                          task: task,
                          assigneeName:
                              memberLookupAsync.valueOrNull?[task.assignedToUserId]
                                  ?.displayName,
                          onTap: () => context.push('/maintenance/tasks/${task.id}'),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, _) => Text('$error'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const HearthSectionHeader(title: 'Service History'),
              ref.watch(completedTasksForAssetProvider(asset.id)).when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No service history yet.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiaryFor(brightness),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: tasks.map<Widget>((task) {
                      final completedBy =
                          memberLookupAsync.valueOrNull?[task.completedByUserId]
                              ?.displayName ??
                          'Member';
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppColors.successFor(brightness),
                              width: 2,
                            ),
                            bottom: BorderSide(
                              color: AppColors.dividerFor(brightness),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(task.title, style: AppTextStyles.titleMedium),
                                  Text(
                                    '${task.completedAt == null ? '' : AppFormatters.shortDate(task.completedAt!)} by $completedBy',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondaryFor(brightness),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (task.actualCost != null)
                              Text(
                                '\$${task.actualCost!.toStringAsFixed(2)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiaryFor(brightness),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, _) => Text('$error'),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Center(child: Text('$error')),
      ),
      bottomNavigationBar: assetAsync.when(
        data: (asset) {
          if (asset == null) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            minimum: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: HearthButton(
                    label: 'Add Task',
                    onPressed: () => showAddEditTaskSheet(
                      context,
                      lockedAssetId: asset.id,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                if (roleAsync.valueOrNull == HouseholdRole.admin)
                  Expanded(
                    child: HearthButton(
                      label: 'Delete Asset',
                      variant: HearthButtonVariant.destructive,
                      onPressed: () async {
                        await ref.read(assetNotifierProvider.notifier).deleteAsset(asset);
                        if (context.mounted) {
                          context.pop();
                        }
                      },
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
