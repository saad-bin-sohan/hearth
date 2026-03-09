import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';
import 'package:hearth/features/grocery/presentation/widgets/grocery_visuals.dart';
import 'package:hearth/features/grocery/presentation/widgets/pantry_item_tile.dart';
import 'package:hearth/features/grocery/presentation/widgets/section_header_tile.dart';
import 'package:hugeicons/hugeicons.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({this.initialLocation, super.key});

  static const String routePath = '/grocery/pantry';

  final PantryLocation? initialLocation;

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;
  bool _seededInitialFilter = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final householdId = ref.watch(groceryHouseholdIdProvider);
    if (householdId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Pantry',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
        ),
        body: const Center(
          child: Text('Create or join a household to track pantry inventory.'),
        ),
      );
    }

    if (!_seededInitialFilter && widget.initialLocation != null) {
      _seededInitialFilter = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pantryLocationFilterProvider(householdId).notifier).state =
            widget.initialLocation;
      });
    }

    final groupedItems = ref.watch(groupedPantryItemsProvider(householdId));
    final allItems =
        ref.watch(pantryItemsProvider(householdId)).valueOrNull ??
        const <PantryItemEntity>[];
    final collapsedKeys = ref.watch(
      pantryCollapsedSectionsProvider(householdId),
    );
    final locationFilter = ref.watch(pantryLocationFilterProvider(householdId));
    final categoryFilter = ref.watch(pantryCategoryFilterProvider(householdId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pantry',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchController.clear();
                  ref
                          .read(pantrySearchQueryProvider(householdId).notifier)
                          .state =
                      '';
                }
              });
            },
            icon: Icon(
              _searchVisible
                  ? HugeIcons.strokeRoundedCancel01
                  : HugeIcons.strokeRoundedSearch01,
            ),
          ),
          IconButton(
            tooltip: 'Filters',
            onPressed: () => _showFilters(context, householdId),
            icon: const Icon(HugeIcons.strokeRoundedFilterHorizontal),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          AnimatedSize(
            duration: AppAnimations.standard,
            curve: AppAnimations.easeInOut,
            child: _searchVisible
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: HearthTextField(
                      label: 'Search pantry',
                      controller: _searchController,
                      prefix: const Icon(HugeIcons.strokeRoundedSearch01),
                      onSubmitted: (value) {
                        ref
                            .read(
                              pantrySearchQueryProvider(householdId).notifier,
                            )
                            .state = value
                            .trim();
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (locationFilter != null || categoryFilter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  if (locationFilter != null)
                    HearthChip(
                      label: locationFilter.label,
                      selected: true,
                      icon: pantryLocationIcon(locationFilter),
                      onTap: () {
                        ref
                                .read(
                                  pantryLocationFilterProvider(
                                    householdId,
                                  ).notifier,
                                )
                                .state =
                            null;
                      },
                    ),
                  if (categoryFilter != null)
                    HearthChip(
                      label: categoryFilter.label,
                      selected: true,
                      icon: pantryCategoryIcon(categoryFilter),
                      onTap: () {
                        ref
                                .read(
                                  pantryCategoryFilterProvider(
                                    householdId,
                                  ).notifier,
                                )
                                .state =
                            null;
                      },
                    ),
                ],
              ),
            ),
          if (allItems.isEmpty)
            const SizedBox(
              height: 300,
              child: HearthEmptyState(
                icon: HugeIcons.strokeRoundedFridge,
                title: 'Your pantry is empty',
                body:
                    "After completing a shopping list, you'll be prompted to add purchased items here.",
              ),
            )
          else if (groupedItems.isEmpty)
            const SizedBox(
              height: 220,
              child: HearthEmptyState(
                icon: HugeIcons.strokeRoundedSearch01,
                title: 'No pantry matches',
                body: 'Try a different location, category, or search term.',
              ),
            )
          else
            ...groupedItems.entries.map((entry) {
              final location = entry.key;
              final keyLabel = location.name;
              final collapsed = collapsedKeys.contains(keyLabel);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  children: <Widget>[
                    SectionHeaderTile(
                      label: location.label,
                      count: entry.value.length,
                      collapsed: collapsed,
                      onTap: () {
                        ref
                            .read(
                              pantryCollapsedSectionsProvider(
                                householdId,
                              ).notifier,
                            )
                            .toggle(keyLabel);
                      },
                      icon: pantryLocationIcon(location),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedSize(
                      duration: AppAnimations.standard,
                      curve: AppAnimations.easeInOut,
                      child: collapsed
                          ? const SizedBox.shrink()
                          : Column(
                              children: List<Widget>.generate(entry.value.length, (
                                index,
                              ) {
                                final item = entry.value[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    top: index == 0
                                        ? AppSpacing.sm
                                        : AppSpacing.xs,
                                  ),
                                  child: HearthListItemEntry(
                                    index: index,
                                    child: HearthSwipeToAction(
                                      leadingAction: HearthSwipeAction(
                                        icon: HugeIcons.strokeRoundedDelete02,
                                        label: 'Delete',
                                        color: AppColors.errorFor(brightness),
                                        onTriggered: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                  'Delete ${item.name}?',
                                                  style: AppTextStyles
                                                      .headlineSmall,
                                                ),
                                                content: const Text(
                                                  'This removes the pantry item permanently.',
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (confirmed == true) {
                                            await ref
                                                .read(
                                                  groceryNotifierProvider
                                                      .notifier,
                                                )
                                                .deletePantryItem(item.id);
                                          }
                                        },
                                      ),
                                      trailingAction: HearthSwipeAction(
                                        icon: HugeIcons.strokeRoundedMinusSign,
                                        label: 'Use 1',
                                        color: AppColors.warningFor(brightness),
                                        onTriggered: () async {
                                          await ref
                                              .read(
                                                groceryNotifierProvider
                                                    .notifier,
                                              )
                                              .decrementPantryQuantity(
                                                item.id,
                                                1,
                                              );
                                        },
                                      ),
                                      child: PantryItemTile(item: item),
                                    ),
                                  ),
                                );
                              }),
                            ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showFilters(BuildContext context, String householdId) {
    PantryLocation? selectedLocation = ref.read(
      pantryLocationFilterProvider(householdId),
    );
    PantryCategory? selectedCategory = ref.read(
      pantryCategoryFilterProvider(householdId),
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(brightness),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.radiusLg),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Filters', style: AppTextStyles.headlineSmall),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Location', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
                          for (final location in PantryLocation.values)
                            HearthChip(
                              label: location.label,
                              selected: selectedLocation == location,
                              icon: pantryLocationIcon(location),
                              onTap: () {
                                setModalState(() {
                                  selectedLocation =
                                      selectedLocation == location
                                      ? null
                                      : location;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Category', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
                          for (final category in PantryCategory.values)
                            HearthChip(
                              label: category.label,
                              selected: selectedCategory == category,
                              icon: pantryCategoryIcon(category),
                              onTap: () {
                                setModalState(() {
                                  selectedCategory =
                                      selectedCategory == category
                                      ? null
                                      : category;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                ref
                                        .read(
                                          pantryLocationFilterProvider(
                                            householdId,
                                          ).notifier,
                                        )
                                        .state =
                                    null;
                                ref
                                        .read(
                                          pantryCategoryFilterProvider(
                                            householdId,
                                          ).notifier,
                                        )
                                        .state =
                                    null;
                                Navigator.of(context).pop();
                              },
                              child: const Text('Clear'),
                            ),
                          ),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                ref
                                        .read(
                                          pantryLocationFilterProvider(
                                            householdId,
                                          ).notifier,
                                        )
                                        .state =
                                    selectedLocation;
                                ref
                                        .read(
                                          pantryCategoryFilterProvider(
                                            householdId,
                                          ).notifier,
                                        )
                                        .state =
                                    selectedCategory;
                                Navigator.of(context).pop();
                              },
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
