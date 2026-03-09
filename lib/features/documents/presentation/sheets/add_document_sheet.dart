import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/expiry_badge.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/presentation/document_notifier.dart';
import 'package:hearth/features/documents/presentation/screens/camera_scan_screen.dart';
import 'package:hearth/features/documents/presentation/widgets/document_expiry_badge_extensions.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

enum _AddDocumentStep { source, metadata }

Future<void> showAddDocumentSheet(
  BuildContext context, {
  String? documentId,
  DocumentEntity? initialDocument,
}) {
  return showHearthBottomSheet<void>(
    context: context,
    initialChildSize: 0.8,
    maxChildSize: 0.94,
    builder: (BuildContext context) {
      return AddDocumentSheet(
        documentId: documentId,
        initialDocument: initialDocument,
      );
    },
  );
}

class AddDocumentSheet extends ConsumerStatefulWidget {
  const AddDocumentSheet({this.documentId, this.initialDocument, super.key});

  final String? documentId;
  final DocumentEntity? initialDocument;

  @override
  ConsumerState<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends ConsumerState<AddDocumentSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _issuerController = TextEditingController();
  final TextEditingController _assetController = TextEditingController(
    text: 'Available in a future update',
  );

  final ImagePicker _imagePicker = ImagePicker();

  _AddDocumentStep _step = _AddDocumentStep.source;
  DocumentType _documentType = DocumentType.other;
  DocumentVisibility _visibility = DocumentVisibility.all;
  String _selectedFolderPath = 'root';
  DateTime? _documentDate;
  DateTime? _expiryDate;
  String? _sourcePath;
  bool _processingSource = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _issuerController.dispose();
    _assetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(documentNotifierProvider);
    final householdAsync = ref.watch(currentHouseholdProvider);
    final currentUserId = ref.watch(documentCurrentUserIdProvider);
    final foldersAsync = ref.watch(vaultFoldersProvider);
    final initialDocumentAsync = widget.initialDocument != null
        ? AsyncValue<DocumentEntity?>.data(widget.initialDocument)
        : widget.documentId == null
        ? const AsyncValue<DocumentEntity?>.data(null)
        : ref.watch(documentDetailProvider(widget.documentId!));

