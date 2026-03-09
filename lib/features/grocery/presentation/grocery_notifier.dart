import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/core/services/notification_service.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/features/grocery/data/local_grocery_repository.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/domain/grocery_repository.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:uuid/uuid.dart';

class GroceryActionState {
  const GroceryActionState({this.isLoading = false, this.message});

  final bool isLoading;
  final String? message;

  GroceryActionState copyWith({
    bool? isLoading,
    String? message,
    bool clearMessage = false,
  }) {
    return GroceryActionState(
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class _ShoppingOptimisticController extends StateNotifier<Map<String, bool>> {
  _ShoppingOptimisticController() : super(const <String, bool>{});

  void setChecked(String itemId, bool value) {
    state = <String, bool>{...state, itemId: value};
  }

  void clear(String itemId) {
    if (!state.containsKey(itemId)) {
      return;
    }
    final updated = <String, bool>{...state}..remove(itemId);
    state = updated;
  }

  void clearAll() {
    state = const <String, bool>{};
  }
}

class _ShoppingPulseController extends StateNotifier<Set<String>> {
  _ShoppingPulseController() : super(const <String>{});

  Future<void> pulse(String itemId) async {
    state = <String>{...state, itemId};
    await Future<void>.delayed(AppAnimations.slow);
    if (!mounted) {
      return;
    }
    state = <String>{...state}..remove(itemId);
  }
}

class MemberPresenceController extends StateNotifier<Map<String, DateTime>> {
  MemberPresenceController() : super(const <String, DateTime>{});

  void recordActivity(String userId) {
    state = <String, DateTime>{...state, userId: DateTime.now()};
  }
}

class _CollapsedSectionsController extends StateNotifier<Set<String>> {
  _CollapsedSectionsController() : super(const <String>{'checked'});

  void toggle(String key) {
    final updated = <String>{...state};
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    state = updated;
  }

  void setCollapsed(String key, bool value) {
    final updated = <String>{...state};
    if (value) {
      updated.add(key);
    } else {
      updated.remove(key);
    }
    state = updated;
  }
}

class GroceryNotifier extends StateNotifier<GroceryActionState> {
  GroceryNotifier(this.ref)
    : _uuid = const Uuid(),
      super(const GroceryActionState());

  final Ref ref;
  final Uuid _uuid;

  GroceryRepository get _repository => ref.read(groceryRepositoryProvider);

  String get _householdId {
    final householdId = ref.read(groceryHouseholdIdProvider);
    if (householdId == null) {
      throw StateError('Household context is missing.');
    }
    return householdId;
  }

  String get _userId {
    final userId = ref.read(groceryCurrentUserIdProvider);
    if (userId == null) {
      throw StateError('You must be signed in to use Grocery.');
    }
    return userId;
  }

  Future<void> saveShoppingItem(
    ShoppingItemEntity item, {
    bool pulsePreview = false,
  }) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final isEdit = ref.read(_shoppingItemExistsProvider(item.id));
      if (isEdit) {
        await _repository.updateItem(item);
      } else {
        await _repository.addItem(item);
      }
      ref.read(memberPresenceProvider.notifier).recordActivity(_userId);
      if (pulsePreview) {
        unawaited(ref.read(shoppingPulseIdsProvider.notifier).pulse(item.id));
      }
      _invalidateData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> checkOffItem(String itemId) async {
    final optimistic = ref.read(
      shoppingOptimisticProvider(_householdId).notifier,
    );
    optimistic.setChecked(itemId, true);
    ref.read(memberPresenceProvider.notifier).recordActivity(_userId);
    try {
      await _repository.checkOffItem(itemId, _userId);
      await Future<void>.delayed(AppAnimations.fast);
      optimistic.clear(itemId);
      _invalidateData();
    } on StateError catch (error) {
      optimistic.clear(itemId);
      state = state.copyWith(message: error.message);
      rethrow;
    }
  }

  Future<void> uncheckItem(String itemId) async {
    final optimistic = ref.read(
      shoppingOptimisticProvider(_householdId).notifier,
    );
    optimistic.setChecked(itemId, false);
    try {
      await _repository.uncheckItem(itemId);
      await Future<void>.delayed(AppAnimations.fast);
      optimistic.clear(itemId);
      _invalidateData();
    } on StateError catch (error) {
      optimistic.clear(itemId);
      state = state.copyWith(message: error.message);
      rethrow;
    }
  }

  Future<void> deleteShoppingItem(String id) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _repository.deleteItem(id);
      _invalidateData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> clearCheckedItems() async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _repository.clearCheckedItems(_householdId);
      ref.read(shoppingOptimisticProvider(_householdId).notifier).clearAll();
      _invalidateData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> clearAllItems() async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _repository.clearAllItems(_householdId);
      ref.read(shoppingOptimisticProvider(_householdId).notifier).clearAll();
      _invalidateData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> addLowStockItemToList(PantryItemEntity pantryItem) async {
    final item = ShoppingItemEntity(
      id: _uuid.v4(),
      householdId: _householdId,
      name: pantryItem.name,
      quantity: 1,
      unit: pantryItem.unit,
      section: ShoppingSection.other,
      addedByUserId: _userId,
      assignedToUserId: null,
      isChecked: false,
      checkedByUserId: null,
      checkedAt: null,
      note: 'Restock pantry',
      createdAt: DateTime.now(),
    );
    await saveShoppingItem(item, pulsePreview: true);
  }

  Future<void> saveTemplate(ListTemplateEntity template) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _repository.saveTemplate(template);
      ref.invalidate(templatesProvider(_householdId));
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _repository.deleteTemplate(templateId);
      ref.invalidate(templatesProvider(_householdId));
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> applyTemplate(
    ListTemplateEntity template, {
    bool replaceCurrent = false,
  }) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      if (replaceCurrent) {
        await _repository.clearAllItems(_householdId);
      }
      await _repository.applyTemplate(
        householdId: _householdId,
        template: template,
        addedByUserId: _userId,
      );
      ref.read(memberPresenceProvider.notifier).recordActivity(_userId);
      _invalidateData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> savePantryItem(PantryItemEntity item) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final exists = ref.read(_pantryItemExistsProvider(item.id));
      if (exists) {
        await _repository.updatePantryItem(item);
      } else {
        await _repository.addPantryItem(item);
      }
      _invalidateData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> deletePantryItem(String id) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _repository.deletePantryItem(id);
      _invalidateData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> decrementPantryQuantity(String id, double amount) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _repository.decrementPantryQuantity(id, amount);
      _invalidateData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> batchAddToPantry({
    required List<ShoppingItemEntity> items,
    required Map<String, ({PantryLocation location, DateTime? expiry})> details,
  }) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      for (final item in items) {
        final detail = details[item.id];
        await _repository.addPantryItem(
          PantryItemEntity(
            id: _uuid.v4(),
            householdId: _householdId,
            name: item.name,
            category: pantryCategoryFromShoppingSection(item.section),
            quantity: item.quantity,
            unit: item.unit,
            location:
                detail?.location ??
                defaultPantryLocationForSection(item.section),
            expiryDate: detail?.expiry,
            purchaseDate: DateTime.now(),
            barcode: null,
            lowStockThreshold: item.quantity > 1 ? 1 : item.quantity,
            addedByUserId: _userId,
            createdAt: DateTime.now(),
          ),
        );
      }
      await _repository.clearCheckedItems(_householdId);
      ref.read(shoppingOptimisticProvider(_householdId).notifier).clearAll();
      _invalidateData();
      state = state.copyWith(isLoading: false, clearMessage: true);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  void _invalidateData() {
    ref.invalidate(shoppingItemsProvider(_householdId));
    ref.invalidate(templatesProvider(_householdId));
    ref.invalidate(pantryItemsProvider(_householdId));
    ref.invalidate(lowStockItemsProvider(_householdId));
    ref.invalidate(groceryHomeSummaryProvider);
    ref.invalidate(groceryBootstrapProvider);
  }
}

PantryCategory pantryCategoryFromShoppingSection(ShoppingSection section) {
  return switch (section) {
    ShoppingSection.produce => PantryCategory.produce,
    ShoppingSection.dairy => PantryCategory.dairy,
    ShoppingSection.meat => PantryCategory.meat,
    ShoppingSection.bakery => PantryCategory.bakery,
    ShoppingSection.frozen => PantryCategory.frozen,
    ShoppingSection.canned => PantryCategory.canned,
    ShoppingSection.beverages => PantryCategory.beverages,
    ShoppingSection.household => PantryCategory.other,
    ShoppingSection.personal => PantryCategory.other,
    ShoppingSection.other => PantryCategory.other,
  };
}

PantryLocation defaultPantryLocationForSection(ShoppingSection section) {
  return switch (section) {
    ShoppingSection.frozen => PantryLocation.freezer,
    ShoppingSection.dairy => PantryLocation.fridge,
    ShoppingSection.meat => PantryLocation.fridge,
    _ => PantryLocation.pantry,
  };
}

DateTime? suggestedExpiryForSection(ShoppingSection section, {DateTime? from}) {
  final anchor = from ?? DateTime.now();
  return switch (section) {
    ShoppingSection.dairy => anchor.add(const Duration(days: 7)),
    ShoppingSection.meat => anchor.add(const Duration(days: 3)),
    ShoppingSection.produce => anchor.add(const Duration(days: 5)),
    ShoppingSection.frozen => anchor.add(const Duration(days: 90)),
    _ => null,
  };
}

final groceryNotifierProvider =
    StateNotifierProvider<GroceryNotifier, GroceryActionState>((Ref ref) {
      return GroceryNotifier(ref);
    });

final groceryHouseholdIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).activeHouseholdId;
});

final groceryCurrentUserIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).userId;
});

final shoppingItemsProvider =
    StreamProvider.family<List<ShoppingItemEntity>, String>((
      Ref ref,
      String householdId,
    ) {
      return ref
          .watch(groceryRepositoryProvider)
          .watchItemsForHousehold(householdId);
    });

final shoppingOptimisticProvider =
    StateNotifierProvider.family<
      _ShoppingOptimisticController,
      Map<String, bool>,
      String
    >((Ref ref, String householdId) {
      return _ShoppingOptimisticController();
    });

final effectiveShoppingItemsProvider =
    Provider.family<List<ShoppingItemEntity>, String>((
      Ref ref,
      String householdId,
    ) {
      final itemsAsync = ref.watch(shoppingItemsProvider(householdId));
      final overrides = ref.watch(shoppingOptimisticProvider(householdId));
      final currentUserId = ref.watch(groceryCurrentUserIdProvider);
      return itemsAsync.maybeWhen(
        data: (List<ShoppingItemEntity> items) {
          final now = DateTime.now();
          return items.map((ShoppingItemEntity item) {
            final optimisticChecked = overrides[item.id];
            if (optimisticChecked == null ||
                optimisticChecked == item.isChecked) {
              return item;
            }
            if (optimisticChecked) {
              return item.copyWith(
                isChecked: true,
                checkedByUserId: currentUserId,
                checkedAt: now,
              );
            }
            return item.copyWith(
              isChecked: false,
              clearCheckedByUserId: true,
              clearCheckedAt: true,
            );
          }).toList();
        },
        orElse: () => const <ShoppingItemEntity>[],
      );
    });

