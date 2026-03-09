import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/expiry_badge.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/presentation/document_notifier.dart';
import 'package:hearth/features/documents/presentation/sheets/add_document_sheet.dart';
import 'package:hearth/features/documents/presentation/widgets/document_expiry_badge_extensions.dart';
import 'package:hearth/features/documents/presentation/widgets/vault_lock_overlay.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  const DocumentDetailScreen({required this.documentId, super.key});

  final String documentId;

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  int _currentPage = 1;
  int _pageCount = 1;
  String? _pdfError;

  @override
  Widget build(BuildContext context) {
    final documentAsync = ref.watch(documentDetailProvider(widget.documentId));
    final foldersAsync = ref.watch(vaultFoldersProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final roleAsync = ref.watch(currentHouseholdRoleProvider);
    final currentUserId = ref.watch(documentCurrentUserIdProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: documentAsync.when(
          data: (DocumentEntity? document) => Text(
            document?.title ?? 'Document',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          loading: () => Text(
            'Document',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          error: (_, __) => Text(
            'Document',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
        ),
        actions: <Widget>[
          documentAsync.when(
            data: (DocumentEntity? document) {
              if (document == null) {
                return const SizedBox.shrink();
              }
              final canEdit =
                  document.uploadedByUserId == currentUserId ||
                  roleAsync.valueOrNull == HouseholdRole.admin;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (canEdit)
                    IconButton(
                      onPressed: () => showAddDocumentSheet(
                        context,
                        initialDocument: document,
                      ),
                      icon: const Icon(HugeIcons.strokeRoundedEdit02),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(HugeIcons.strokeRoundedMoreVertical),
                    onSelected: (String value) {
                      if (value == 'share') {
                        _shareDocument(document);
                      } else if (value == 'delete') {
                        _confirmDelete(document);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'share',
                            child: Text('Share'),
                          ),
                          if (canEdit)
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                        ],
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: VaultLockOverlay(
        child: documentAsync.when(
          data: (DocumentEntity? document) {
            if (document == null) {
              return const Center(child: Text('Document not found.'));
            }
            final uploadedByName =
                membersAsync.valueOrNull
                    ?.where(
                      (HouseholdMember member) =>
                          member.userId == document.uploadedByUserId,
                    )
                    .map((HouseholdMember member) => member.displayName)
                    .firstWhere(
                      (_) => true,
                      orElse: () => 'Household member',
                    ) ??
                'Household member';
            final folderName = document.folderPath == 'root'
                ? 'Root'
                : foldersAsync.valueOrNull
                          ?.where(
                            (VaultFolderEntity folder) =>
                                folder.fullPath == document.folderPath,
                          )
                          .map((VaultFolderEntity folder) => folder.name)
                          .firstWhere((_) => true, orElse: () => 'Folder') ??
                      'Folder';
            final canEdit =
                document.uploadedByUserId == currentUserId ||
                roleAsync.valueOrNull == HouseholdRole.admin;
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final previewHeight = constraints.maxHeight * 0.55;
                return Column(
                  children: <Widget>[
                    SizedBox(
                      height: previewHeight,
                      child: _buildPreview(document),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: <Widget>[
                            HearthCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainerFor(
                                        brightness,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.radiusFull,
                                      ),
                                    ),
                                    child: Text(
                                      document.docType.label,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.primaryFor(brightness),
                                      ),
                                    ),
                                  ),
                                  if (document.issuer != null) ...<Widget>[
                                    const SizedBox(height: AppSpacing.md),
                                    _MetadataRow(
                                      icon: HugeIcons
                                          .strokeRoundedDocumentValidation,
                                      label: 'Issuer',
                                      value: document.issuer!,
                                    ),
                                  ],
                                  if (document.docDate != null) ...<Widget>[
                                    const SizedBox(height: AppSpacing.md),
                                    _MetadataRow(
                                      icon: HugeIcons.strokeRoundedCalendar01,
                                      label: 'Document date',
                                      value: AppFormatters.shortDate(
                                        document.docDate!,
                                      ),
                                    ),
                                  ],
                                  if (document.expiryDate != null) ...<Widget>[
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: <Widget>[
                                        const Icon(
                                          HugeIcons.strokeRoundedCalendar01,
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                'Expiry',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color:
                                                          AppColors.textSecondaryFor(
                                                            brightness,
                                                          ),
                                                    ),
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              ExpiryBadge(
                                                urgency: document
                                                    .expiryUrgency
                                                    .badgeUrgency,
                                                daysUntil:
                                                    document.daysUntilExpiry,
                                                date: document.expiryDate,
                                                size: ExpiryBadgeSize.large,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.md),
                                  _MetadataRow(
                                    icon: HugeIcons.strokeRoundedFolder01,
                                    label: 'Folder',
                                    value: folderName,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: <Widget>[
                                      HearthAvatar(
                                        displayName: uploadedByName,
                                        size: 24,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              'Uploaded by',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondaryFor(
                                                          brightness,
                                                        ),
                                                  ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.xs,
                                            ),
                                            Text(
                                              '$uploadedByName • ${AppFormatters.shortDate(document.uploadedAt)}',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    color:
                                                        AppColors.textPrimaryFor(
                                                          brightness,
                                                        ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _MetadataRow(
                                    icon: HugeIcons.strokeRoundedFile01,
                                    label: 'File size',
                                    value: AppFormatters.fileSize(
                                      document.fileSizeBytes,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _MetadataRow(
                                    icon: HugeIcons.strokeRoundedLock,
                                    label: 'Linked Asset',
                                    value: document.linkedAssetId == null
                                        ? 'Not linked'
                                        : document.linkedAssetId!,
                                    subdued: document.linkedAssetId == null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (document.isPdf)
                              HearthButton(
                                label: 'Open Full Screen',
                                icon: const Icon(HugeIcons.strokeRoundedPdf01),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (BuildContext context) {
                                        return _FullScreenPdfView(
                                          title: document.title,
                                          path: document.localFilePath,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            if (canEdit) ...<Widget>[
                              const SizedBox(height: AppSpacing.sm),
                              HearthButton(
                                label: 'Edit',
                                variant: HearthButtonVariant.ghost,
                                onPressed: () => showAddDocumentSheet(
                                  context,
                                  initialDocument: document,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              HearthButton(
                                label: 'Delete',
                                variant: HearthButtonVariant.destructive,
                                onPressed: () => _confirmDelete(document),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => Center(child: Text('$error')),
        ),
      ),
    );
  }

  Widget _buildPreview(DocumentEntity document) {
    final file = File(document.localFilePath);
    if (!file.existsSync()) {
      return const Center(child: _MissingFileState());
    }
    if (document.isPdf) {
      if (_pdfError != null) {
        return const _MissingFileState();
      }
      return Stack(
        children: <Widget>[
          PDFView(
            filePath: document.localFilePath,
            enableSwipe: true,
            swipeHorizontal: false,
            onRender: (int? pages) {
              if (!mounted) {
                return;
              }
              setState(() {
                _pageCount = pages ?? 1;
              });
            },
            onPageChanged: (int? current, int? total) {
              HapticFeedback.lightImpact();
              if (!mounted) {
                return;
              }
              setState(() {
                _currentPage = (current ?? 0) + 1;
                _pageCount = total ?? _pageCount;
              });
            },
            onError: (dynamic error) {
              if (!mounted) {
                return;
              }
              setState(() {
                _pdfError = '$error';
              });
            },
            onPageError: (int? page, dynamic error) {
              if (!mounted) {
                return;
              }
              setState(() {
                _pdfError = '$error';
              });
            },
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.overlay,
                  borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    HearthNumberTicker(
                      value: '$_currentPage',
                      style: AppTextStyles.numericSmall.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                    Text(
                      ' / $_pageCount',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Hero(
      tag: 'document_preview_${document.id}',
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Image.file(file, width: double.infinity, fit: BoxFit.contain),
      ),
    );
  }

  Future<void> _shareDocument(DocumentEntity document) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(document.localFilePath)],
        text: document.title,
        subject: document.title,
      ),
    );
  }

  Future<void> _confirmDelete(DocumentEntity document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete document?'),
          content: const Text(
            'This removes the record from the vault and deletes the local file.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref
          .read(documentNotifierProvider.notifier)
          .deleteDocument(document);
      if (mounted) {
        context.pop();
      }
    } on StateError {
      return;
    }
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subdued = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: AppColors.textSecondaryFor(brightness)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryFor(brightness),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: subdued
                      ? AppColors.textTertiaryFor(brightness)
                      : AppColors.textPrimaryFor(brightness),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissingFileState extends StatelessWidget {
  const _MissingFileState();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          HugeIcons.strokeRoundedImageNotFound01,
          size: 36,
          color: AppColors.errorFor(brightness),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'File not found on this device',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
      ],
    );
  }
}

class _FullScreenPdfView extends StatefulWidget {
  const _FullScreenPdfView({required this.title, required this.path});

  final String title;
  final String path;

  @override
  State<_FullScreenPdfView> createState() => _FullScreenPdfViewState();
}

class _FullScreenPdfViewState extends State<_FullScreenPdfView> {
  int _currentPage = 1;
  int _pageCount = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.path,
            onRender: (int? pages) {
              setState(() {
                _pageCount = pages ?? 1;
              });
            },
            onPageChanged: (int? current, int? total) {
              HapticFeedback.lightImpact();
              setState(() {
                _currentPage = (current ?? 0) + 1;
                _pageCount = total ?? _pageCount;
              });
            },
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.overlay,
                  borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                ),
                child: Text(
                  '$_currentPage / $_pageCount',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