    return householdAsync.when(
      data: (household) => initialDocumentAsync.when(
        data: (DocumentEntity? initialDocument) {
          if (household == null || currentUserId == null) {
            return const SizedBox.shrink();
          }
          _initialize(initialDocument);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                initialDocument == null ? 'Add Document' : 'Update Document',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimaryFor(Theme.of(context).brightness),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                initialDocument == null
                    ? 'Capture, upload, and organize the records your household needs close at hand.'
                    : 'Adjust the metadata, folder, and protection settings for this vault item.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryFor(
                    Theme.of(context).brightness,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_step == _AddDocumentStep.source)
                _buildSourceStep(context)
              else
                _buildMetadataStep(
                  context: context,
                  actionState: actionState,
                  initialDocument: initialDocument,
                  householdId: household.id,
                  currentUserId: currentUserId,
                  foldersAsync: foldersAsync,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Text('$error'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, _) => Text('$error'),
    );
  }

  Widget _buildSourceStep(BuildContext context) {
    return Column(
      children: <Widget>[
        _SourceOptionCard(
          icon: HugeIcons.strokeRoundedCamera01,
          title: 'Camera Scan',
          subtitle: 'Capture with your camera',
          onTap: _processingSource ? null : () => _pickFromCamera(context),
        ),
        const SizedBox(height: AppSpacing.md),
        _SourceOptionCard(
          icon: HugeIcons.strokeRoundedImage01,
          title: 'Photo Library',
          subtitle: 'Choose from your photos',
          onTap: _processingSource ? null : _pickFromGallery,
        ),
        const SizedBox(height: AppSpacing.md),
        _SourceOptionCard(
          icon: HugeIcons.strokeRoundedUpload01,
          title: 'File Picker',
          subtitle: 'Upload a PDF or file',
          onTap: _processingSource ? null : _pickFromFiles,
        ),
        if (_processingSource) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _buildMetadataStep({
    required BuildContext context,
    required DocumentActionState actionState,
    required DocumentEntity? initialDocument,
    required String householdId,
    required String currentUserId,
    required AsyncValue<List<VaultFolderEntity>> foldersAsync,
  }) {
    final brightness = Theme.of(context).brightness;
    final previewDocument = initialDocument;
    final previewPath = _sourcePath ?? previewDocument?.localFilePath;
    final previewMimeType =
        previewDocument?.mimeType ?? _mimeTypeForPath(previewPath ?? '');
    final previewEntity =
        previewDocument ??
        DocumentEntity(
          id: 'preview',
          householdId: householdId,
          title: _titleController.text.isEmpty
              ? 'Preview'
              : _titleController.text,
          docType: _documentType,
          folderPath: _selectedFolderPath,
          localFilePath: previewPath ?? '',
          fileSizeBytes: 0,
          mimeType: previewMimeType,
          visibility: _visibility,
          uploadedByUserId: currentUserId,
          uploadedAt: DateTime.now(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: () => setState(() {
            _step = _AddDocumentStep.source;
          }),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                child: _DocumentPreviewThumbnail(
                  path: previewPath,
                  mimeType: previewMimeType,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Tap the preview to replace this file source.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        HearthTextField(label: 'Title', controller: _titleController),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Document Type',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSpacing.xxl,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              final type = DocumentType.values[index];
              return HearthChip(
                label: type.label,
                selected: type == _documentType,
                onTap: () {
                  setState(() {
                    _documentType = type;
                  });
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemCount: DocumentType.values.length,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Folder',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        foldersAsync.when(
          data: (List<VaultFolderEntity> folders) {
            final options = <({String label, String path})>[
              (label: 'Root', path: 'root'),
              ...folders.map(
                (VaultFolderEntity folder) =>
                    (label: folder.name, path: folder.fullPath),
              ),
            ];
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                ...options.map((option) {
                  return HearthChip(
                    label: option.label,
                    selected: _selectedFolderPath == option.path,
                    onTap: () {
                      setState(() {
                        _selectedFolderPath = option.path;
                      });
                    },
                  );
                }),
                HearthChip(
                  label: 'New Folder +',
                  selected: false,
                  onTap: () => _createNewFolder(householdId),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (Object error, _) => Text('$error'),
        ),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Issuer',
          controller: _issuerController,
          hintText: 'Who issued this document?',
        ),
        const SizedBox(height: AppSpacing.md),
        _DateSelectorRow(
          label: 'Document Date',
          value: _documentDate,
          onPressed: () => _pickDate(
            initial: _documentDate ?? DateTime.now(),
            onPicked: (DateTime value) {
              setState(() {
                _documentDate = value;
              });
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DateSelectorRow(
          label: 'Expiry Date',
          value: _expiryDate,
          onPressed: () => _pickDate(
            initial: _expiryDate ?? DateTime.now(),
            onPicked: (DateTime value) {
              setState(() {
                _expiryDate = value;
              });
            },
          ),
        ),
        if (_expiryDate != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ExpiryBadge(
            urgency: previewEntity
                .copyWith(expiryDate: _expiryDate)
                .expiryUrgency
                .badgeUrgency,
            daysUntil: previewEntity
                .copyWith(expiryDate: _expiryDate)
                .daysUntilExpiry,
            date: _expiryDate,
            size: ExpiryBadgeSize.large,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Visibility',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: HearthButton(
                label: 'All Members',
                variant: _visibility == DocumentVisibility.all
                    ? HearthButtonVariant.primary
                    : HearthButtonVariant.ghost,
                onPressed: () {
                  setState(() {
                    _visibility = DocumentVisibility.all;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: HearthButton(
                label: 'Admins Only',
                variant: _visibility == DocumentVisibility.adminOnly
                    ? HearthButtonVariant.secondary
                    : HearthButtonVariant.ghost,
                onPressed: () {
                  setState(() {
                    _visibility = DocumentVisibility.adminOnly;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Link to Asset',
          controller: _assetController,
          readOnly: true,
          suffix: Icon(
            HugeIcons.strokeRoundedLock,
            color: AppColors.textTertiaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'You will be able to link documents to appliances and assets in a coming update.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryFor(brightness),
          ),
        ),
        if (actionState.message != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            actionState.message!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.errorFor(brightness),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        HearthButton(
          label: initialDocument == null ? 'Save Document' : 'Update Document',
          isLoading: actionState.isLoading,
          onPressed: () => _saveDocument(
            initialDocument: initialDocument,
            householdId: householdId,
            currentUserId: currentUserId,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HearthButton(
          label: 'Cancel',
          variant: HearthButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  void _initialize(DocumentEntity? initialDocument) {
    if (_initialized) {
      return;
    }
    if (initialDocument != null) {
      _step = _AddDocumentStep.metadata;
      _titleController.text = initialDocument.title;
      _issuerController.text = initialDocument.issuer ?? '';
      _documentType = initialDocument.docType;
      _visibility = initialDocument.visibility;
      _selectedFolderPath = initialDocument.folderPath;
      _documentDate = initialDocument.docDate;
      _expiryDate = initialDocument.expiryDate;
      _sourcePath = initialDocument.localFilePath;
    }
    _initialized = true;
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final GoRouter router = GoRouter.of(context);
    await _setProcessingSource(true);
    try {
      if (!mounted) {
        return;
      }
      final result = await router.push<String>(CameraScanScreen.routePath);
      if (result != null && mounted) {
        setState(() {
          _sourcePath = result;
          _step = _AddDocumentStep.metadata;
        });
      }
    } finally {
      await _setProcessingSource(false);
    }
  }

  Future<void> _pickFromGallery() async {
    await _setProcessingSource(true);
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file != null && mounted) {
        setState(() {
          _sourcePath = file.path;
          _step = _AddDocumentStep.metadata;
        });
      }
    } finally {
      await _setProcessingSource(false);
    }
  }

  Future<void> _pickFromFiles() async {
    await _setProcessingSource(true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['pdf', 'jpg', 'jpeg', 'png'],
      );
      final path = result?.files.single.path;
      if (path != null && mounted) {
        setState(() {
          _sourcePath = path;
          _step = _AddDocumentStep.metadata;
        });
      }
    } finally {
      await _setProcessingSource(false);
    }
  }

  Future<void> _createNewFolder(String householdId) async {
    final controller = TextEditingController();
    final createdName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Folder'),
          content: TextField(controller: controller, autofocus: true),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    if (createdName == null || createdName.isEmpty) {
      return;
    }
    final folder = await ref
        .read(documentNotifierProvider.notifier)
        .createFolder(householdId: householdId, name: createdName);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedFolderPath = folder.fullPath;
    });
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _saveDocument({
    required DocumentEntity? initialDocument,
    required String householdId,
    required String currentUserId,
  }) async {
    final title = _titleController.text.trim();
    if (title.length < 2) {
      return;
    }
    if (initialDocument == null && _sourcePath == null) {
      return;
    }

    final fallbackPath = initialDocument?.localFilePath ?? _sourcePath ?? '';
    final file = File(fallbackPath);
    final fileSize = file.existsSync()
        ? file.lengthSync()
        : (initialDocument?.fileSizeBytes ?? 0);
    final document = ref
        .read(documentNotifierProvider.notifier)
        .draftDocument(
          id: initialDocument?.id,
          householdId: householdId,
          title: title,
          docType: _documentType,
          folderPath: _selectedFolderPath,
          issuer: _issuerController.text,
          docDate: _documentDate,
          expiryDate: _expiryDate,
          linkedAssetId: null,
          localFilePath: fallbackPath,
          fileSizeBytes: fileSize,
          mimeType: _mimeTypeForPath(fallbackPath),
          visibility: _visibility,
          uploadedByUserId: initialDocument?.uploadedByUserId ?? currentUserId,
          uploadedAt: initialDocument?.uploadedAt,
        );
    try {
      if (initialDocument == null) {
        await ref
            .read(documentNotifierProvider.notifier)
            .saveDocument(document: document, sourceFile: File(_sourcePath!));
      } else {
        final replacementPath =
            _sourcePath != null && _sourcePath != initialDocument.localFilePath
            ? _sourcePath
            : null;
        await ref
            .read(documentNotifierProvider.notifier)
            .updateDocument(
              document: document,
              replacementSourceFile: replacementPath == null
                  ? null
                  : File(replacementPath),
            );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on StateError {
      return;
    }
  }

  Future<void> _setProcessingSource(bool value) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _processingSource = value;
    });
  }

  String _mimeTypeForPath(String value) {
    final normalized = value.toLowerCase();
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.pdf')) {
      return 'application/pdf';
    }
    return 'application/octet-stream';
  }
}

class _SourceOptionCard extends StatelessWidget {
  const _SourceOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(HugeIcons.strokeRoundedArrowRight01),
        ],
      ),
    );
  }
}

class _DocumentPreviewThumbnail extends StatelessWidget {
  const _DocumentPreviewThumbnail({required this.path, required this.mimeType});

  final String? path;
  final String mimeType;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (path != null &&
        (mimeType == 'image/jpeg' || mimeType == 'image/png') &&
        File(path!).existsSync()) {
      return Image.file(File(path!), width: 80, height: 80, fit: BoxFit.cover);
    }
    return Container(
      width: 80,
      height: 80,
      color: AppColors.primaryContainerFor(brightness),
      child: Icon(
        mimeType == 'application/pdf'
            ? HugeIcons.strokeRoundedPdf01
            : HugeIcons.strokeRoundedFile01,
        color: AppColors.primaryFor(brightness),
      ),
    );
  }
}

class _DateSelectorRow extends StatelessWidget {
  const _DateSelectorRow({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryFor(Theme.of(context).brightness),
            ),
          ),
        ),
        HearthButton(
          label: value == null
              ? 'Set date'
              : '${value!.day}/${value!.month}/${value!.year}',
          expanded: false,
          variant: HearthButtonVariant.ghost,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
