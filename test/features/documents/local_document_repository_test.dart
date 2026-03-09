import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hearth/core/database/app_database.dart';
import 'package:hearth/features/documents/data/local_document_repository.dart';
import 'package:hearth/features/documents/domain/delete_document_usecase.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/domain/save_document_usecase.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late LocalDocumentRepository repository;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    repository = LocalDocumentRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('folder create and rename keep a stable folder path', () async {
    const householdId = 'household-1';
    final folder = _folder(
      id: 'folder-1',
      householdId: householdId,
      name: 'Insurance',
    );

    await repository.createFolder(folder);
    await repository.renameFolder(
      folderId: folder.id,
      householdId: householdId,
      name: 'Policies',
    );

    final folders = await repository.watchFolders(householdId).first;

    expect(folders, hasLength(1));
    expect(folders.single.name, 'Policies');
    expect(folders.single.fullPath, 'root/folder-1');
  });

  test('save, update, and delete document persists detail records', () async {
    final document = _document(id: 'document-1');

    await repository.saveDocument(document);

    final inserted = await repository.getDocumentById(document.id);
    expect(inserted, document);
    expect(
      await repository.getDocumentCountInFolder(
        document.householdId,
        document.folderPath,
      ),
      1,
    );

    await repository.saveDocument(document.copyWith(title: 'Updated Passport'));
    final updated = await repository.getDocumentById(document.id);
    expect(updated?.title, 'Updated Passport');

    await repository.deleteDocument(document.id);

    expect(await repository.getDocumentById(document.id), isNull);
    expect(
      await repository.getDocumentCountInFolder(
        document.householdId,
        document.folderPath,
      ),
      0,
    );
  });

  test('deleting a folder moves contained documents back to root', () async {
    const householdId = 'household-1';
    final folder = _folder(
      id: 'folder-2',
      householdId: householdId,
      name: 'Medical',
    );
    final document = _document(
      id: 'document-2',
      householdId: householdId,
      folderPath: folder.fullPath,
      title: 'Vaccination Record',
    );

    await repository.createFolder(folder);
    await repository.saveDocument(document);
    await repository.deleteFolder(folder.id, householdId);

    final saved = await repository.getDocumentById(document.id);
    final folders = await repository.watchFolders(householdId).first;

    expect(saved?.folderPath, 'root');
    expect(folders, isEmpty);
  });

  test('searchDocuments matches title and issuer and expiry query sorts by date', () async {
    const householdId = 'household-1';
    await repository.saveDocument(
      _document(
        id: 'expired',
        householdId: householdId,
        title: 'Resident Permit',
        issuer: 'City Services',
        expiryDate: DateTime(2026, 3, 1),
        uploadedAt: DateTime(2026, 3, 9, 8),
      ),
    );
    await repository.saveDocument(
      _document(
        id: 'critical',
        householdId: householdId,
        title: 'Passport',
        issuer: 'National Authority',
        expiryDate: DateTime(2026, 3, 14),
        uploadedAt: DateTime(2026, 3, 9, 9),
      ),
    );
    await repository.saveDocument(
      _document(
        id: 'warning',
        householdId: householdId,
        title: 'Insurance Policy',
        issuer: 'Metro Health',
        expiryDate: DateTime(2026, 4, 18),
        uploadedAt: DateTime(2026, 3, 9, 10),
      ),
    );
    await repository.saveDocument(
      _document(
        id: 'safe',
        householdId: householdId,
        title: 'Warranty Card',
        issuer: 'Northwind Appliances',
        expiryDate: DateTime(2026, 7, 1),
        uploadedAt: DateTime(2026, 3, 9, 11),
      ),
    );

    final titleMatches = await repository.searchDocuments(
      householdId,
      'Passport',
    );
    final issuerMatches = await repository.searchDocuments(
      householdId,
      'Metro',
    );
    final expiring = await repository.getDocumentsWithExpiryBefore(
      householdId,
      DateTime(2026, 5, 1),
    );

    expect(titleMatches.map((document) => document.id), <String>['critical']);
    expect(issuerMatches.map((document) => document.id), <String>['warning']);
    expect(
      expiring.map((document) => document.id),
      <String>['expired', 'critical', 'warning'],
    );
  });

  test('save and delete use cases copy into the vault directory and remove files', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'hearth-docs-files-',
    );
    addTearDown(() async {
      const MethodChannel channel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await tempDirectory.delete(recursive: true);
    });
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tempDirectory.path;
      }
      return null;
    });

    final sourceFile = File(path.join(tempDirectory.path, 'scan.jpg'));
    await sourceFile.writeAsBytes(List<int>.filled(32, 7));
    final document = _document(
      id: 'document-file',
      localFilePath: sourceFile.path,
      fileSizeBytes: 0,
      mimeType: 'image/jpeg',
    );

    final saved = await SaveDocumentUseCase(repository).execute(
      document: document,
      sourceFile: sourceFile,
    );

    expect(File(saved.localFilePath).existsSync(), isTrue);
    expect(
      saved.localFilePath,
      path.join(
        tempDirectory.path,
        'hearth',
        'vault',
        document.householdId,
        'document-file.jpg',
      ),
    );
    expect(saved.fileSizeBytes, 32);

    await DeleteDocumentUseCase(repository).execute(saved);

    expect(File(saved.localFilePath).existsSync(), isFalse);
    expect(await repository.getDocumentById(saved.id), isNull);
  });
}

VaultFolderEntity _folder({
  required String id,
  required String householdId,
  required String name,
}) {
  return VaultFolderEntity(
    id: id,
    householdId: householdId,
    name: name,
    parentFolderPath: 'root',
    createdByUserId: 'user-1',
    createdAt: DateTime(2026, 3, 9),
  );
}

DocumentEntity _document({
  required String id,
  String householdId = 'household-1',
  String title = 'Passport',
  DocumentType docType = DocumentType.passport,
  String folderPath = 'root',
  String? issuer = 'National Authority',
  DateTime? expiryDate,
  String localFilePath = '/tmp/passport.pdf',
  int fileSizeBytes = 2048,
  String mimeType = 'application/pdf',
  DateTime? uploadedAt,
}) {
  return DocumentEntity(
    id: id,
    householdId: householdId,
    title: title,
    docType: docType,
    folderPath: folderPath,
    issuer: issuer,
    expiryDate: expiryDate,
    localFilePath: localFilePath,
    fileSizeBytes: fileSizeBytes,
    mimeType: mimeType,
    visibility: DocumentVisibility.all,
    uploadedByUserId: 'user-1',
    uploadedAt: uploadedAt ?? DateTime(2026, 3, 9, 12),
  );
}
