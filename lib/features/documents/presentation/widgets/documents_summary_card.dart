import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/presentation/document_notifier.dart';
import 'package:hearth/features/documents/presentation/screens/vault_dashboard_screen.dart';
import 'package:hearth/features/documents/presentation/vault_lock_provider.dart';
import 'package:hugeicons/hugeicons.dart';

class DocumentsSummaryCard extends ConsumerWidget {
  const DocumentsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final documentsAsync = ref.watch(allDocumentsProvider);
    return SizedBox(
      width: 220,
      height: 128,
      child: HearthCard(
        onTap: () {
          context.go(VaultDashboardScreen.routePath);
          if (ref.read(vaultLockProvider) == VaultLockState.locked) {
            ref.read(vaultLockProvider.notifier).requestUnlock();
          }
        },
        child: documentsAsync.when(
          data: (List<DocumentEntity> documents) {
            final expiringSoon = documents
                .where((DocumentEntity document) =>
                    document.expiryUrgency == DocumentExpiryUrgency.warning ||
                    document.expiryUrgency == DocumentExpiryUrgency.critical)
                .length;
            final expired = documents
                .where((DocumentEntity document) =>
                    document.expiryUrgency == DocumentExpiryUrgency.expired)
                .length;
            final footer = expired > 0
                ? (
                    label: '$expired expired',
                    color: AppColors.errorFor(brightness),
                  )
                : expiringSoon > 0
                    ? (
                        label: '$expiringSoon expiring soon',
                        color: AppColors.warningFor(brightness),
                      )
                    : (
                        label: 'All current',
                        color: AppColors.successFor(brightness),
                      );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      HugeIcons.strokeRoundedFolderFileStorage,
                      size: 20,
                      color: AppColors.accentFor(brightness),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Documents',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ),
                HearthNumberTicker(
                  value: '${documents.length}',
                  style: AppTextStyles.numericMedium.copyWith(
                    color: AppColors.accentFor(brightness),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'documents saved',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      footer.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: footer.color,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    HugeIcons.strokeRoundedFolderFileStorage,
                    size: 20,
                    color: AppColors.accentFor(brightness),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Documents',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
              HearthNumberTicker(
                value: '...',
                style: AppTextStyles.numericMedium.copyWith(
                  color: AppColors.accentFor(brightness),
                ),
              ),
              Text(
                'Checking vault',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
            ],
          ),
          error: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    HugeIcons.strokeRoundedFolderFileStorage,
                    size: 20,
                    color: AppColors.accentFor(brightness),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Documents',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
              HearthNumberTicker(
                value: '0',
                style: AppTextStyles.numericMedium.copyWith(
                  color: AppColors.accentFor(brightness),
                ),
              ),
              Text(
                'Vault ready',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
