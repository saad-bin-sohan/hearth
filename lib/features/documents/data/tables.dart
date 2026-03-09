import 'package:drift/drift.dart';
import 'package:hearth/core/database/app_database.dart';

class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get title => text()();
  TextColumn get docType => text()();
  TextColumn get folderPath => text().withDefault(const Constant('root'))();
  TextColumn get issuer => text().nullable()();
  DateTimeColumn get docDate => dateTime().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get linkedAssetId => text().nullable()();
  TextColumn get localFilePath => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get mimeType => text()();
  TextColumn get visibility => text().withDefault(const Constant('all'))();
  TextColumn get uploadedByUserId => text()();
  DateTimeColumn get uploadedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class VaultFolders extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  TextColumn get parentFolderPath => text().withDefault(const Constant('root'))();
  TextColumn get createdByUserId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

List<TableInfo<Table, Object?>> documentTables(AppDatabase db) =>
    <TableInfo<Table, Object?>>[db.documents, db.vaultFolders];
