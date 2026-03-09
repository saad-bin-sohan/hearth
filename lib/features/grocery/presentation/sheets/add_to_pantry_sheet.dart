import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';
import 'package:hearth/features/grocery/presentation/widgets/grocery_visuals.dart';

enum _AddToPantryStep { select, details }

Future<void> showAddToPantrySheet(
  BuildContext context, {
  required List<ShoppingItemEntity> checkedItems,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return AddToPantrySheet(checkedItems: checkedItems);
    },
  );
}

class AddToPantrySheet extends ConsumerStatefulWidget {
  const AddToPantrySheet({required this.checkedItems, super.key});

  final List<ShoppingItemEntity> checkedItems;

  @override
  ConsumerState<AddToPantrySheet> createState() => _AddToPantrySheetState();
}

class _AddToPantrySheetState extends ConsumerState<AddToPantrySheet> {
  _AddToPantryStep _step = _AddToPantryStep.select;
  late Set<String> _selectedIds;
  late Map<String, ({PantryLocation location, DateTime? expiry})> _details;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.checkedItems
        .map((ShoppingItemEntity item) => item.id)
        .toSet();
    _details = <String, ({PantryLocation location, DateTime? expiry})>{
      for (final item in widget.checkedItems)
        item.id: (
          location: defaultPantryLocationForSection(item.section),
          expiry: suggestedExpiryForSection(item.section),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final actionState = ref.watch(groceryNotifierProvider);
    final selectedItems = widget.checkedItems
        .where((ShoppingItemEntity item) => _selectedIds.contains(item.id))
        .toList();
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(brightness),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.radiusLg),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Shopping Complete! 🛍️',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Add purchased items to your pantry?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_step == _AddToPantryStep.select)
                  _SelectionStep(
                    items: widget.checkedItems,
                    selectedIds: _selectedIds,
                    onToggle: (String id) {
                      setState(() {
                        if (_selectedIds.contains(id)) {
                          _selectedIds.remove(id);
                        } else {
                          _selectedIds.add(id);
                        }
                      });
                    },
                    onToggleAll: () {
                      setState(() {
                        if (_selectedIds.length == widget.checkedItems.length) {
                          _selectedIds = <String>{};
                        } else {
                          _selectedIds = widget.checkedItems
                              .map((ShoppingItemEntity item) => item.id)
                              .toSet();
                        }
                      });
                    },
                  )
                else
                  _DetailsStep(
                    items: selectedItems,
                    details: _details,
                    onLocationChanged:
                        (String itemId, PantryLocation location) {
                          setState(() {
                            _details[itemId] = (
                              location: location,
                              expiry: _details[itemId]?.expiry,
                            );
                          });
                        },
                    onExpiryChanged: (String itemId, DateTime? expiry) {
                      setState(() {
                        _details[itemId] = (
                          location:
                              _details[itemId]?.location ??
                              PantryLocation.pantry,
                          expiry: expiry,
                        );
                      });
                    },
                  ),
                if (actionState.message != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    actionState.message!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.errorFor(brightness),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (_step == _AddToPantryStep.select)
                  HearthButton(
                    label: 'Continue →',
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _step = _AddToPantryStep.details;
                            });
                          },
                  )
                else
                  HearthButton(
                    label: 'Add ${selectedItems.length} Items to Pantry',
                    isLoading: actionState.isLoading,
                    onPressed: selectedItems.isEmpty
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(groceryNotifierProvider.notifier)
                                  .batchAddToPantry(
                                    items: selectedItems,
                                    details: _details,
                                  );
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${selectedItems.length} items added to your pantry.',
                                  ),
                                ),
                              );
                            } on StateError {
                              return;
                            }
                          },
                  ),
                const SizedBox(height: AppSpacing.sm),
                HearthButton(
                  label: _step == _AddToPantryStep.select
                      ? 'Skip for Now'
                      : 'Back',
                  variant: HearthButtonVariant.ghost,
                  onPressed: () {
                    if (_step == _AddToPantryStep.select) {
                      Navigator.of(context).pop();
                      return;
                    }
                    setState(() {
                      _step = _AddToPantryStep.select;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionStep extends StatelessWidget {
  const _SelectionStep({
    required this.items,
    required this.selectedIds,
    required this.onToggle,
    required this.onToggleAll,
  });

  final List<ShoppingItemEntity> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final allSelected = selectedIds.length == items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Step 1 · Select items', style: AppTextStyles.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: onToggleAll,
              child: Text(allSelected ? 'Deselect All' : 'Select All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((ShoppingItemEntity item) {
          final selected = selectedIds.contains(item.id);
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selected,
            onChanged: (_) => onToggle(item.id),
            title: Text(item.name, style: AppTextStyles.titleMedium),
            subtitle: Text(
              item.quantityDisplay,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.items,
    required this.details,
    required this.onLocationChanged,
    required this.onExpiryChanged,
  });

  final List<ShoppingItemEntity> items;
  final Map<String, ({PantryLocation location, DateTime? expiry})> details;
  final void Function(String itemId, PantryLocation location) onLocationChanged;
  final void Function(String itemId, DateTime? expiry) onExpiryChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Step 2 · Pantry details', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((ShoppingItemEntity item) {
          final detail = details[item.id]!;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantFor(brightness),
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.quantityDisplay,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: PantryLocation.values
                        .where(
                          (PantryLocation location) =>
                              location != PantryLocation.other,
                        )
                        .length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) {
                      final location = PantryLocation.values
                          .where(
                            (PantryLocation value) =>
                                value != PantryLocation.other,
                          )
                          .toList()[index];
                      return HearthChip(
                        label: location.label,
                        icon: pantryLocationIcon(location),
                        selected: detail.location == location,
                        onTap: () => onLocationChanged(item.id, location),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        detail.expiry == null
                            ? 'No expiry date'
                            : 'Expiry ${detail.expiry!.day}/${detail.expiry!.month}/${detail.expiry!.year}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    HearthButton(
                      label: detail.expiry == null ? 'Set Date' : 'Change',
                      expanded: false,
                      variant: HearthButtonVariant.ghost,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime(2100),
                          initialDate: detail.expiry ?? DateTime.now(),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        onExpiryChanged(item.id, picked);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
