import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/animated/hearth_celebration.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/expiry_badge.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_progress_bar.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/presentation/document_notifier.dart';
import 'package:hearth/features/documents/presentation/screens/expiry_timeline_screen.dart';
import 'package:hearth/features/documents/presentation/screens/folder_screen.dart';
import 'package:hearth/features/documents/presentation/vault_lock_provider.dart';
import 'package:hearth/features/documents/presentation/widgets/document_card.dart';
import 'package:hearth/features/documents/presentation/widgets/document_expiry_badge_extensions.dart';
import 'package:hearth/features/documents/presentation/widgets/folder_card.dart';
import 'package:hearth/features/documents/presentation/widgets/vault_lock_overlay.dart';
import 'package:hugeicons/hugeicons.dart';

class VaultDashboardScreen extends ConsumerStatefulWidget {
  const VaultDashboardScreen({super.key});

  static const String routePath = '/documents';

  @override
  ConsumerState<VaultDashboardScreen> createState() =>
      _VaultDashboardScreenState();
}

class _VaultDashboardScreenState extends ConsumerState<VaultDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  ProviderSubscription<DocumentActionState>? _actionSubscription;
  String? _highlightedDocumentId;
  bool _showCelebration = false;
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _actionSubscription = ref.listenManual<DocumentActionState>(
      documentNotifierProvider,
      (DocumentActionState? previous, DocumentActionState next) {
        if (!mounted) {
          return;
        }
        if (next.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.message!)));
          ref.read(documentNotifierProvider.notifier).clearMessage();
        }
        if (next.lastSavedDocumentId != null) {
          setState(() {
            _highlightedDocumentId = next.lastSavedDocumentId;
            _showCelebration = next.firstDocumentCreated;
          });
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 900), () {
              if (mounted) {
                setState(() {
                  _highlightedDocumentId = null;
                });
              }
            }),
          );
          if (next.firstDocumentCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your vault is open!')),
            );
          }
          ref.read(documentNotifierProvider.notifier).clearTransientState();
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(vaultLockProvider) == VaultLockState.locked) {
        ref.read(vaultLockProvider.notifier).requestUnlock();
      }
    });
  }

  @override
  void dispose() {
    _actionSubscription?.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final documentsAsync = ref.watch(allDocumentsProvider);
    final foldersAsync = ref.watch(vaultFoldersProvider);
    final expiringAsync = ref.watch(expiringDocumentsProvider);
    final householdId = ref.watch(documentHouseholdIdProvider);
    final searchResultsAsync = ref.watch(documentSearchProvider);
    final showSearchResults =
        _searchOpen && _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ref.read(vaultLockProvider.notifier).lock(),
          icon: const Icon(HugeIcons.strokeRoundedLock),
        ),
        title: _searchOpen
            ? Container(
                height: AppSpacing.xxl,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantFor(brightness),
                  borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    Icon(
                      HugeIcons.strokeRoundedSearch01,
                      size: 20,
                      color: AppColors.textTertiaryFor(brightness),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search documents',
                          border: InputBorder.none,
                        ),
                        onChanged: (String value) {
                          if (householdId == null) {
                            return;
                          }
                          ref
                              .read(documentSearchProvider.notifier)
                              .search(householdId: householdId, query: value);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              )
            : Text(
                'Document Vault',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimaryFor(brightness),
                ),
              ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchController.clear();
                  ref.read(documentSearchProvider.notifier).clear();
                }
              });
            },
            icon: Icon(
              _searchOpen
                  ? HugeIcons.strokeRoundedCancel01
                  : HugeIcons.strokeRoundedSearch01,
            ),
          ),
        ],
      ),
      body: VaultLockOverlay(
        child: Stack(
          children: <Widget>[
            documentsAsync.when(
              data: (List<DocumentEntity> documents) {
                final totalBytes = documents.fold<int>(
                  0,
                  (int total, DocumentEntity document) =>
                      total + document.fileSizeBytes,
                );
                final recentDocuments = documents.take(5).toList();
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: <Widget>[
                    HearthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          HearthProgressBar(
                            progress: totalBytes / (1024 * 1024 * 1024),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${documents.length} documents · ${AppFormatters.fileSize(totalBytes)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryFor(brightness),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (showSearchResults)
                      _SearchResultsSection(
                        resultsAsync: searchResultsAsync,
                        highlightedDocumentId: _highlightedDocumentId,
                      )
                    else ...<Widget>[
                      expiringAsync.when(
                        data: (List<DocumentEntity> expiring) {
                          if (expiring.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              HearthSectionHeader(
                                title: 'Expiring Soon',
                                subtitle: 'Documents within the next 60 days.',
                                actionLabel: 'See All',
                                onActionPressed: () => context.push(
                                  ExpiryTimelineScreen.routePath,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                height: 118,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: expiring.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: AppSpacing.md),
                                  itemBuilder: (BuildContext context, int index) {
                                    final document = expiring[index];
                                    return HearthListItemEntry(
                                      index: index,
                                      child: SizedBox(
                                        width: 220,
                                        child: HearthCard(
                                          onTap: () => context.push(
                                            '${VaultDashboardScreen.routePath}/${document.id}',
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              ExpiryBadge(
                                                urgency: document
                                                    .expiryUrgency
                                                    .badgeUrgency,
                                                daysUntil:
                                                    document.daysUntilExpiry,
                                                date: document.expiryDate,
                                                size: ExpiryBadgeSize.large,
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.md,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      document.title,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTextStyles
                                                          .titleMedium
                                                          .copyWith(
                                                            color:
                                                                AppColors.textPrimaryFor(
                                                                  brightness,
                                                                ),
                                                          ),
                                                    ),
                                                    const SizedBox(
                                                      height: AppSpacing.xs,
                                                    ),
                                                    Text(
                                                      document.docType.label,
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                            color:
                                                                AppColors.textSecondaryFor(
                                                                  brightness,
                                                                ),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (Object error, _) => Text('$error'),
                      ),
                      HearthSectionHeader(
                        title: 'Folders',
                        subtitle: 'Organize your household records.',
                        actionLabel: 'New Folder',
                        onActionPressed: householdId == null
                            ? null
                            : () => _promptCreateFolder(householdId),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      foldersAsync.when(
                        data: (List<VaultFolderEntity> folders) {
                          if (folders.isEmpty) {
                            return Text(
                              'Create a folder or keep everything in Root.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondaryFor(brightness),
                              ),
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: folders.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                  childAspectRatio: 1.18,
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              final folder = folders[index];
                              return HearthListItemEntry(
                                index: index,
                                child: FolderCard(
                                  folder: folder,
                                  onTap: () => context.push(
                                    FolderScreen.routeForPath(folder.fullPath),
                                  ),
                                  onLongPress: () => _showFolderActions(folder),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (Object error, _) => Text('$error'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      HearthSectionHeader(
                        title: 'Recent Documents',
                        subtitle: 'The latest uploads in your vault.',
                        actionLabel: 'See All',
                        onActionPressed: () =>
                            context.push(FolderScreen.routeForPath('root')),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...List<Widget>.generate(recentDocuments.length, (
                        int index,
                      ) {
                        final document = recentDocuments[index];
                        return HearthListItemEntry(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: HearthSwipeToAction(
                              trailingAction: HearthSwipeAction(
                                icon: HugeIcons.strokeRoundedDelete02,
                                label: 'Delete',
                                color: AppColors.errorFor(brightness),
                                onTriggered: () =>
                                    _confirmDeleteDocument(document),
                              ),
                              child: DocumentCard(
                                document: document,
                                variant: DocumentCardVariant.list,
                                highlightOnEntry:
                                    _highlightedDocumentId == document.id,
                                onTap: () => context.push(
                                  '${VaultDashboardScreen.routePath}/${document.id}',
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, _) => Center(child: Text('$error')),
            ),
            if (_showCelebration)
              Positioned.fill(
                child: HearthCelebration(
                  onCompleted: () {
                    if (mounted) {
                      setState(() {
                        _showCelebration = false;
                      });
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptCreateFolder(String householdId) async {
    final controller = TextEditingController();
    final folderName = await showDialog<String>(
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
    if (folderName == null || folderName.isEmpty) {
      return;
    }
    try {
      await ref
          .read(documentNotifierProvider.notifier)
          .createFolder(householdId: householdId, name: folderName);
    } on StateError {
      return;
    }
  }

  Future<void> _showFolderActions(VaultFolderEntity folder) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedEdit02),
                title: const Text('Rename'),
                onTap: () => Navigator.of(context).pop('rename'),
              ),
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedDelete02),
                title: const Text('Delete'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || selection == null) {
      return;
    }
    if (selection == 'rename') {
      final controller = TextEditingController(text: folder.name);
      final updatedName = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Rename Folder'),
            content: TextField(controller: controller, autofocus: true),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      if (updatedName == null || updatedName.isEmpty) {
        return;
      }
      await ref
          .read(documentNotifierProvider.notifier)
          .renameFolder(
            folderId: folder.id,
            householdId: folder.householdId,
            name: updatedName,
          );
      return;
    }
    await ref
        .read(documentNotifierProvider.notifier)
        .deleteFolder(folder.id, folder.householdId);
  }

  Future<void> _confirmDeleteDocument(DocumentEntity document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete document?'),
          content: Text(
            'This will remove ${document.title} from the vault and delete the local file.',
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
    } on StateError {
      return;
    }
  }
}

class _SearchResultsSection extends StatelessWidget {
  const _SearchResultsSection({
    required this.resultsAsync,
    required this.highlightedDocumentId,
  });

  final AsyncValue<List<DocumentEntity>> resultsAsync;
  final String? highlightedDocumentId;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return resultsAsync.when(
      data: (List<DocumentEntity> results) {
        if (results.isEmpty) {
          return Text(
            'No matches yet. Try a title or issuer.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryFor(brightness),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Search Results',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimaryFor(brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...List<Widget>.generate(results.length, (int index) {
              final document = results[index];
              return HearthListItemEntry(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: DocumentCard(
                    document: document,
                    variant: DocumentCardVariant.list,
                    highlightOnEntry: highlightedDocumentId == document.id,
                    onTap: () => context.push(
                      '${VaultDashboardScreen.routePath}/${document.id}',
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, _) => Text('$error'),
    );
  }
}
