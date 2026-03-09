import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/core/services/notification_service.dart';
import 'package:hearth/features/documents/data/local_document_repository.dart';
import 'package:hearth/features/documents/domain/delete_document_usecase.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/domain/save_document_usecase.dart';
import 'package:uuid/uuid.dart';

class DocumentActionState {
  const DocumentActionState({
    this.isLoading = false,
    this.message,
    this.lastSavedDocumentId,
    this.firstDocumentCreated = false,
  });

  final bool isLoading;
  final String? message;
  final String? lastSavedDocumentId;
  final bool firstDocumentCreated;

  DocumentActionState copyWith({
    bool? isLoading,
    String? message,
    String? lastSavedDocumentId,
    bool? firstDocumentCreated,
    bool clearMessage = false,
    bool clearLastSavedDocumentId = false,
  }) {
    return DocumentActionState(
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
      lastSavedDocumentId: clearLastSavedDocumentId
          ? null
          : lastSavedDocumentId ?? this.lastSavedDocumentId,
      firstDocumentCreated: firstDocumentCreated ?? this.firstDocumentCreated,
    );
  }
}

class DocumentSearchNotifier extends StateNotifier<AsyncValue<List<DocumentEntity>>> {
  DocumentSearchNotifier(this.ref) : super(const AsyncValue.data(<DocumentEntity>[]));

  final Ref ref;

  Future<void> search({
    required String householdId,
    required String query,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      state = const AsyncValue.data(<DocumentEntity>[]);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref
          .read(documentRepositoryProvider)
          .searchDocuments(householdId, normalizedQuery);
    });
  }

  void clear() {
    state = const AsyncValue.data(<DocumentEntity>[]);
  }
}

class DocumentNotifier extends StateNotifier<DocumentActionState> {
  DocumentNotifier(this.ref)
      : _uuid = const Uuid(),
        super(const DocumentActionState());

  final Ref ref;
  final Uuid _uuid;

  Future<DocumentEntity> saveDocument({
    required DocumentEntity document,
    required File sourceFile,
  }) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final householdId = document.householdId;
      final beforeCount = await ref
          .read(documentRepositoryProvider)
          .watchAllDocuments(householdId)
          .first
          .then((List<DocumentEntity> value) => value.length);
      final saved = await SaveDocumentUseCase(
        ref.read(documentRepositoryProvider),
      ).execute(document: document, sourceFile: sourceFile);
      _invalidateDocuments();
      state = state.copyWith(
        isLoading: false,
        lastSavedDocumentId: saved.id,
        firstDocumentCreated: beforeCount == 0,
      );
      return saved;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<DocumentEntity> updateDocument({
    required DocumentEntity document,
    File? replacementSourceFile,
  }) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final previous = await ref
          .read(documentRepositoryProvider)
          .getDocumentById(document.id);
      final saved = replacementSourceFile == null
          ? document
          : await SaveDocumentUseCase(ref.read(documentRepositoryProvider))
              .execute(document: document, sourceFile: replacementSourceFile);
      if (replacementSourceFile == null) {
        await ref.read(documentRepositoryProvider).saveDocument(saved);
      } else if (previous != null &&
          previous.localFilePath != saved.localFilePath &&
          File(previous.localFilePath).existsSync()) {
        await File(previous.localFilePath).delete();
      }
      _invalidateDocuments();
      ref.invalidate(documentDetailProvider(saved.id));
      state = state.copyWith(
        isLoading: false,
        lastSavedDocumentId: saved.id,
      );
      return saved;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> deleteDocument(DocumentEntity document) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await DeleteDocumentUseCase(ref.read(documentRepositoryProvider))
          .execute(document);
      _invalidateDocuments();
      ref.invalidate(documentDetailProvider(document.id));
      state = state.copyWith(
        isLoading: false,
        clearLastSavedDocumentId: true,
        firstDocumentCreated: false,
      );
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<VaultFolderEntity> createFolder({
    required String householdId,
    required String name,
  }) async {
    final actorUserId = ref.read(sessionControllerProvider).userId;
    if (actorUserId == null) {
      throw StateError('You must be signed in to create folders.');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final folder = VaultFolderEntity(
        id: _uuid.v4(),
        householdId: householdId,
        name: name.trim(),
        parentFolderPath: 'root',
        createdByUserId: actorUserId,
        createdAt: DateTime.now(),
      );
      await ref.read(documentRepositoryProvider).createFolder(folder);
      ref.invalidate(vaultFoldersProvider);
      state = state.copyWith(isLoading: false);
      return folder;
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> renameFolder({
    required String folderId,
    required String householdId,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref.read(documentRepositoryProvider).renameFolder(
            folderId: folderId,
            householdId: householdId,
            name: name,
          );
      ref.invalidate(vaultFoldersProvider);
      state = state.copyWith(isLoading: false);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  Future<void> deleteFolder(String folderId, String householdId) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await ref.read(documentRepositoryProvider).deleteFolder(folderId, householdId);
      _invalidateDocuments();
      state = state.copyWith(isLoading: false);
    } on StateError catch (error) {
      state = state.copyWith(isLoading: false, message: error.message);
      rethrow;
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  void clearTransientState() {
    state = state.copyWith(
      clearLastSavedDocumentId: true,
      firstDocumentCreated: false,
      clearMessage: true,
    );
  }

  DocumentEntity draftDocument({
    String? id,
    required String householdId,
    required String title,
    required DocumentType docType,
    required String folderPath,
    String? issuer,
    DateTime? docDate,
    DateTime? expiryDate,
    String? linkedAssetId,
    required String localFilePath,
    required int fileSizeBytes,
    required String mimeType,
    required DocumentVisibility visibility,
    required String uploadedByUserId,
    DateTime? uploadedAt,
  }) {
    return DocumentEntity(
      id: id ?? _uuid.v4(),
      householdId: householdId,
      title: title.trim(),
      docType: docType,
      folderPath: folderPath,
      issuer: issuer?.trim().isEmpty ?? true ? null : issuer?.trim(),
      docDate: docDate,
      expiryDate: expiryDate,
      linkedAssetId: linkedAssetId,
      localFilePath: localFilePath,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
      visibility: visibility,
      uploadedByUserId: uploadedByUserId,
      uploadedAt: uploadedAt ?? DateTime.now(),
    );
  }

  void _invalidateDocuments() {
    ref.invalidate(documentBootstrapProvider);
    ref.invalidate(allDocumentsProvider);
    ref.invalidate(vaultFoldersProvider);
    ref.invalidate(expiringDocumentsProvider);
    ref.invalidate(documentSearchProvider);
  }
}

final documentNotifierProvider =
    StateNotifierProvider<DocumentNotifier, DocumentActionState>((Ref ref) {
  return DocumentNotifier(ref);
});

final documentSearchProvider = StateNotifierProvider<
    DocumentSearchNotifier,
    AsyncValue<List<DocumentEntity>>>((Ref ref) {
  return DocumentSearchNotifier(ref);
});

final documentHouseholdIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).activeHouseholdId;
});

final documentCurrentUserIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(sessionControllerProvider).userId;
});

