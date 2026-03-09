import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/services/notification_service.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';

void main() {
  test('generic notification ids stay above reserved module ranges', () {
    final notificationId = LocalNotificationService.genericNotificationIdFor(
      'chore-overdue-user-1',
    );

    expect(notificationId, greaterThanOrEqualTo(4000));
  });

  test('document notification ids stay in the 2000 range', () {
    final first = LocalNotificationService.documentNotificationIdFor(
      'document-1',
      '60d',
    );
    final second = LocalNotificationService.documentNotificationIdFor(
      'document-1',
      '7d',
    );

    expect(first, inInclusiveRange(2000, 2999));
    expect(second, inInclusiveRange(2000, 2999));
  });

  test('pantry notifications use the 3000 range only for qualifying items', () {
    final now = DateTime.now();
    final planned = LocalNotificationService.plannedPantryNotificationEntries(
      <PantryItemEntity>[
        _pantryItem(
          id: 'safe',
          name: 'Rice',
          expiryDate: now.add(const Duration(days: 12)),
        ),
        _pantryItem(
          id: 'warning',
          name: 'Milk',
          expiryDate: now.add(const Duration(days: 6)),
        ),
        _pantryItem(
          id: 'critical',
          name: 'Chicken',
          expiryDate: now.add(const Duration(days: 1)),
        ),
      ],
    );

    expect(planned.map((entry) => entry.id), <int>[3000, 3001]);
    expect(planned.map((entry) => entry.item.name), <String>[
      'Milk',
      'Chicken',
    ]);
  });
}

PantryItemEntity _pantryItem({
  required String id,
  required String name,
  required DateTime expiryDate,
}) {
  return PantryItemEntity(
    id: id,
    householdId: 'household-1',
    name: name,
    category: PantryCategory.other,
    quantity: 1,
    unit: 'pcs',
    location: PantryLocation.pantry,
    expiryDate: expiryDate,
    purchaseDate: DateTime(2026, 3, 9),
    barcode: null,
    lowStockThreshold: 1,
    addedByUserId: 'user-1',
    createdAt: DateTime(2026, 3, 9),
  );
}
