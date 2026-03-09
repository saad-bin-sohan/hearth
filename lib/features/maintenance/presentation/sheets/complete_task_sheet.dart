import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/maintenance/domain/entities/maintenance_task.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_task_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/vendor_providers.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

Future<DateTime?> showCompleteTaskSheet(
  BuildContext context, {
  required MaintenanceTask task,
  String? assetName,
}) {
  return showHearthBottomSheet<DateTime?>(
    context: context,
    initialChildSize: 0.62,
    maxChildSize: 0.82,
    builder: (BuildContext context) {
      return CompleteTaskSheet(task: task, assetName: assetName);
    },
  );
}

class CompleteTaskSheet extends ConsumerStatefulWidget {
  const CompleteTaskSheet({
    required this.task,
    this.assetName,
    super.key,
  });

  final MaintenanceTask task;
  final String? assetName;

  @override
  ConsumerState<CompleteTaskSheet> createState() => _CompleteTaskSheetState();
}

class _CompleteTaskSheetState extends ConsumerState<CompleteTaskSheet> {
  final TextEditingController _actualCostController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _photoFile;
  String? _selectedVendorId;
  bool _initialized = false;

  @override
  void dispose() {
    _actualCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdId = ref.watch(maintenanceHouseholdIdProvider);
    if (!_initialized) {
      _actualCostController.text = widget.task.estimatedCost?.toString() ?? '';
      _selectedVendorId = widget.task.vendorId;
      _initialized = true;
    }
    if (householdId == null) {
      return const SizedBox.shrink();
    }
    final vendorsAsync = ref.watch(vendorsProvider(householdId));
    final notifierState = ref.watch(maintenanceTaskNotifierProvider);
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.task.title,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        if (widget.assetName != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.assetName!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryFor(brightness),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        HearthTextField(
          label: 'Actual Cost',
          controller: _actualCostController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Vendor Used',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        vendorsAsync.when(
          data: (vendors) {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                HearthChip(
                  label: 'No vendor',
                  selected: _selectedVendorId == null,
                  onTap: () {
                    setState(() {
                      _selectedVendorId = null;
                    });
                  },
                ),
                ...vendors.map((Vendor vendor) {
                  return HearthChip(
                    label: vendor.businessName,
                    selected: _selectedVendorId == vendor.id,
                    onTap: () {
                      setState(() {
                        _selectedVendorId = vendor.id;
                      });
                    },
                  );
                }),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (Object error, _) => Text('$error'),
        ),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Notes',
          controller: _notesController,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            HearthButton(
              label: _photoFile == null ? 'Add Photo' : 'Replace Photo',
              expanded: false,
              variant: HearthButtonVariant.ghost,
              icon: const Icon(HugeIcons.strokeRoundedCamera01),
              onPressed: _pickPhoto,
            ),
            if (_photoFile != null) ...<Widget>[
              const SizedBox(width: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                child: Image.file(
                  _photoFile!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        HearthButton(
          label: 'Complete Task',
          isLoading: notifierState.isLoading,
          onPressed: _complete,
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

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedCamera01),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedImage01),
                title: const Text('Photo Library'),
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
    final image = await _imagePicker.pickImage(source: source);
    if (image == null) {
      return;
    }
    setState(() {
      _photoFile = File(image.path);
    });
  }

  Future<void> _complete() async {
    try {
      final nextDueDate = await ref
          .read(maintenanceTaskNotifierProvider.notifier)
          .completeTask(
            widget.task,
            actualCost: double.tryParse(_actualCostController.text.trim()),
            vendorId: _selectedVendorId,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            photoFile: _photoFile,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(nextDueDate);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to complete task right now.')),
      );
    }
  }
}
