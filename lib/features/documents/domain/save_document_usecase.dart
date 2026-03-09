import 'dart:io';

import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/domain/document_repository.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SaveDocumentUseCase {
  const SaveDocumentUseCase(this._repository);

  final DocumentRepository _repository;

  Future<DocumentEntity> execute({
    required DocumentEntity document,
    required File sourceFile,
  }) async {
    final docsDirectory = await getApplicationDocumentsDirectory();
    final extension = _normalizedExtension(sourceFile.path);
    final destinationDirectory = Directory(
      path.join(
        docsDirectory.path,
        'hearth',
        'vault',
        document.householdId,
      ),
    );
    await destinationDirectory.create(recursive: true);

    final destinationPath = path.join(
      destinationDirectory.path,
      '${document.id}$extension',
    );
    final copied = await sourceFile.copy(destinationPath);
    final sizeBytes = await copied.length();
    final savedDocument = document.copyWith(
      localFilePath: destinationPath,
      fileSizeBytes: sizeBytes,
      mimeType: _mimeTypeForPath(destinationPath),
    );

    await _repository.saveDocument(savedDocument);

    return savedDocument;
  }

  String _normalizedExtension(String value) {
    final extension = path.extension(value).toLowerCase();
    if (extension == '.jpeg' || extension == '.jpg') {
      return '.jpg';
    }
    if (extension == '.png') {
      return '.png';
    }
    if (extension == '.pdf') {
      return '.pdf';
    }
    return extension.isEmpty ? '.bin' : extension;
  }

  String _mimeTypeForPath(String value) {
    switch (path.extension(value).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
