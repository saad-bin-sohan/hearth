import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/documents/data/tables.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/domain/document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((Ref ref) {
  return LocalDocumentRepository(database: ref.read(appDatabaseProvider));
});

class LocalDocumentRepository implements DocumentRepository {
  LocalDocumentRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  @override
  Stream<List<VaultFolderEntity>> watchFolders(String householdId) {
    final query =
        (_database.select(_database.vaultFolders)
              ..where((VaultFolders row) => row.householdId.equals(householdId))
              ..orderBy(<OrderingTerm Function(VaultFolders)>[
                (VaultFolders row) => OrderingTerm.asc(row.name),
                (VaultFolders row) => OrderingTerm.asc(row.createdAt),
              ]))
            .watch();
    return query.map(
      (List<VaultFolder> rows) => rows.map(_mapFolder).toList(),
    );
  }

  @override
  Future<void> createFolder(VaultFolderEntity folder) async {
    await _database.into(_database.vaultFolders).insert(
          VaultFoldersCompanion.insert(
            id: folder.id,
            householdId: folder.householdId,
            name: folder.name.trim(),
            parentFolderPath: Value<String>(folder.parentFolderPath),
            createdByUserId: folder.createdByUserId,
            createdAt: folder.createdAt,
          ),
        );
  }

  @override
  Future<void> renameFolder({
    required String folderId,
    required String householdId,
    required String name,
  }) async {
    await (_database.update(_database.vaultFolders)
          ..where(
            (VaultFolders row) =>
                row.id.equals(folderId) & row.householdId.equals(householdId),
          ))
        .write(VaultFoldersCompanion(name: Value<String>(name.trim())));
  }

  @override
  Future<void> deleteFolder(String folderId, String householdId) async {
    final folder =
        await (_database.select(_database.vaultFolders)
              ..where(
                (VaultFolders row) =>
                    row.id.equals(folderId) &
                    row.householdId.equals(householdId),
              ))
            .getSingleOrNull();
    if (folder == null) {
      return;
    }
    final folderPath = _mapFolder(folder).fullPath;
    await _database.transaction(() async {
      await (_database.update(_database.documents)
            ..where(
              (Documents row) =>
                  row.householdId.equals(householdId) &
                  row.folderPath.equals(folderPath),
            ))
          .write(
        const DocumentsCompanion(folderPath: Value<String>('root')),
      );
      await (_database.delete(_database.vaultFolders)
            ..where((VaultFolders row) => row.id.equals(folderId)))
          .go();
    });
  }

  @override
  Stream<List<DocumentEntity>> watchDocumentsInFolder(
    String householdId,
    String folderPath,
  ) {
    final query =
        (_database.select(_database.documents)
              ..where(
                (Documents row) =>
                    row.householdId.equals(householdId) &
                    row.folderPath.equals(folderPath),
              )
              ..orderBy(<OrderingTerm Function(Documents)>[
                (Documents row) => OrderingTerm.desc(row.uploadedAt),
                (Documents row) => OrderingTerm.asc(row.title),
              ]))
            .watch();
    return query.map((List<Document> rows) => rows.map(_mapDocument).toList());
  }

  @override
  Stream<List<DocumentEntity>> watchAllDocuments(String householdId) {
    final query =
        (_database.select(_database.documents)
              ..where((Documents row) => row.householdId.equals(householdId))
              ..orderBy(<OrderingTerm Function(Documents)>[
                (Documents row) => OrderingTerm.desc(row.uploadedAt),
                (Documents row) => OrderingTerm.asc(row.title),
              ]))
            .watch();
    return query.map((List<Document> rows) => rows.map(_mapDocument).toList());
  }

