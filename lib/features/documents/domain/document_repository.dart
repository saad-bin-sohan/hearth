import 'package:hearth/features/documents/domain/document_models.dart';

abstract class DocumentRepository {
  Stream<List<VaultFolderEntity>> watchFolders(String householdId);

  Future<void> createFolder(VaultFolderEntity folder);

  Future<void> renameFolder({
    required String folderId,
    required String householdId,
    required String name,
  });

  Future<void> deleteFolder(String folderId, String householdId);

  Stream<List<DocumentEntity>> watchDocumentsInFolder(
    String householdId,
    String folderPath,
  );

  Stream<List<DocumentEntity>> watchAllDocuments(String householdId);

  Future<DocumentEntity?> getDocumentById(String id);

  Future<void> saveDocument(DocumentEntity document);

  Future<void> deleteDocument(String id);

  Future<List<DocumentEntity>> searchDocuments(String householdId, String query);

  Future<List<DocumentEntity>> getDocumentsWithExpiryBefore(
    String householdId,
    DateTime cutoff,
  );

  Future<int> getDocumentCountInFolder(String householdId, String folderPath);
}
