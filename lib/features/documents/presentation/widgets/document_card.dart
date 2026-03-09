import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/documents/domain/document_models.dart';
import 'package:hearth/features/documents/presentation/widgets/expiry_badge.dart';
import 'package:hugeicons/hugeicons.dart';

enum DocumentCardVariant { grid, list }

class DocumentCard extends StatefulWidget {
  const DocumentCard({
    required this.document,
    required this.onTap,
    this.variant = DocumentCardVariant.grid,
    this.highlightOnEntry = false,
    this.pulseCriticalExpiry = false,
    super.key,
  });

  final DocumentEntity document;
  final VoidCallback onTap;
  final DocumentCardVariant variant;
  final bool highlightOnEntry;
  final bool pulseCriticalExpiry;

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
      value: widget.highlightOnEntry ? 0 : 1,
    );
    if (widget.highlightOnEntry) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant DocumentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.highlightOnEntry && widget.highlightOnEntry) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final scale = widget.highlightOnEntry
            ? 0.8 + (_controller.value * 0.2)
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: switch (widget.variant) {
        DocumentCardVariant.grid => _GridDocumentCard(
            document: widget.document,
            onTap: widget.onTap,
          ),
        DocumentCardVariant.list => _ListDocumentCard(
            document: widget.document,
            onTap: widget.onTap,
            pulseCriticalExpiry: widget.pulseCriticalExpiry,
          ),
      },
    );
  }
}

class _GridDocumentCard extends StatelessWidget {
  const _GridDocumentCard({required this.document, required this.onTap});

  final DocumentEntity document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return HearthCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Hero(
                tag: 'document_preview_${document.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.radiusMd),
                  ),
                  child: _DocumentThumbnail(
                    document: document,
                    height: 116,
                    width: double.infinity,
                  ),
                ),
              ),
              if (document.expiryUrgency != DocumentExpiryUrgency.none)
                const Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: SizedBox.shrink(),
                ),
              if (document.expiryUrgency != DocumentExpiryUrgency.none)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: ExpiryBadge(
                    document: document,
                    size: ExpiryBadgeSize.compact,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _TypeChip(document: document),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  document.docDate == null
                      ? 'No date'
                      : AppFormatters.shortDate(document.docDate!),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiaryFor(brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListDocumentCard extends StatelessWidget {
  const _ListDocumentCard({
    required this.document,
    required this.onTap,
    required this.pulseCriticalExpiry,
  });

  final DocumentEntity document;
  final VoidCallback onTap;
  final bool pulseCriticalExpiry;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return HearthCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Hero(
            tag: 'document_preview_${document.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              child: _DocumentThumbnail(
                document: document,
                height: AppSpacing.xxl + AppSpacing.sm,
                width: AppSpacing.xxl + AppSpacing.sm,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    document.docType.label,
                    if (document.issuer != null && document.issuer!.isNotEmpty)
                      document.issuer!,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  document.docDate == null
                      ? 'Added ${AppFormatters.shortDate(document.uploadedAt)}'
                      : AppFormatters.shortDate(document.docDate!),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiaryFor(brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (document.expiryUrgency != DocumentExpiryUrgency.none)
            ExpiryBadge(document: document, pulse: pulseCriticalExpiry)
          else
            Text(
              AppFormatters.fileSize(document.fileSizeBytes),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiaryFor(brightness),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({
    required this.document,
    required this.height,
    required this.width,
  });

  final DocumentEntity document;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final file = File(document.localFilePath);
    if (document.isImage && file.existsSync()) {
      return Image.file(
        file,
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    }
    if (document.isPdf) {
      return Container(
        height: height,
        width: width,
        color: AppColors.primaryContainerFor(brightness),
        child: Icon(
          HugeIcons.strokeRoundedPdf01,
          size: 32,
          color: AppColors.primaryFor(brightness),
        ),
      );
    }
    if (!file.existsSync()) {
      return Container(
        height: height,
        width: width,
        color: AppColors.surfaceVariantFor(brightness),
        child: Icon(
          HugeIcons.strokeRoundedImageNotFound01,
          size: 28,
          color: AppColors.textTertiaryFor(brightness),
        ),
      );
    }
    return Container(
      height: height,
      width: width,
      color: AppColors.surfaceVariantFor(brightness),
      child: Icon(
        HugeIcons.strokeRoundedFile01,
        size: 32,
        color: AppColors.textSecondaryFor(brightness),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.document});

  final DocumentEntity document;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantFor(brightness),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Text(
        document.docType.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondaryFor(brightness),
        ),
      ),
    );
  }
}