final allDocumentsProvider = StreamProvider<List<DocumentEntity>>((Ref ref) {
  final householdId = ref.watch(documentHouseholdIdProvider);
  if (householdId == null) {
    return Stream<List<DocumentEntity>>.value(const <DocumentEntity>[]);
  }
  return ref.watch(documentRepositoryProvider).watchAllDocuments(householdId);
});

final documentsInFolderProvider = StreamProvider.family<List<DocumentEntity>, String>(
  (Ref ref, String folderPath) {
    final householdId = ref.watch(documentHouseholdIdProvider);
    if (householdId == null) {
      return Stream<List<DocumentEntity>>.value(const <DocumentEntity>[]);
    }
    return ref
        .watch(documentRepositoryProvider)
        .watchDocumentsInFolder(householdId, folderPath);
  },
);

final vaultFoldersProvider = StreamProvider<List<VaultFolderEntity>>((Ref ref) {
  final householdId = ref.watch(documentHouseholdIdProvider);
  if (householdId == null) {
    return Stream<List<VaultFolderEntity>>.value(const <VaultFolderEntity>[]);
  }
  return ref.watch(documentRepositoryProvider).watchFolders(householdId);
});

final documentDetailProvider = FutureProvider.family<DocumentEntity?, String>((
  Ref ref,
  String documentId,
) {
  return ref.watch(documentRepositoryProvider).getDocumentById(documentId);
});

final expiringDocumentsProvider = FutureProvider<List<DocumentEntity>>((Ref ref) async {
  final householdId = ref.watch(documentHouseholdIdProvider);
  if (householdId == null) {
    return const <DocumentEntity>[];
  }
  return ref
      .watch(documentRepositoryProvider)
      .getDocumentsWithExpiryBefore(
        householdId,
        DateTime.now().add(const Duration(days: 60)),
      );
});

final folderDocumentCountProvider = FutureProvider.family<int, String>((
  Ref ref,
  String folderPath,
) async {
  final householdId = ref.watch(documentHouseholdIdProvider);
  if (householdId == null) {
    return 0;
  }
  return ref
      .watch(documentRepositoryProvider)
      .getDocumentCountInFolder(householdId, folderPath);
});

final documentBootstrapProvider = FutureProvider<void>((Ref ref) async {
  final householdId = ref.watch(documentHouseholdIdProvider);
  if (householdId == null) {
    return;
  }
  final expiring = await ref.watch(expiringDocumentsProvider.future);
  if (expiring.isEmpty) {
    return;
  }
  await ref
      .watch(notificationServiceProvider)
      .scheduleDocumentExpiryAlerts(expiring);
});
