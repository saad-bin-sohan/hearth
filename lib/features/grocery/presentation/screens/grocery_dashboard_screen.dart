import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/hearth_badge.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';
import 'package:hearth/features/grocery/presentation/screens/list_templates_screen.dart';
import 'package:hearth/features/grocery/presentation/screens/pantry_screen.dart';
import 'package:hearth/features/grocery/presentation/screens/shopping_list_screen.dart';
import 'package:hearth/features/grocery/presentation/widgets/grocery_visuals.dart';
import 'package:hearth/features/grocery/presentation/widgets/low_stock_alert_strip.dart';
import 'package:hearth/features/grocery/presentation/widgets/member_presence_indicator.dart';
import 'package:hearth/features/grocery/presentation/widgets/shopping_item_tile.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hugeicons/hugeicons.dart';

class GroceryDashboardScreen extends ConsumerWidget {
  const GroceryDashboardScreen({super.key});

  static const String routePath = '/grocery';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final householdId = ref.watch(groceryHouseholdIdProvider);
    if (householdId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Grocery',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Text('Create or join a household to start shopping together.'),
        ),
      );
    }

    final previewItems = ref.watch(shoppingPreviewItemsProvider(householdId));
    final locationSummary = ref.watch(
      pantryLocationSummaryProvider(householdId),
    );
    final memberLookup =
        ref.watch(groceryMemberLookupProvider).valueOrNull ??
        const <String, HouseholdMember>{};
    final uncheckedCount = ref.watch(
      shoppingItemsProvider(householdId).select(
        (value) =>
            value.valueOrNull?.where((item) => !item.isChecked).length ?? 0,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grocery',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            tooltip: 'Templates',
            onPressed: () => context.push(ListTemplatesScreen.routePath),
            icon: const Icon(HugeIcons.strokeRoundedFile02),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          LowStockAlertStrip(householdId: householdId),
          const MemberPresenceIndicator(),
          if (previewItems.isNotEmpty) const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: HearthSectionHeader(
                  title: 'Shopping List',
                  subtitle: 'The next few things still waiting in the cart.',
                  actionLabel: 'See All',
                  onActionPressed: () =>
                      context.push(ShoppingListScreen.routePath),
                ),
              ),
              HearthBadge(
                count: uncheckedCount,
                backgroundColor: AppColors.primaryContainerFor(brightness),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (previewItems.isEmpty)
            const SizedBox(
              height: 280,
              child: HearthEmptyState(
                icon: HugeIcons.strokeRoundedShoppingCart01,
                title: 'List is empty',
                body: 'Add items or load a template.',
              ),
            )
          else
            Column(
              children: List<Widget>.generate(previewItems.length, (int index) {
                final item = previewItems[index];
                final assignedName = item.assignedToUserId == null
                    ? null
                    : memberLookup[item.assignedToUserId!]?.displayName;
                return HearthListItemEntry(
                  index: index,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index == previewItems.length - 1
                          ? 0
                          : AppSpacing.sm,
                    ),
                    child: ShoppingItemTile(
                      item: item,
                      variant: ShoppingItemTileVariant.compact,
                      assignedDisplayName: assignedName,
                      highlightPulse: ref.watch(
                        shoppingPulseIdsProvider.select(
                          (ids) => ids.contains(item.id),
                        ),
                      ),
                      onToggleChecked: () async {
                        try {
                          await ref
                              .read(groceryNotifierProvider.notifier)
                              .checkOffItem(item.id);
                        } on StateError {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not update shopping item.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }),
            ),
          const SizedBox(height: AppSpacing.xl),
          HearthSectionHeader(
            title: 'Pantry',
            subtitle:
                'Quick counts across the places you usually stash things.',
            actionLabel: 'View All',
            onActionPressed: () => context.push(PantryScreen.routePath),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (locationSummary.isEmpty)
            const SizedBox(
              height: 280,
              child: HearthEmptyState(
                icon: HugeIcons.strokeRoundedFridge,
                title: 'Your pantry is empty',
                body:
                    'Finish a shopping run and bring what you bought back here.',
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: <Widget>[
                for (final location in <PantryLocation>[
                  PantryLocation.fridge,
                  PantryLocation.freezer,
                  PantryLocation.pantry,
                  PantryLocation.cabinet,
                ])
                  if (locationSummary.containsKey(location))
                    SizedBox(
                      width:
                          (MediaQuery.of(context).size.width -
                              (AppSpacing.md * 3)) /
                          2,
                      child: HearthListItemEntry(
                        index: location.index,
                        child: _PantryLocationCard(
                          location: location,
                          totalCount: locationSummary[location]!.totalCount,
                          warningCount: locationSummary[location]!.warningCount,
                          onTap: () => context.push(
                            '${PantryScreen.routePath}?location=${location.name}',
                          ),
                        ),
                      ),
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PantryLocationCard extends StatelessWidget {
  const _PantryLocationCard({
    required this.location,
    required this.totalCount,
    required this.warningCount,
    required this.onTap,
  });

  final PantryLocation location;
  final int totalCount;
  final int warningCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return HearthCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            pantryLocationIcon(location),
            color: AppColors.secondaryFor(brightness),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(location.label, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$totalCount items',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryFor(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            warningCount > 0 ? '$warningCount expiry warnings' : 'All clear',
            style: AppTextStyles.labelMedium.copyWith(
              color: warningCount > 0
                  ? AppColors.warningFor(brightness)
                  : AppColors.successFor(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
