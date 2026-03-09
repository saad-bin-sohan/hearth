import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/presentation/document_notifier.dart';
import 'package:hugeicons/hugeicons.dart';

class FolderCard extends ConsumerWidget {
  const FolderCard({
    required this.folder,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final VaultFolderEntity folder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final countAsync = ref.watch(folderDocumentCountProvider(folder.fullPath));
    return GestureDetector(
      onLongPress: onLongPress,
      child: HearthCard(
        onTap: onTap,
        backgroundColor: AppColors.surfaceVariantFor(brightness),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              HugeIcons.strokeRoundedFolder01,
              size: 32,
              color: AppColors.secondaryFor(brightness),
            ),
            const Spacer(),
            Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimaryFor(brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            countAsync.when(
              data: (int count) => Text(
                '$count ${count == 1 ? 'item' : 'items'}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
              loading: () => Text(
                'Counting…',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
              error: (_, __) => Text(
                'Items unavailable',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
