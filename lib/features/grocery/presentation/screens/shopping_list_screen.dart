import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_celebration.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';
import 'package:hearth/features/grocery/presentation/screens/list_templates_screen.dart';
import 'package:hearth/features/grocery/presentation/sheets/add_item_sheet.dart';
import 'package:hearth/features/grocery/presentation/sheets/add_to_pantry_sheet.dart';
import 'package:hearth/features/grocery/presentation/widgets/grocery_visuals.dart';
import 'package:hearth/features/grocery/presentation/widgets/section_header_tile.dart';
import 'package:hearth/features/grocery/presentation/widgets/shopping_item_tile.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:uuid/uuid.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  static const String routePath = '/grocery/list';

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final Uuid _uuid = const Uuid();
  bool _showCelebration = false;
  bool _completionSequenceActive = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final householdId = ref.watch(groceryHouseholdIdProvider);

    ref.listen<GroceryActionState>(groceryNotifierProvider, (previous, next) {
      final message = next.message;
      if (!mounted || message == null || message == previous?.message) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      ref.read(groceryNotifierProvider.notifier).clearMessage();
    });

    if (householdId != null) {
      ref.listen<bool>(allItemsCheckedProvider(householdId), (previous, next) {
        if (!mounted ||
            previous != false ||
            next != true ||
            _completionSequenceActive) {
          return;
        }
        _startCompletionSequence(householdId);
      });
    }

    if (householdId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Shopping List',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
        ),
        body: const Center(
          child: Text('Create or join a household to build a shopping list.'),
        ),
      );
    }

    final groupedItems = ref.watch(groupedShoppingItemsProvider(householdId));
    final uncheckedItems = ref.watch(
      uncheckedShoppingItemsProvider(householdId),
    );
    final checkedItems = ref.watch(checkedShoppingItemsProvider(householdId));
    final sortMode = ref.watch(shoppingSortModeProvider(householdId));
    final collapsedKeys = ref.watch(
      shoppingCollapsedSectionsProvider(householdId),
    );
    final activeInlineKey = ref.watch(inlineAddSectionProvider(householdId));
    final memberLookup =
        ref.watch(groceryMemberLookupProvider).valueOrNull ??
        const <String, HouseholdMember>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping List',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: sortMode == ShoppingSortMode.section
                ? 'Sort by date added'
                : 'Sort by section',
            onPressed: () {
              ref
                  .read(shoppingSortModeProvider(householdId).notifier)
                  .state = sortMode == ShoppingSortMode.section
                  ? ShoppingSortMode.dateAdded
                  : ShoppingSortMode.section;
            },
            icon: const Icon(HugeIcons.strokeRoundedSortByDown01),
          ),
          PopupMenuButton<_ShoppingMenuAction>(
            onSelected: (value) => _handleMenuAction(
              context: context,
              householdId: householdId,
              action: value,
            ),
            itemBuilder: (context) =>
                const <PopupMenuEntry<_ShoppingMenuAction>>[
                  PopupMenuItem<_ShoppingMenuAction>(
                    value: _ShoppingMenuAction.saveTemplate,
                    child: Text('Save as Template'),
                  ),
                  PopupMenuItem<_ShoppingMenuAction>(
                    value: _ShoppingMenuAction.clearChecked,
                    child: Text('Clear Checked'),
                  ),
                  PopupMenuItem<_ShoppingMenuAction>(
                    value: _ShoppingMenuAction.clearAll,
                    child: Text('Clear All'),
                  ),
                ],
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          if (uncheckedItems.isEmpty && checkedItems.isEmpty)
            Center(
              child: HearthEmptyState(
                icon: HugeIcons.strokeRoundedShoppingCart01,
                title: 'Your list is empty',
                body: 'Add items below, or load a saved template.',
                ctaLabel: 'Load Template',
                onCtaPressed: () => context.push(ListTemplatesScreen.routePath),
              ),
            )
          else
            ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                if (sortMode == ShoppingSortMode.section)
                  ...groupedItems.entries.map((entry) {
                    final section = entry.key;
                    final sectionKey = section.name;
                    final collapsed = collapsedKeys.contains(sectionKey);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ShoppingSection(
                        keyLabel: sectionKey,
                        householdId: householdId,
                        label: section.label,
                        icon: shoppingSectionIcon(section),
                        collapsed: collapsed,
                        count: entry.value.length,
                        inlineRowVisible: activeInlineKey == sectionKey,
                        onToggleCollapsed: () {
                          ref
                              .read(
                                shoppingCollapsedSectionsProvider(
                                  householdId,
                                ).notifier,
                              )
                              .toggle(sectionKey);
                        },
                        onOpenInlineRow: () {
                          ref
                                  .read(
                                    inlineAddSectionProvider(
                                      householdId,
                                    ).notifier,
                                  )
                                  .state =
                              sectionKey;
                        },
                        onCloseInlineRow: () {
                          ref
                                  .read(
                                    inlineAddSectionProvider(
                                      householdId,
                                    ).notifier,
                                  )
                                  .state =
                              null;
                        },
                        onAddItem: () =>
                            showAddItemSheet(context, initialSection: section),
                        children: List<Widget>.generate(entry.value.length, (
                          index,
                        ) {
                          final item = entry.value[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              top: index == 0 ? AppSpacing.sm : AppSpacing.xs,
                            ),
                            child: HearthListItemEntry(
                              index: index,
                              child: _ShoppingTileRow(
                                item: item,
                                householdId: householdId,
                                memberLookup: memberLookup,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                if (sortMode == ShoppingSortMode.dateAdded &&
                    uncheckedItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ShoppingSection(
                      keyLabel: 'recent',
                      householdId: householdId,
                      label: 'Recently Added',
                      icon: HugeIcons.strokeRoundedShoppingBag01,
                      collapsed: collapsedKeys.contains('recent'),
                      count: uncheckedItems.length,
                      inlineRowVisible: activeInlineKey == 'recent',
                      onToggleCollapsed: () {
                        ref
                            .read(
                              shoppingCollapsedSectionsProvider(
                                householdId,
                              ).notifier,
                            )
                            .toggle('recent');
                      },
                      onOpenInlineRow: () {
                        ref
                                .read(
                                  inlineAddSectionProvider(
                                    householdId,
                                  ).notifier,
                                )
                                .state =
                            'recent';
                      },
                      onCloseInlineRow: () {
                        ref
                                .read(
                                  inlineAddSectionProvider(
                                    householdId,
                                  ).notifier,
                                )
                                .state =
                            null;
                      },
                      onAddItem: () => showAddItemSheet(context),
                      addHint: 'Add another item...',
                      children: List<Widget>.generate(uncheckedItems.length, (
                        index,
                      ) {
                        final item = uncheckedItems[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? AppSpacing.sm : AppSpacing.xs,
                          ),
                          child: HearthListItemEntry(
                            index: index,
                            child: _ShoppingTileRow(
                              item: item,
                              householdId: householdId,
                              memberLookup: memberLookup,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                if (checkedItems.isNotEmpty)
                  _ShoppingSection(
                    keyLabel: 'checked',
                    householdId: householdId,
                    label: 'Checked',
                    icon: HugeIcons.strokeRoundedTickDouble02,
                    collapsed: collapsedKeys.contains('checked'),
                    count: checkedItems.length,
                    inlineRowVisible: false,
                    onToggleCollapsed: () {
                      ref
                          .read(
                            shoppingCollapsedSectionsProvider(
                              householdId,
                            ).notifier,
                          )
                          .toggle('checked');
                    },
                    onOpenInlineRow: () {},
                    onCloseInlineRow: () {},
                    onAddItem: () {},
                    addHint: '',
                    children: List<Widget>.generate(checkedItems.length, (
                      index,
                    ) {
                      final item = checkedItems[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? AppSpacing.sm : AppSpacing.xs,
                        ),
                        child: HearthListItemEntry(
                          index: index,
                          child: _ShoppingTileRow(
                            item: item,
                            householdId: householdId,
                            memberLookup: memberLookup,
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          if (_showCelebration)
            const Positioned.fill(child: HearthCelebration()),
        ],
      ),
    );
  }

  Future<void> _startCompletionSequence(String householdId) async {
    _completionSequenceActive = true;
    setState(() {
      _showCelebration = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) {
      return;
    }
    setState(() {
      _showCelebration = false;
    });
    final checkedItems = ref.read(checkedShoppingItemsProvider(householdId));
    if (checkedItems.isNotEmpty) {
      await showAddToPantrySheet(context, checkedItems: checkedItems);
    }
    _completionSequenceActive = false;
  }

  Future<void> _handleMenuAction({
    required BuildContext context,
    required String householdId,
    required _ShoppingMenuAction action,
  }) async {
    switch (action) {
      case _ShoppingMenuAction.saveTemplate:
        await _saveTemplate(context, householdId);
        return;
      case _ShoppingMenuAction.clearChecked:
        final confirmed = await _confirmDestructiveAction(
          context,
          title: 'Clear checked items?',
          body: 'This removes everything in the checked section.',
          confirmLabel: 'Clear Checked',
        );
        if (confirmed == true) {
          await ref.read(groceryNotifierProvider.notifier).clearCheckedItems();
        }
        return;
      case _ShoppingMenuAction.clearAll:
        final confirmed = await _confirmDestructiveAction(
          context,
          title: 'Clear the whole list?',
          body: 'This removes checked and unchecked items from this list.',
          confirmLabel: 'Clear All',
        );
        if (confirmed == true) {
          await ref.read(groceryNotifierProvider.notifier).clearAllItems();
        }
        return;
    }
  }

  Future<void> _saveTemplate(BuildContext context, String householdId) async {
    final items = ref.read(effectiveShoppingItemsProvider(householdId));
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items before saving a template.')),
      );
      return;
    }

    final controller = TextEditingController();
    final templateName = await showDialog<String>(
      context: context,
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return AlertDialog(
          title: Text('Save Template', style: AppTextStyles.headlineSmall),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Weekly Restock',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiaryFor(brightness),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || templateName == null || templateName.isEmpty) {
      return;
    }

    final currentUserId = ref.read(groceryCurrentUserIdProvider);
    final household = ref.read(groceryHouseholdIdProvider);
    if (currentUserId == null || household == null) {
      return;
    }
    final template = ListTemplateEntity(
      id: _uuid.v4(),
      householdId: household,
      name: templateName,
      items: items
          .map(
            (item) => TemplateItem(
              name: item.name,
              quantity: item.quantity,
              unit: item.unit,
              section: item.section,
              note: item.note,
            ),
          )
          .toList(),
      createdByUserId: currentUserId,
      createdAt: DateTime.now(),
    );
    await ref.read(groceryNotifierProvider.notifier).saveTemplate(template);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(content: Text('$templateName saved as a template.')),
    );
  }

  Future<bool?> _confirmDestructiveAction(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: AppTextStyles.headlineSmall),
          content: Text(body, style: AppTextStyles.bodyMedium),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }
}

enum _ShoppingMenuAction { saveTemplate, clearChecked, clearAll }

class _ShoppingSection extends StatelessWidget {
  const _ShoppingSection({
    required this.keyLabel,
    required this.householdId,
    required this.label,
    required this.icon,
    required this.collapsed,
    required this.count,
    required this.inlineRowVisible,
    required this.onToggleCollapsed,
    required this.onOpenInlineRow,
    required this.onCloseInlineRow,
    required this.onAddItem,
    required this.children,
    this.addHint,
  });

  final String keyLabel;
  final String householdId;
  final String label;
  final IconData icon;
  final bool collapsed;
  final int count;
  final bool inlineRowVisible;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onOpenInlineRow;
  final VoidCallback onCloseInlineRow;
  final VoidCallback onAddItem;
  final List<Widget> children;
  final String? addHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeaderTile(
          label: keyLabel == 'checked' ? 'Checked ($count)' : label,
          count: count,
          collapsed: collapsed,
          onTap: onToggleCollapsed,
          icon: icon,
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSize(
          duration: AppAnimations.standard,
          curve: AppAnimations.easeInOut,
          child: collapsed
              ? const SizedBox.shrink()
              : Column(
                  children: <Widget>[
                    ...children,
                    if (keyLabel != 'checked')
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: _InlineAddRow(
                          visible: inlineRowVisible,
                          label: addHint ?? 'Add to $label...',
                          onOpen: onOpenInlineRow,
                          onClose: onCloseInlineRow,
                          onAddItem: onAddItem,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ShoppingTileRow extends ConsumerWidget {
  const _ShoppingTileRow({
    required this.item,
    required this.householdId,
    required this.memberLookup,
  });

  final ShoppingItemEntity item;
  final String householdId;
  final Map<String, HouseholdMember> memberLookup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final assignedDisplayName = item.assignedToUserId == null
        ? null
        : memberLookup[item.assignedToUserId!]?.displayName;
    return HearthSwipeToAction(
      leadingAction: HearthSwipeAction(
        icon: HugeIcons.strokeRoundedDelete02,
        label: 'Delete',
        color: AppColors.errorFor(brightness),
        onTriggered: () async {
          await ref
              .read(groceryNotifierProvider.notifier)
              .deleteShoppingItem(item.id);
        },
      ),
      trailingAction: HearthSwipeAction(
        icon: HugeIcons.strokeRoundedEdit02,
        label: 'Edit',
        color: AppColors.warningFor(brightness),
        onTriggered: () {
          showAddItemSheet(context, initialItem: item);
        },
      ),
      child: ShoppingItemTile(
        item: item,
        assignedDisplayName: assignedDisplayName,
        highlightPulse: ref.watch(
          shoppingPulseIdsProvider.select((ids) => ids.contains(item.id)),
        ),
        onToggleChecked: () async {
          try {
            if (item.isChecked) {
              await ref
                  .read(groceryNotifierProvider.notifier)
                  .uncheckItem(item.id);
            } else {
              await ref
                  .read(groceryNotifierProvider.notifier)
                  .checkOffItem(item.id);
            }
          } on StateError {
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not update shopping item.')),
            );
          }
        },
      ),
    );
  }
}

class _InlineAddRow extends StatelessWidget {
  const _InlineAddRow({
    required this.visible,
    required this.label,
    required this.onOpen,
    required this.onClose,
    required this.onAddItem,
  });

  final bool visible;
  final String label;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AnimatedSwitcher(
      duration: AppAnimations.standard,
      switchInCurve: AppAnimations.easeInOut,
      switchOutCurve: AppAnimations.easeInOut,
      child: visible
          ? InkWell(
              key: const ValueKey<String>('inline-add-open'),
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
              onTap: onAddItem,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantFor(brightness),
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      HugeIcons.strokeRoundedAdd01,
                      color: AppColors.primaryFor(brightness),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryFor(brightness),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(HugeIcons.strokeRoundedCancel01),
                    ),
                  ],
                ),
              ),
            )
          : InkWell(
              key: const ValueKey<String>('inline-add-closed'),
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      HugeIcons.strokeRoundedAdd01,
                      color: AppColors.primaryFor(brightness),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
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