final uncheckedShoppingItemsProvider =
    Provider.family<List<ShoppingItemEntity>, String>((
      Ref ref,
      String householdId,
    ) {
      final sortMode = ref.watch(shoppingSortModeProvider(householdId));
      final items = ref.watch(effectiveShoppingItemsProvider(householdId));
      final unchecked = items
          .where((ShoppingItemEntity item) => !item.isChecked)
          .toList();
      unchecked.sort((ShoppingItemEntity left, ShoppingItemEntity right) {
        if (sortMode == ShoppingSortMode.dateAdded) {
          return left.createdAt.compareTo(right.createdAt);
        }
        final sectionOrder = kSectionOrder
            .indexOf(left.section)
            .compareTo(kSectionOrder.indexOf(right.section));
        if (sectionOrder != 0) {
          return sectionOrder;
        }
        return left.createdAt.compareTo(right.createdAt);
      });
      return unchecked;
    });

final checkedShoppingItemsProvider =
    Provider.family<List<ShoppingItemEntity>, String>((
      Ref ref,
      String householdId,
    ) {
      final items = ref.watch(effectiveShoppingItemsProvider(householdId));
      final checked =
          items.where((ShoppingItemEntity item) => item.isChecked).toList()
            ..sort((ShoppingItemEntity left, ShoppingItemEntity right) {
              final leftCheckedAt = left.checkedAt ?? left.createdAt;
              final rightCheckedAt = right.checkedAt ?? right.createdAt;
              return rightCheckedAt.compareTo(leftCheckedAt);
            });
      return checked;
    });

final groupedShoppingItemsProvider =
    Provider.family<Map<ShoppingSection, List<ShoppingItemEntity>>, String>((
      Ref ref,
      String householdId,
    ) {
      final items = ref.watch(uncheckedShoppingItemsProvider(householdId));
      final grouped = <ShoppingSection, List<ShoppingItemEntity>>{};
      for (final section in kSectionOrder) {
        final sectionItems = items
            .where((ShoppingItemEntity item) => item.section == section)
            .toList();
        if (sectionItems.isNotEmpty) {
          grouped[section] = sectionItems;
        }
      }
      return grouped;
    });

