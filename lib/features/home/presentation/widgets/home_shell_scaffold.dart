import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/animated/hearth_fab_entry.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/features/chores/presentation/chore_notifier.dart';
import 'package:hearth/features/chores/presentation/widgets/add_edit_chore_sheet.dart';
import 'package:hearth/features/documents/presentation/document_notifier.dart';
import 'package:hearth/features/documents/presentation/sheets/add_document_sheet.dart';
import 'package:hearth/features/finance/presentation/finance_notifier.dart';
import 'package:hearth/features/finance/presentation/widgets/add_expense_sheet.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';
import 'package:hearth/features/grocery/presentation/sheets/add_item_sheet.dart';
import 'package:hearth/features/home/presentation/widgets/more_modules_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeShellScaffold extends ConsumerWidget {
  const HomeShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<({String label, IconData icon})> _items =
      <({String label, IconData icon})>[
        (label: 'Home', icon: HugeIcons.strokeRoundedHome03),
        (label: 'Finance', icon: HugeIcons.strokeRoundedComputerDollar),
        (label: 'Chores', icon: HugeIcons.strokeRoundedCheckList),
        (label: 'Documents', icon: HugeIcons.strokeRoundedFolderFileStorage),
        (label: 'Grocery', icon: HugeIcons.strokeRoundedShoppingCart01),
        (label: 'Household', icon: HugeIcons.strokeRoundedHouse03),
        (label: 'More', icon: HugeIcons.strokeRoundedMoreHorizontal),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(financeBootstrapProvider);
    ref.watch(choresBootstrapProvider);
    ref.watch(documentBootstrapProvider);
    ref.watch(groceryBootstrapProvider);
    final brightness = Theme.of(context).brightness;
    final showFab =
        navigationShell.currentIndex == 0 ||
        navigationShell.currentIndex == 1 ||
        navigationShell.currentIndex == 2 ||
        navigationShell.currentIndex == 3 ||
        navigationShell.currentIndex == 4;
    return Scaffold(
      body: navigationShell,
      floatingActionButton: showFab
          ? HearthFABEntry(
              child: FloatingActionButton.extended(
                onPressed: () {
                  if (navigationShell.currentIndex == 2) {
                    showAddEditChoreSheet(context);
                    return;
                  }
                  if (navigationShell.currentIndex == 3) {
                    showAddDocumentSheet(context);
                    return;
                  }
                  if (navigationShell.currentIndex == 4) {
                    showAddItemSheet(context);
                    return;
                  }
                  showAddExpenseSheet(context);
                },
                icon: const Icon(HugeIcons.strokeRoundedAddCircle),
                label: Text(switch (navigationShell.currentIndex) {
                  1 => 'Add Expense',
                  2 => 'Add Chore',
                  3 => 'Add Document',
                  4 => 'Add Item',
                  _ => 'Quick Add',
                }),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(brightness),
          boxShadow: AppElevation.elevationLow,
        ),
        child: Row(
          children: List<Widget>.generate(_items.length, (int index) {
            final item = _items[index];
            final active = index == navigationShell.currentIndex;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                onTap: () {
                  if (index == _items.length - 1) {
                    showHearthBottomSheet<void>(
                      context: context,
                      builder: (context) => const MoreModulesSheet(),
                    );
                    return;
                  }
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  curve: AppAnimations.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: AppAnimations.standard,
                        curve: AppAnimations.easeInOut,
                        width: active ? 28 : 12,
                        height: 3,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primaryFor(brightness)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusFull,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnimatedScale(
                        duration: AppAnimations.fast,
                        scale: active ? 1.1 : 1,
                        child: Icon(
                          item.icon,
                          color: active
                              ? AppColors.primaryFor(brightness)
                              : AppColors.textTertiaryFor(brightness),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: active
                              ? AppColors.primaryFor(brightness)
                              : AppColors.textTertiaryFor(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