  @override
  Future<DocumentEntity?> getDocumentById(String id) async {
    final row =
        await (_database.select(_database.documents)
              ..where((Documents document) => document.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : _mapDocument(row);
  }

  @override
  Future<void> saveDocument(DocumentEntity document) async {
    await _database.into(_database.documents).insertOnConflictUpdate(
          DocumentsCompanion(
            id: Value<String>(document.id),
            householdId: Value<String>(document.householdId),
            title: Value<String>(document.title.trim()),
            docType: Value<String>(document.docType.name),
            folderPath: Value<String>(document.folderPath),
            issuer: Value<String?>(document.issuer?.trim()),
            docDate: Value<DateTime?>(document.docDate),
            expiryDate: Value<DateTime?>(document.expiryDate),
            linkedAssetId: Value<String?>(document.linkedAssetId),
            localFilePath: Value<String>(document.localFilePath),
            fileSizeBytes: Value<int>(document.fileSizeBytes),
            mimeType: Value<String>(document.mimeType),
            visibility: Value<String>(document.visibility.name),
            uploadedByUserId: Value<String>(document.uploadedByUserId),
            uploadedAt: Value<DateTime>(document.uploadedAt),
          ),
        );
  }

  @override
  Future<void> deleteDocument(String id) async {
    await (_database.delete(_database.documents)
          ..where((Documents row) => row.id.equals(id)))
        .go();
  }

  @override
  Future<List<DocumentEntity>> searchDocuments(
    String householdId,
    String query,
  ) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const <DocumentEntity>[];
    }
    final rows =
        await (_database.select(_database.documents)
              ..where(
                (Documents row) =>
                    row.householdId.equals(householdId) &
                    (row.title.like('%$normalizedQuery%') |
                        row.issuer.like('%$normalizedQuery%')),
              )
              ..orderBy(<OrderingTerm Function(Documents)>[
                (Documents row) => OrderingTerm.desc(row.uploadedAt),
              ]))
            .get();
    return rows.map(_mapDocument).toList();
  }

  @override
  Future<List<DocumentEntity>> getDocumentsWithExpiryBefore(
    String householdId,
    DateTime cutoff,
  ) async {
    final rows =
        await (_database.select(_database.documents)
              ..where(
                (Documents row) =>
                    row.householdId.equals(householdId) &
                    row.expiryDate.isNotNull() &
                    row.expiryDate.isSmallerOrEqualValue(cutoff),
              )
              ..orderBy(<OrderingTerm Function(Documents)>[
                (Documents row) => OrderingTerm.asc(row.expiryDate),
                (Documents row) => OrderingTerm.asc(row.title),
              ]))
            .get();
    return rows.map(_mapDocument).toList();
  }

  @override
  Future<int> getDocumentCountInFolder(String householdId, String folderPath) {
    return (_database.selectOnly(_database.documents)
          ..addColumns(<Expression<Object>>[
            _database.documents.id.count(),
          ])
          ..where(
            _database.documents.householdId.equals(householdId) &
                _database.documents.folderPath.equals(folderPath),
          ))
        .map((TypedResult row) => row.read(_database.documents.id.count()) ?? 0)
        .getSingle();
  }

  DocumentEntity _mapDocument(Document row) {
    return DocumentEntity(
      id: row.id,
      householdId: row.householdId,
      title: row.title,
      docType: DocumentTypeX.fromName(row.docType),
      folderPath: row.folderPath,
      issuer: row.issuer,
      docDate: row.docDate,
      expiryDate: row.expiryDate,
      linkedAssetId: row.linkedAssetId,
      localFilePath: row.localFilePath,
      fileSizeBytes: row.fileSizeBytes,
      mimeType: row.mimeType,
      visibility: DocumentVisibilityX.fromName(row.visibility),
      uploadedByUserId: row.uploadedByUserId,
      uploadedAt: row.uploadedAt,
    );
  }

  VaultFolderEntity _mapFolder(VaultFolder row) {
    return VaultFolderEntity(
      id: row.id,
      householdId: row.householdId,
      name: row.name,
      parentFolderPath: row.parentFolderPath,
      createdByUserId: row.createdByUserId,
      createdAt: row.createdAt,
    );
  }
}
