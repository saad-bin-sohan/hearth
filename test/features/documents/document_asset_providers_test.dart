import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/documents/presentation/providers/document_asset_providers.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('asset picker returns household assets and resolves linked asset names', () async {
    await database.into(database.assets).insert(
          AssetsCompanion.insert(
            id: 'asset-1',
            householdId: 'household-1',
            name: 'Boiler',
            categoryEnum: 'hvac',
            createdByUserId: 'user-1',
            createdAt: DateTime(2026, 3, 9),
          ),
        );
    await database.into(database.assets).insert(
          AssetsCompanion.insert(
            id: 'asset-2',
            householdId: 'household-2',
            name: 'Dryer',
            categoryEnum: 'appliance',
            createdByUserId: 'user-2',
            createdAt: DateTime(2026, 3, 9),
          ),
        );

    final options = await container.read(assetPickerProvider('household-1').future);
    final linkedAssetName = await container.read(linkedAssetNameProvider('asset-1').future);

    expect(options, hasLength(1));
    expect(options.single.id, 'asset-1');
    expect(options.single.name, 'Boiler');
    expect(options.single.category, 'hvac');
    expect(linkedAssetName, 'Boiler');
  });
}
