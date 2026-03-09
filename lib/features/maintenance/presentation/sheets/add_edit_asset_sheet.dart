import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/expiry_status.dart';
import 'package:hearth/core/widgets/expiry_badge.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/maintenance/domain/entities/asset.dart';
import 'package:hearth/features/maintenance/presentation/providers/asset_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/widgets/maintenance_visuals.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

Future<void> showAddEditAssetSheet(
  BuildContext context, {
  Asset? initialAsset,
}) {
  return showHearthBottomSheet<void>(
    context: context,
    initialChildSize: 0.82,
    maxChildSize: 0.95,
    builder: (BuildContext context) {
      return AddEditAssetSheet(initialAsset: initialAsset);
    },
  );
}

class AddEditAssetSheet extends ConsumerStatefulWidget {
  const AddEditAssetSheet({this.initialAsset, super.key});

  final Asset? initialAsset;

  @override
  ConsumerState<AddEditAssetSheet> createState() => _AddEditAssetSheetState();
}

class _AddEditAssetSheetState extends ConsumerState<AddEditAssetSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  AssetCategory _category = AssetCategory.appliance;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  File? _pickedPhoto;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdId = ref.watch(maintenanceHouseholdIdProvider);
    final userId = ref.watch(maintenanceCurrentUserIdProvider);
    final notifierState = ref.watch(assetNotifierProvider);
    if (!_initialized) {
      _initialize();
    }
    if (householdId == null || userId == null) {
      return const SizedBox.shrink();
    }
    final brightness = Theme.of(context).brightness;
    final previewPath = _pickedPhoto?.path ?? widget.initialAsset?.photoLocalPath;
    final previewUrgency = widget.initialAsset?.copyWith(
      warrantyExpiry: _warrantyExpiry,
    ).warrantyUrgency;
    final badgeUrgency = previewUrgency == null
        ? null
        : <DateExpiryUrgency, ExpiryBadgeUrgency>{
            DateExpiryUrgency.none: ExpiryBadgeUrgency.none,
            DateExpiryUrgency.safe: ExpiryBadgeUrgency.safe,
            DateExpiryUrgency.warning: ExpiryBadgeUrgency.warning,
            DateExpiryUrgency.critical: ExpiryBadgeUrgency.critical,
            DateExpiryUrgency.expired: ExpiryBadgeUrgency.expired,
          }[previewUrgency];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.initialAsset == null ? 'Add Asset' : 'Edit Asset',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantFor(brightness),
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                ),
                alignment: Alignment.center,
                child: previewPath == null
                    ? Icon(
                        HugeIcons.strokeRoundedCamera01,
                        color: AppColors.textSecondaryFor(brightness),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                        child: Image.file(
                          File(previewPath),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  HearthButton(
                    label: 'Choose Photo',
                    expanded: false,
                    onPressed: _pickPhoto,
                    icon: const Icon(HugeIcons.strokeRoundedImage01),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add a clear reference photo for quick identification.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        HearthTextField(label: 'Name', controller: _nameController),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Category',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: AssetCategory.values.map((AssetCategory category) {
            return HearthChip(
              label: category.label,
              icon: iconForAssetCategory(category),
              selected: _category == category,
              onTap: () {
                setState(() {
                  _category = category;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(label: 'Brand', controller: _brandController),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(label: 'Model Number', controller: _modelController),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(label: 'Serial Number', controller: _serialController),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Location Note',
          controller: _locationController,
          hintText: 'e.g. Laundry room, Garage',
        ),
        const SizedBox(height: AppSpacing.md),
        _DateButtonRow(
          label: 'Purchase Date',
          value: _purchaseDate,
          onPressed: () => _pickDate(_purchaseDate, (DateTime value) {
            setState(() {
              _purchaseDate = value;
            });
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        HearthTextField(
          label: 'Purchase Price',
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.md),
        _DateButtonRow(
          label: 'Warranty Expiry',
          value: _warrantyExpiry,
          onPressed: () => _pickDate(_warrantyExpiry, (DateTime value) {
            setState(() {
              _warrantyExpiry = value;
            });
          }),
        ),
        if (_warrantyExpiry != null && previewUrgency != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ExpiryBadge(
            urgency: badgeUrgency ?? ExpiryBadgeUrgency.none,
            daysUntil:
                widget.initialAsset
                    ?.copyWith(warrantyExpiry: _warrantyExpiry)
                    .daysUntilWarranty ??
                Asset(
                  id: 'preview',
                  householdId: householdId,
                  name: _nameController.text,
                  category: _category,
                  warrantyExpiry: _warrantyExpiry,
                  createdByUserId: userId,
                  createdAt: DateTime.now(),
                ).daysUntilWarranty,
            date: _warrantyExpiry,
            size: ExpiryBadgeSize.large,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        HearthButton(
          label: 'Save Asset',
          isLoading: notifierState.isLoading,
          onPressed: () => _save(householdId, userId),
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

  void _initialize() {
    final initialAsset = widget.initialAsset;
    if (initialAsset != null) {
      _nameController.text = initialAsset.name;
      _brandController.text = initialAsset.brand ?? '';
      _modelController.text = initialAsset.modelNumber ?? '';
      _serialController.text = initialAsset.serialNumber ?? '';
      _locationController.text = initialAsset.locationNote ?? '';
      _priceController.text = initialAsset.purchasePrice?.toString() ?? '';
      _category = initialAsset.category;
      _purchaseDate = initialAsset.purchaseDate;
      _warrantyExpiry = initialAsset.warrantyExpiry;
    }
    _initialized = true;
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
      _pickedPhoto = File(image.path);
    });
  }

  Future<void> _pickDate(
    DateTime? initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      initialDate: initial ?? DateTime.now(),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _save(String householdId, String userId) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final asset = Asset(
      id: widget.initialAsset?.id ?? const Uuid().v4(),
      householdId: householdId,
      name: name,
      category: _category,
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      modelNumber: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
      serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
      purchaseDate: _purchaseDate,
      purchasePrice: double.tryParse(_priceController.text.trim()),
      warrantyExpiry: _warrantyExpiry,
      photoLocalPath: widget.initialAsset?.photoLocalPath,
      locationNote: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      createdByUserId: widget.initialAsset?.createdByUserId ?? userId,
      createdAt: widget.initialAsset?.createdAt ?? DateTime.now(),
    );
    try {
      if (widget.initialAsset == null) {
        await ref.read(assetNotifierProvider.notifier).addAsset(asset, _pickedPhoto);
      } else {
        await ref.read(assetNotifierProvider.notifier).updateAsset(asset, _pickedPhoto);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save asset right now.')),
      );
    }
  }
}

class _DateButtonRow extends StatelessWidget {
  const _DateButtonRow({
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
          label: value == null ? 'Set date' : '${value!.day}/${value!.month}/${value!.year}',
          expanded: false,
          variant: HearthButtonVariant.ghost,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
