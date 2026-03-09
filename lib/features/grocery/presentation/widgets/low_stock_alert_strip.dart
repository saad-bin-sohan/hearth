import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';
import 'package:hugeicons/hugeicons.dart';

class LowStockAlertStrip extends ConsumerWidget {
  const LowStockAlertStrip({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final lowStockAsync = ref.watch(lowStockItemsProvider(householdId));
    return lowStockAsync.when(
      data: (List<PantryItemEntity> items) {
        return AnimatedSize(
          duration: AppAnimations.standard,
          curve: AppAnimations.easeInOut,
          child: items.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentContainerFor(brightness),
                    borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                    border: Border(
                      left: BorderSide(
                        color: AppColors.accentFor(brightness),
                        width: AppSpacing.xs,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const HearthSectionHeader(
                        title: 'Low Stock',
                        subtitle:
                            'Add pantry staples back to the list in one tap.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 132,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (BuildContext context, int index) {
                            final item = items[index];
                            return SizedBox(
                              width: 160,
                              child: HearthCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          HugeIcons.strokeRoundedAlert01,
                                          size: 18,
                                          color: AppColors.warningFor(
                                            brightness,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.titleMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      item.quantityDisplay,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondaryFor(
                                          brightness,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    HearthButton(
                                      label: 'Add to List',
                                      expanded: false,
                                      variant: HearthButtonVariant.ghost,
                                      onPressed: () async {
                                        try {
                                          await ref
                                              .read(
                                                groceryNotifierProvider
                                                    .notifier,
                                              )
                                              .addLowStockItemToList(item);
                                          if (!context.mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${item.name} added to list',
                                              ),
                                            ),
                                          );
                                        } on StateError {
                                          if (!context.mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not add item to list.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
