import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/expiry_status.dart';
import 'package:hearth/core/widgets/expiry_badge.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/maintenance/domain/entities/asset.dart';
import 'package:hearth/features/maintenance/presentation/widgets/maintenance_visuals.dart';

enum AssetCardVariant { grid, list }

class AssetCard extends StatelessWidget {
  const AssetCard({
    required this.asset,
    required this.onTap,
    this.nextTaskLabel,
    this.variant = AssetCardVariant.grid,
    super.key,
  });

  final Asset asset;
  final VoidCallback onTap;
  final String? nextTaskLabel;
  final AssetCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final badgeUrgency = switch (asset.warrantyUrgency) {
      DateExpiryUrgency.none => ExpiryBadgeUrgency.none,
      DateExpiryUrgency.safe => ExpiryBadgeUrgency.safe,
      DateExpiryUrgency.warning => ExpiryBadgeUrgency.warning,
      DateExpiryUrgency.critical => ExpiryBadgeUrgency.critical,
      DateExpiryUrgency.expired => ExpiryBadgeUrgency.expired,
    };

    final leading = asset.photoLocalPath != null &&
            File(asset.photoLocalPath!).existsSync()
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            child: Image.file(
              File(asset.photoLocalPath!),
              width: variant == AssetCardVariant.list ? 48 : double.infinity,
              height: variant == AssetCardVariant.list ? 48 : 96,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            width: variant == AssetCardVariant.list ? 48 : double.infinity,
            height: variant == AssetCardVariant.list ? 48 : 96,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantFor(brightness),
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            ),
            alignment: Alignment.center,
            child: Icon(
              iconForAssetCategory(asset.category),
              size: variant == AssetCardVariant.list ? 24 : 32,
              color: AppColors.secondaryFor(brightness),
            ),
          );

    if (variant == AssetCardVariant.list) {
      return HearthCard(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimaryFor(brightness),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    asset.brand ?? asset.category.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
            ),
            if (badgeUrgency != ExpiryBadgeUrgency.none)
              ExpiryBadge(
                urgency: badgeUrgency,
                daysUntil: asset.daysUntilWarranty,
                pulse: badgeUrgency == ExpiryBadgeUrgency.critical,
                size: ExpiryBadgeSize.compact,
              ),
          ],
        ),
      );
    }

    return HearthCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              leading,
              if (badgeUrgency != ExpiryBadgeUrgency.none)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: ExpiryBadge(
                    urgency: badgeUrgency,
                    daysUntil: asset.daysUntilWarranty,
                    pulse: badgeUrgency == ExpiryBadgeUrgency.critical,
                    size: ExpiryBadgeSize.compact,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      iconForAssetCategory(asset.category),
                      size: 18,
                      color: AppColors.textTertiaryFor(brightness),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        asset.brand ?? asset.category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiaryFor(brightness),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
                if (nextTaskLabel != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    nextTaskLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accentFor(brightness),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
