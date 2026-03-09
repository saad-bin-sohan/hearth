import 'dart:io';

import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/domain/document_repository.dart';

class DeleteDocumentUseCase {
  const DeleteDocumentUseCase(this._repository);

  final DocumentRepository _repository;

  Future<void> execute(DocumentEntity document) async {
    final file = File(document.localFilePath);
    if (await file.exists()) {
      await file.delete();
    }
    await _repository.deleteDocument(document.id);
  }
}
