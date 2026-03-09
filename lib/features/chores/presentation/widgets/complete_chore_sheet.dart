import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/chores/presentation/chore_notifier.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

Future<ChoreCompletionOutcome?> showCompleteChoreSheet(
  BuildContext context, {
  required ChoreEntity chore,
}) {
  return showHearthBottomSheet<ChoreCompletionOutcome>(
    context: context,
    initialChildSize: 0.54,
    minChildSize: 0.4,
    maxChildSize: 0.72,
    builder: (BuildContext context) {
      return CompleteChoreSheet(chore: chore);
    },
  );
}

class CompleteChoreSheet extends ConsumerStatefulWidget {
  const CompleteChoreSheet({required this.chore, super.key});

  final ChoreEntity chore;

  @override
  ConsumerState<CompleteChoreSheet> createState() => _CompleteChoreSheetState();
}

class _CompleteChoreSheetState extends ConsumerState<CompleteChoreSheet> {
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _photoPath;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(choreNotifierProvider);
    final brightness = Theme.of(context).brightness;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.chore.title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimaryFor(brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Current streak: ${widget.chore.streakCount} days 🔥',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.accentFor(brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            HearthButton(
              label: _photoPath == null ? 'Add photo proof' : 'Change photo',
              variant: HearthButtonVariant.ghost,
              icon: const Icon(HugeIcons.strokeRoundedCamera01),
              onPressed: _pickPhoto,
            ),
            if (_photoPath != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                child: Image.file(
                  File(_photoPath!),
                  height: 148,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            HearthTextField(
              label: 'Notes',
              controller: _notesController,
              maxLines: 3,
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
              label: 'Complete',
              isLoading: actionState.isLoading,
              icon: const Icon(HugeIcons.strokeRoundedTick02),
              onPressed: () async {
                try {
                  final outcome = await ref
                      .read(choreNotifierProvider.notifier)
                      .completeChore(
                        choreId: widget.chore.id,
                        notes: _notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim(),
                        photoLocalPath: _photoPath,
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop(outcome);
                  }
                } on StateError {
                  // surfaced via notifier state
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            HearthButton(
              label: 'Cancel',
              variant: HearthButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedCamera01),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedImage01),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) {
      return;
    }
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
    );
    if (image == null) {
      return;
    }
    setState(() {
      _photoPath = image.path;
    });
  }
}
