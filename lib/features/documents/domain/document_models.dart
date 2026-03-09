import 'package:equatable/equatable.dart';

enum DocumentType {
  id,
  passport,
  insurance,
  warranty,
  lease,
  medical,
  financial,
  other,
}

extension DocumentTypeX on DocumentType {
  String get label => switch (this) {
    DocumentType.id => 'ID',
    DocumentType.passport => 'Passport',
    DocumentType.insurance => 'Insurance',
    DocumentType.warranty => 'Warranty',
    DocumentType.lease => 'Lease',
    DocumentType.medical => 'Medical',
    DocumentType.financial => 'Financial',
    DocumentType.other => 'Other',
  };

  static DocumentType fromName(String value) {
    return DocumentType.values.firstWhere(
      (DocumentType type) => type.name == value,
      orElse: () => DocumentType.other,
    );
  }
}

enum DocumentVisibility { all, adminOnly }

extension DocumentVisibilityX on DocumentVisibility {
  String get label => switch (this) {
    DocumentVisibility.all => 'All Members',
    DocumentVisibility.adminOnly => 'Admins Only',
  };

  static DocumentVisibility fromName(String value) {
    return DocumentVisibility.values.firstWhere(
      (DocumentVisibility visibility) => visibility.name == value,
      orElse: () => DocumentVisibility.all,
    );
  }
}

enum DocumentExpiryUrgency { none, safe, warning, critical, expired }

class DocumentEntity extends Equatable {
  const DocumentEntity({
    required this.id,
    required this.householdId,
    required this.title,
    required this.docType,
    required this.folderPath,
    this.issuer,
    this.docDate,
    this.expiryDate,
    this.linkedAssetId,
    required this.localFilePath,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.visibility,
    required this.uploadedByUserId,
    required this.uploadedAt,
  });

  final String id;
  final String householdId;
  final String title;
  final DocumentType docType;
  final String folderPath;
  final String? issuer;
  final DateTime? docDate;
  final DateTime? expiryDate;
  final String? linkedAssetId;
  final String localFilePath;
  final int fileSizeBytes;
  final String mimeType;
  final DocumentVisibility visibility;
  final String uploadedByUserId;
  final DateTime uploadedAt;

  bool get isImage => mimeType == 'image/jpeg' || mimeType == 'image/png';
  bool get isPdf => mimeType == 'application/pdf';

  int? get daysUntilExpiry {
    final value = expiryDate;
    if (value == null) {
      return null;
    }
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    return target.difference(startOfToday).inDays;
  }

  DocumentExpiryUrgency get expiryUrgency {
    final days = daysUntilExpiry;
    if (days == null) {
      return DocumentExpiryUrgency.none;
    }
    if (days < 0) {
      return DocumentExpiryUrgency.expired;
    }
    if (days < 14) {
      return DocumentExpiryUrgency.critical;
    }
    if (days <= 60) {
      return DocumentExpiryUrgency.warning;
    }
    return DocumentExpiryUrgency.safe;
  }

  DocumentEntity copyWith({
    String? id,
    String? householdId,
    String? title,
    DocumentType? docType,
    String? folderPath,
    String? issuer,
    bool clearIssuer = false,
    DateTime? docDate,
    bool clearDocDate = false,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    String? linkedAssetId,
    bool clearLinkedAssetId = false,
    String? localFilePath,
    int? fileSizeBytes,
    String? mimeType,
    DocumentVisibility? visibility,
    String? uploadedByUserId,
    DateTime? uploadedAt,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      docType: docType ?? this.docType,
      folderPath: folderPath ?? this.folderPath,
      issuer: clearIssuer ? null : issuer ?? this.issuer,
      docDate: clearDocDate ? null : docDate ?? this.docDate,
      expiryDate: clearExpiryDate ? null : expiryDate ?? this.expiryDate,
      linkedAssetId: clearLinkedAssetId
          ? null
          : linkedAssetId ?? this.linkedAssetId,
      localFilePath: localFilePath ?? this.localFilePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      visibility: visibility ?? this.visibility,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    title,
    docType,
    folderPath,
    issuer,
    docDate,
    expiryDate,
    linkedAssetId,
    localFilePath,
    fileSizeBytes,
    mimeType,
    visibility,
    uploadedByUserId,
    uploadedAt,
  ];
}

class VaultFolderEntity extends Equatable {
  const VaultFolderEntity({
    required this.id,
    required this.householdId,
    required this.name,
    required this.parentFolderPath,
    required this.createdByUserId,
    required this.createdAt,
  });

  final String id;
  final String householdId;
  final String name;
  final String parentFolderPath;
  final String createdByUserId;
  final DateTime createdAt;

  String get fullPath => parentFolderPath == 'root'
      ? 'root/$id'
      : '$parentFolderPath/$id';

  VaultFolderEntity copyWith({
    String? id,
    String? householdId,
    String? name,
    String? parentFolderPath,
    String? createdByUserId,
    DateTime? createdAt,
  }) {
    return VaultFolderEntity(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      parentFolderPath: parentFolderPath ?? this.parentFolderPath,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    householdId,
    name,
    parentFolderPath,
    createdByUserId,
    createdAt,
  ];
}