final shoppingPreviewItemsProvider =
    Provider.family<List<ShoppingItemEntity>, String>((
      Ref ref,
      String householdId,
    ) {
      return ref
          .watch(uncheckedShoppingItemsProvider(householdId))
          .take(5)
          .toList();
    });

final shoppingSortModeProvider = StateProvider.family<ShoppingSortMode, String>(
  (Ref ref, String householdId) {
    return ShoppingSortMode.section;
  },
);

final shoppingCollapsedSectionsProvider =
    StateNotifierProvider.family<
      _CollapsedSectionsController,
      Set<String>,
      String
    >((Ref ref, String householdId) {
      return _CollapsedSectionsController();
    });

final pantryCollapsedSectionsProvider =
    StateNotifierProvider.family<
      _CollapsedSectionsController,
      Set<String>,
      String
    >((Ref ref, String householdId) {
      return _CollapsedSectionsController()..setCollapsed('checked', false);
    });

final inlineAddSectionProvider = StateProvider.family<String?, String>(
  (Ref ref, String householdId) => null,
);

final shoppingPulseIdsProvider =
    StateNotifierProvider<_ShoppingPulseController, Set<String>>((Ref ref) {
      return _ShoppingPulseController();
    });

final allItemsCheckedProvider = Provider.family<bool, String>((
  Ref ref,
  String householdId,
) {
  final items = ref.watch(effectiveShoppingItemsProvider(householdId));
  return items.isNotEmpty &&
      items.every((ShoppingItemEntity item) => item.isChecked);
});

final templatesProvider =
    StreamProvider.family<List<ListTemplateEntity>, String>((
      Ref ref,
      String householdId,
    ) {
      return ref.watch(groceryRepositoryProvider).watchTemplates(householdId);
    });

final pantryItemsProvider =
    StreamProvider.family<List<PantryItemEntity>, String>((
      Ref ref,
      String householdId,
    ) {
      return ref
          .watch(groceryRepositoryProvider)
          .watchPantryItemsForHousehold(householdId);
    });

final lowStockItemsProvider =
    StreamProvider.family<List<PantryItemEntity>, String>((
      Ref ref,
      String householdId,
    ) {
      return ref
          .watch(groceryRepositoryProvider)
          .watchLowStockItems(householdId);
    });

final pantryLocationFilterProvider =
    StateProvider.family<PantryLocation?, String>(
      (Ref ref, String householdId) => null,
    );

final pantryCategoryFilterProvider =
    StateProvider.family<PantryCategory?, String>(
      (Ref ref, String householdId) => null,
    );

final pantrySearchQueryProvider = StateProvider.family<String, String>(
  (Ref ref, String householdId) => '',
);

final groupedPantryItemsProvider =
    Provider.family<Map<PantryLocation, List<PantryItemEntity>>, String>((
      Ref ref,
      String householdId,
    ) {
      final itemsAsync = ref.watch(pantryItemsProvider(householdId));
      final locationFilter = ref.watch(
        pantryLocationFilterProvider(householdId),
      );
      final categoryFilter = ref.watch(
        pantryCategoryFilterProvider(householdId),
      );
      final searchQuery = ref
          .watch(pantrySearchQueryProvider(householdId))
          .trim()
          .toLowerCase();
      return itemsAsync.maybeWhen(
        data: (List<PantryItemEntity> items) {
          final filtered =
              items.where((PantryItemEntity item) {
                  final matchesLocation =
                      locationFilter == null || item.location == locationFilter;
                  final matchesCategory =
                      categoryFilter == null || item.category == categoryFilter;
                  final matchesSearch =
                      searchQuery.isEmpty ||
                      item.name.toLowerCase().contains(searchQuery);
                  return matchesLocation && matchesCategory && matchesSearch;
                }).toList()
                ..sort((PantryItemEntity left, PantryItemEntity right) {
                  final leftExpiry = left.expiryDate ?? DateTime(9999);
                  final rightExpiry = right.expiryDate ?? DateTime(9999);
                  final expiryOrder = leftExpiry.compareTo(rightExpiry);
                  if (expiryOrder != 0) {
                    return expiryOrder;
                  }
                  return left.name.compareTo(right.name);
                });
          final grouped = <PantryLocation, List<PantryItemEntity>>{};
          final locations = locationFilter == null
              ? PantryLocation.values
              : <PantryLocation>[locationFilter];
          for (final location in locations) {
            final locationItems = filtered
                .where((PantryItemEntity item) => item.location == location)
                .toList();
            if (locationItems.isNotEmpty) {
              grouped[location] = locationItems;
            }
          }
          return grouped;
        },
        orElse: () => const <PantryLocation, List<PantryItemEntity>>{},
      );
    });

