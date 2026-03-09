import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart' as db;

typedef DocumentAssetOption = ({String id, String name, String category});

final assetPickerProvider =
    FutureProvider.family<List<DocumentAssetOption>, String>((Ref ref, String householdId) async {
  final database = ref.watch(db.appDatabaseProvider);
  final rows = await (database.select(database.assets)
        ..where((table) => table.householdId.equals(householdId))
        ..orderBy(<OrderingTerm Function(db.$AssetsTable)>[
          (table) => OrderingTerm.asc(table.name),
        ]))
      .get();
  return rows
      .map(
        (db.Asset row) => (
          id: row.id,
          name: row.name,
          category: row.categoryEnum,
        ),
      )
      .toList();
});

final linkedAssetNameProvider = FutureProvider.family<String?, String>((
  Ref ref,
  String assetId,
) async {
  final database = ref.watch(db.appDatabaseProvider);
  final row = await (database.select(database.assets)
        ..where((table) => table.id.equals(assetId)))
      .getSingleOrNull();
  return row?.name;
});
