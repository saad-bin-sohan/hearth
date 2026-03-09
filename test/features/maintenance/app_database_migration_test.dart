import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:path/path.dart' as path;

void main() {
  test('schema version 6 upgrade creates maintenance tables', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'hearth-maintenance-migration-',
    );
    addTearDown(() async {
      await tempDirectory.delete(recursive: true);
    });
    final databaseFile = File(path.join(tempDirectory.path, 'hearth.sqlite'));

    final initialDatabase = AppDatabase.test(NativeDatabase(databaseFile));
    await initialDatabase.customStatement('DROP TABLE IF EXISTS assets');
    await initialDatabase.customStatement('DROP TABLE IF EXISTS maintenance_tasks');
    await initialDatabase.customStatement('DROP TABLE IF EXISTS vendors');
    await initialDatabase.customStatement('DROP TABLE IF EXISTS vendor_ratings');
    await initialDatabase.customStatement('PRAGMA user_version = 5');
    await initialDatabase.close();

    final upgradedDatabase = AppDatabase.test(NativeDatabase(databaseFile));
    addTearDown(upgradedDatabase.close);

    final maintenanceTables = await upgradedDatabase.customSelect('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('assets', 'maintenance_tasks', 'vendors', 'vendor_ratings')
      ORDER BY name
      ''').get();

    expect(maintenanceTables.map((row) => row.read<String>('name')), <String>[
      'assets',
      'maintenance_tasks',
      'vendor_ratings',
      'vendors',
    ]);

    await upgradedDatabase.into(upgradedDatabase.assets).insert(
          AssetsCompanion.insert(
            id: 'asset-1',
            householdId: 'household-1',
            name: 'Water Heater',
            categoryEnum: 'hvac',
            createdByUserId: 'user-1',
            createdAt: DateTime(2026, 3, 9),
          ),
        );
    await upgradedDatabase.into(upgradedDatabase.vendors).insert(
          VendorsCompanion.insert(
            id: 'vendor-1',
            householdId: 'household-1',
            businessName: 'Northwind HVAC',
            categoryEnum: 'hvac',
            createdByUserId: 'user-1',
            createdAt: DateTime(2026, 3, 9),
          ),
        );
    await upgradedDatabase.into(upgradedDatabase.maintenanceTasks).insert(
          MaintenanceTasksCompanion.insert(
            id: 'task-1',
            householdId: 'household-1',
            assetId: const Value<String?>('asset-1'),
            title: 'Flush tank',
            vendorId: const Value<String?>('vendor-1'),
            createdAt: DateTime(2026, 3, 9),
            createdByUserId: 'user-1',
          ),
        );
    await upgradedDatabase.into(upgradedDatabase.vendorRatings).insert(
          VendorRatingsCompanion.insert(
            id: 'rating-1',
            vendorId: 'vendor-1',
            ratingByUserId: 'user-1',
            stars: 5,
            ratedAt: DateTime(2026, 3, 9),
          ),
        );

    expect(await upgradedDatabase.select(upgradedDatabase.assets).get(), hasLength(1));
    expect(
      await upgradedDatabase.select(upgradedDatabase.maintenanceTasks).get(),
      hasLength(1),
    );
    expect(await upgradedDatabase.select(upgradedDatabase.vendors).get(), hasLength(1));
    expect(
      await upgradedDatabase.select(upgradedDatabase.vendorRatings).get(),
      hasLength(1),
    );
  });
}
