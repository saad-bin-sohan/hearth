import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/presentation/widgets/maintenance_visuals.dart';
import 'package:hearth/features/maintenance/presentation/widgets/star_rating_widget.dart';

class VendorCard extends StatelessWidget {
  const VendorCard({required this.vendor, required this.onTap, super.key});

  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return HearthCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(
            iconForVendorCategory(vendor.category),
            size: 28,
            color: AppColors.secondaryFor(brightness),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  vendor.businessName,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  vendor.contactName == null
                      ? vendor.category.label
                      : '${vendor.category.label} · ${vendor.contactName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              StarRatingWidget(rating: vendor.averageRating, size: 16),
              const SizedBox(height: AppSpacing.xs),
              Text(
                vendor.averageRating.toStringAsFixed(1),
                style: AppTextStyles.numericSmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