final pantryLocationSummaryProvider =
    Provider.family<
      Map<PantryLocation, ({int totalCount, int warningCount})>,
      String
    >((Ref ref, String householdId) {
      final items =
          ref.watch(pantryItemsProvider(householdId)).valueOrNull ??
          const <PantryItemEntity>[];
      final summary = <PantryLocation, ({int totalCount, int warningCount})>{};
      for (final location in PantryLocation.values) {
        final locationItems = items
            .where((PantryItemEntity item) => item.location == location)
            .toList();
        if (locationItems.isEmpty) {
          continue;
        }
        final warningCount = locationItems.where((PantryItemEntity item) {
          return item.expiryUrgency == PantryExpiryUrgency.warning ||
              item.expiryUrgency == PantryExpiryUrgency.critical ||
              item.expiryUrgency == PantryExpiryUrgency.expired;
        }).length;
        summary[location] = (
          totalCount: locationItems.length,
          warningCount: warningCount,
        );
      }
      return summary;
    });

final memberPresenceProvider =
    StateNotifierProvider<MemberPresenceController, Map<String, DateTime>>((
      Ref ref,
    ) {
      return MemberPresenceController();
    });

final activeShoppingMemberIdsProvider = Provider<List<String>>((Ref ref) {
  final presence = ref.watch(memberPresenceProvider);
  final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
  return presence.entries
      .where((MapEntry<String, DateTime> entry) => entry.value.isAfter(cutoff))
      .map((MapEntry<String, DateTime> entry) => entry.key)
      .toList();
});

final groceryMemberLookupProvider =
    FutureProvider<Map<String, HouseholdMember>>((Ref ref) async {
      final members = await ref.watch(householdMembersProvider.future);
      return <String, HouseholdMember>{
        for (final member in members) member.userId: member,
      };
    });

final activeShoppingMembersProvider = FutureProvider<List<HouseholdMember>>((
  Ref ref,
) async {
  final activeIds = ref.watch(activeShoppingMemberIdsProvider);
  if (activeIds.isEmpty) {
    return const <HouseholdMember>[];
  }
  final members = await ref.watch(householdMembersProvider.future);
  return members
      .where((HouseholdMember member) => activeIds.contains(member.userId))
      .toList();
});

final groceryHomeSummaryProvider = FutureProvider<GroceryHomeSummary?>((
  Ref ref,
) async {
  final householdId = ref.watch(groceryHouseholdIdProvider);
  if (householdId == null) {
    return null;
  }
  return ref.watch(groceryRepositoryProvider).getHomeSummary(householdId);
});

final groceryBootstrapProvider = FutureProvider<void>((Ref ref) async {
  final householdId = ref.watch(groceryHouseholdIdProvider);
  if (householdId == null) {
    return;
  }
  final expiring = await ref
      .watch(groceryRepositoryProvider)
      .getItemsExpiringWithin(householdId, 7);
  await ref
      .watch(notificationServiceProvider)
      .schedulePantryExpiryAlerts(expiring);
});

final _shoppingItemExistsProvider = Provider.family<bool, String>((
  Ref ref,
  String itemId,
) {
  final householdId = ref.watch(groceryHouseholdIdProvider);
  if (householdId == null) {
    return false;
  }
  final items =
      ref.watch(shoppingItemsProvider(householdId)).valueOrNull ??
      const <ShoppingItemEntity>[];
  return items.any((ShoppingItemEntity item) => item.id == itemId);
});

final _pantryItemExistsProvider = Provider.family<bool, String>((
  Ref ref,
  String itemId,
) {
  final householdId = ref.watch(groceryHouseholdIdProvider);
  if (householdId == null) {
    return false;
  }
  final items =
      ref.watch(pantryItemsProvider(householdId)).valueOrNull ??
      const <PantryItemEntity>[];
  return items.any((PantryItemEntity item) => item.id == itemId);
});
