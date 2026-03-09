import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:path/path.dart' as path;

void main() {
  test('schema version 5 upgrade creates grocery tables', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'hearth-grocery-migration-',
    );
    addTearDown(() async {
      await tempDirectory.delete(recursive: true);
    });
    final databaseFile = File(path.join(tempDirectory.path, 'hearth.sqlite'));

    final initialDatabase = AppDatabase.test(NativeDatabase(databaseFile));
    await initialDatabase.customStatement(
      'DROP TABLE IF EXISTS shopping_list_items',
    );
    await initialDatabase.customStatement('DROP TABLE IF EXISTS pantry_items');
    await initialDatabase.customStatement(
      'DROP TABLE IF EXISTS list_templates',
    );
    await initialDatabase.customStatement('PRAGMA user_version = 4');
    await initialDatabase.close();

    final upgradedDatabase = AppDatabase.test(NativeDatabase(databaseFile));
    addTearDown(upgradedDatabase.close);

    final groceryTables = await upgradedDatabase.customSelect('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('shopping_list_items', 'pantry_items', 'list_templates')
      ORDER BY name
      ''').get();

    expect(groceryTables.map((row) => row.read<String>('name')), <String>[
      'list_templates',
      'pantry_items',
      'shopping_list_items',
    ]);

    await upgradedDatabase
        .into(upgradedDatabase.shoppingListItems)
        .insert(
          ShoppingListItemsCompanion.insert(
            id: 'shopping-1',
            householdId: 'household-1',
            name: 'Milk',
            addedByUserId: 'user-1',
            createdAt: DateTime(2026, 3, 9),
          ),
        );
    await upgradedDatabase
        .into(upgradedDatabase.pantryItems)
        .insert(
          PantryItemsCompanion.insert(
            id: 'pantry-1',
            householdId: 'household-1',
            name: 'Apples',
            addedByUserId: 'user-1',
            createdAt: DateTime(2026, 3, 9),
          ),
        );
    await upgradedDatabase
        .into(upgradedDatabase.listTemplates)
        .insert(
          ListTemplatesCompanion.insert(
            id: 'template-1',
            householdId: 'household-1',
            name: 'Weekly shop',
            itemsJson:
                '[{"name":"Milk","quantity":1,"unit":"L","section":"dairy"}]',
            createdByUserId: 'user-1',
            createdAt: DateTime(2026, 3, 9),
          ),
        );

    expect(
      await upgradedDatabase.select(upgradedDatabase.shoppingListItems).get(),
      hasLength(1),
    );
    expect(
      await upgradedDatabase.select(upgradedDatabase.pantryItems).get(),
      hasLength(1),
    );
    expect(
      await upgradedDatabase.select(upgradedDatabase.listTemplates).get(),
      hasLength(1),
    );
  });
}
