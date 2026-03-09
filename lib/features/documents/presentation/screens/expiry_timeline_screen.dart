import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/presentation/document_notifier.dart';
import 'package:hearth/features/documents/presentation/widgets/document_card.dart';
import 'package:hearth/features/documents/presentation/widgets/vault_lock_overlay.dart';
import 'package:hugeicons/hugeicons.dart';

enum _ExpiryFilter { all, expired, critical, warning, safe }

class ExpiryTimelineScreen extends ConsumerStatefulWidget {
  const ExpiryTimelineScreen({super.key});

  static const String routePath = '/documents/expiry';

  @override
  ConsumerState<ExpiryTimelineScreen> createState() =>
      _ExpiryTimelineScreenState();
}

class _ExpiryTimelineScreenState extends ConsumerState<ExpiryTimelineScreen> {
  _ExpiryFilter _filter = _ExpiryFilter.all;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final documentsAsync = ref.watch(allDocumentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Expiry Timeline',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimaryFor(brightness),
              ),
            ),
            Text(
              'Documents approaching expiry',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
          ],
        ),
      ),
      body: VaultLockOverlay(
        child: documentsAsync.when(
          data: (List<DocumentEntity> documents) {
            final filtered = _filteredDocuments(documents);
            if (filtered.isEmpty) {
              return const HearthEmptyState(
                icon: HugeIcons.strokeRoundedCalendar01,
                title: 'No expiry dates tracked',
                body:
                    'When you add documents with expiry dates, they will appear here.',
              );
            }
            final grouped = _groupDocuments(filtered);
            var index = 0;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                SizedBox(
                  height: AppSpacing.xxl,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      _FilterChip(
                        label: 'All',
                        selected: _filter == _ExpiryFilter.all,
                        onTap: () => setState(() => _filter = _ExpiryFilter.all),
                      ),
                      _FilterChip(
                        label: 'Expired',
                        selected: _filter == _ExpiryFilter.expired,
                        onTap: () =>
                            setState(() => _filter = _ExpiryFilter.expired),
                      ),
                      _FilterChip(
                        label: 'Critical',
                        selected: _filter == _ExpiryFilter.critical,
                        onTap: () =>
                            setState(() => _filter = _ExpiryFilter.critical),
                      ),
                      _FilterChip(
                        label: 'Warning',
                        selected: _filter == _ExpiryFilter.warning,
                        onTap: () =>
                            setState(() => _filter = _ExpiryFilter.warning),
                      ),
                      _FilterChip(
                        label: 'Safe',
                        selected: _filter == _ExpiryFilter.safe,
                        onTap: () => setState(() => _filter = _ExpiryFilter.safe),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...grouped.entries.expand((MapEntry<String, List<DocumentEntity>> entry) {
                  final children = <Widget>[
                    HearthSectionHeader(title: entry.key),
                    const SizedBox(height: AppSpacing.sm),
                  ];
                  for (final document in entry.value) {
                    children.add(
                      HearthListItemEntry(
                        index: index++,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: HearthSwipeToAction(
                            trailingAction: HearthSwipeAction(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              label: 'Open',
                              color: AppColors.primaryFor(brightness),
                              onTriggered: () =>
                                  context.push('/documents/${document.id}'),
                            ),
                            child: DocumentCard(
                              document: document,
                              variant: DocumentCardVariant.list,
                              pulseCriticalExpiry: true,
                              onTap: () => context.push('/documents/${document.id}'),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return children;
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => Center(child: Text('$error')),
        ),
      ),
    );
  }

  List<DocumentEntity> _filteredDocuments(List<DocumentEntity> documents) {
    final filtered = documents
        .where((DocumentEntity document) => document.expiryDate != null)
        .toList()
      ..sort((DocumentEntity left, DocumentEntity right) {
        final leftDate = left.expiryDate;
        final rightDate = right.expiryDate;
        if (leftDate == null && rightDate == null) {
          return left.title.compareTo(right.title);
        }
        if (leftDate == null) {
          return 1;
        }
        if (rightDate == null) {
          return -1;
        }
        return leftDate.compareTo(rightDate);
      });
    return filtered.where((DocumentEntity document) {
      return switch (_filter) {
        _ExpiryFilter.all => true,
        _ExpiryFilter.expired =>
          document.expiryUrgency == DocumentExpiryUrgency.expired,
        _ExpiryFilter.critical =>
          document.expiryUrgency == DocumentExpiryUrgency.critical,
        _ExpiryFilter.warning =>
          document.expiryUrgency == DocumentExpiryUrgency.warning,
        _ExpiryFilter.safe =>
          document.expiryUrgency == DocumentExpiryUrgency.safe,
      };
    }).toList();
  }

  Map<String, List<DocumentEntity>> _groupDocuments(List<DocumentEntity> docs) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final inTwoMonths = DateTime(now.year, now.month + 2, 0);
    final groups = <String, List<DocumentEntity>>{};
    for (final document in docs) {
      final expiryDate = document.expiryDate;
      final key = expiryDate == null
          ? 'Later'
          : expiryDate.isBefore(now)
              ? 'Expired'
              : expiryDate.isBefore(endOfMonth) ||
                      expiryDate.isAtSameMomentAs(endOfMonth)
                  ? 'This Month'
                  : expiryDate.isBefore(inTwoMonths) ||
                          expiryDate.isAtSameMomentAs(inTwoMonths)
                      ? 'Next 2 Months'
                      : 'Later';
      groups.putIfAbsent(key, () => <DocumentEntity>[]).add(document);
    }
    return groups;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: HearthChip(label: label, selected: selected, onTap: onTap),
    );
  }
}
