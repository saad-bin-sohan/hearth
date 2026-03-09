import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/animated/hearth_fab_entry.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/features/home/presentation/widgets/more_modules_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeShellScaffold extends StatelessWidget {
  const HomeShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<({String label, IconData icon})> _items =
      <({String label, IconData icon})>[
        (label: 'Home', icon: HugeIcons.strokeRoundedHome03),
        (label: 'Household', icon: HugeIcons.strokeRoundedHouse03),
        (label: 'Members', icon: HugeIcons.strokeRoundedUserGroup),
        (label: 'Settings', icon: HugeIcons.strokeRoundedSettings02),
        (label: 'More', icon: HugeIcons.strokeRoundedMoreHorizontal),
      ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      body: navigationShell,
      floatingActionButton: navigationShell.currentIndex == 0
          ? HearthFABEntry(
              child: FloatingActionButton.extended(
                onPressed: () {
                  showHearthBottomSheet<void>(
                    context: context,
                    builder: (context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Quick Add', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Phase 1 keeps Quick Add as a polished placeholder. Finance, chores, documents, and more wire into this sheet in later phases.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          HearthButton(
                            label: 'Close',
                            variant: HearthButtonVariant.ghost,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(HugeIcons.strokeRoundedAddCircle),
                label: const Text('Quick Add'),
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
                  if (index == 4) {
                    showHearthBottomSheet<void>(
                      context: context,
                      builder: (context) => const MoreModulesSheet(),
                    );
                    return;
                  }
                  navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
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
                          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
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
