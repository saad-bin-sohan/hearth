import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/presentation/document_notifier.dart';
import 'package:hearth/features/documents/presentation/sheets/add_document_sheet.dart';
import 'package:hearth/features/documents/presentation/widgets/document_card.dart';
import 'package:hearth/features/documents/presentation/widgets/vault_lock_overlay.dart';
import 'package:hugeicons/hugeicons.dart';

enum _FolderSort { dateDesc, nameAsc, sizeDesc }

class FolderScreen extends ConsumerStatefulWidget {
  const FolderScreen({required this.folderPath, super.key});

  final String folderPath;

  static String routeForPath(String folderPath) {
    return '/documents/folder/${Uri.encodeComponent(folderPath)}';
  }

  @override
  ConsumerState<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends ConsumerState<FolderScreen> {
  bool _gridMode = true;
  _FolderSort _sort = _FolderSort.dateDesc;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foldersAsync = ref.watch(vaultFoldersProvider);
    final documentsAsync = widget.folderPath == 'root'
        ? ref.watch(allDocumentsProvider)
        : ref.watch(documentsInFolderProvider(widget.folderPath));

    return Scaffold(
      appBar: AppBar(
        title: foldersAsync.when(
          data: (List<VaultFolderEntity> folders) {
            var folderName = 'Folder';
            if (widget.folderPath == 'root') {
              folderName = 'All Documents';
            } else {
              for (final folder in folders) {
                if (folder.fullPath == widget.folderPath) {
                  folderName = folder.name;
                  break;
                }
              }
            }
            return Text(
              folderName,
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimaryFor(brightness),
              ),
            );
          },
          loading: () => Text(
            'Loading…',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          error: (_, __) => Text(
            'Folder',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<_FolderSort>(
            icon: const Icon(HugeIcons.strokeRoundedSortByDown01),
            onSelected: (_FolderSort value) {
              setState(() {
                _sort = value;
              });
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<_FolderSort>>[
              PopupMenuItem<_FolderSort>(
                value: _FolderSort.dateDesc,
                child: Text('Newest first'),
              ),
              PopupMenuItem<_FolderSort>(
                value: _FolderSort.nameAsc,
                child: Text('Name A-Z'),
              ),
              PopupMenuItem<_FolderSort>(
                value: _FolderSort.sizeDesc,
                child: Text('Largest first'),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _gridMode = !_gridMode;
              });
            },
            icon: Icon(
              _gridMode
                  ? HugeIcons.strokeRoundedListView
                  : HugeIcons.strokeRoundedGridView,
            ),
          ),
        ],
      ),
      body: VaultLockOverlay(
        child: documentsAsync.when(
          data: (List<DocumentEntity> documents) {
            final sorted = _sortDocuments(documents);
            if (sorted.isEmpty) {
              return HearthEmptyState(
                icon: HugeIcons.strokeRoundedFile01,
                title: 'No documents yet',
                body: 'Tap + to scan or upload your first document.',
                ctaLabel: 'Add Document',
                onCtaPressed: () => showAddDocumentSheet(context),
              );
            }
            if (_gridMode) {
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: sorted.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.83,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final document = sorted[index];
                  return HearthListItemEntry(
                    index: index,
                    child: DocumentCard(
                      document: document,
                      onTap: () => context.push('/documents/${document.id}'),
                    ),
                  );
                },
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: sorted.length,
              itemBuilder: (BuildContext context, int index) {
                final document = sorted[index];
                return HearthListItemEntry(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: HearthSwipeToAction(
                      trailingAction: HearthSwipeAction(
                        icon: HugeIcons.strokeRoundedDelete02,
                        label: 'Delete',
                        color: AppColors.errorFor(brightness),
                        onTriggered: () => _deleteDocument(document),
                      ),
                      child: DocumentCard(
                        document: document,
                        variant: DocumentCardVariant.list,
                        onTap: () => context.push('/documents/${document.id}'),
                      ),
                    ),
                  ),
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

  List<DocumentEntity> _sortDocuments(List<DocumentEntity> documents) {
    final sorted = List<DocumentEntity>.from(documents);
    sorted.sort((DocumentEntity left, DocumentEntity right) {
      switch (_sort) {
        case _FolderSort.dateDesc:
          return right.uploadedAt.compareTo(left.uploadedAt);
        case _FolderSort.nameAsc:
          return left.title.toLowerCase().compareTo(right.title.toLowerCase());
        case _FolderSort.sizeDesc:
          return right.fileSizeBytes.compareTo(left.fileSizeBytes);
      }
    });
    return sorted;
  }

  Future<void> _deleteDocument(DocumentEntity document) async {
    try {
      await ref.read(documentNotifierProvider.notifier).deleteDocument(document);
    } on StateError {
      return;
    }
  }
}
