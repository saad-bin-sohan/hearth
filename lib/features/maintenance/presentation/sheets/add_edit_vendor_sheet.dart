import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/vendor_providers.dart';
import 'package:hearth/features/maintenance/presentation/widgets/maintenance_visuals.dart';
import 'package:uuid/uuid.dart';

Future<void> showAddEditVendorSheet(
  BuildContext context, {
  Vendor? initialVendor,
}) {
  return showHearthBottomSheet<void>(
    context: context,
    initialChildSize: 0.76,
    maxChildSize: 0.92,
    builder: (BuildContext context) {
      return AddEditVendorSheet(initialVendor: initialVendor);
    },
  );
}

class AddEditVendorSheet extends ConsumerStatefulWidget {
  const AddEditVendorSheet({this.initialVendor, super.key});

  final Vendor? initialVendor;

  @override
  ConsumerState<AddEditVendorSheet> createState() => _AddEditVendorSheetState();
}

class _AddEditVendorSheetState extends ConsumerState<AddEditVendorSheet> {
  final TextEditingController _businessController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  VendorCategory _category = VendorCategory.plumber;
  bool _initialized = false;

  @override
  void dispose() {
    _businessController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdId = ref.watch(maintenanceHouseholdIdProvider);
    final userId = ref.watch(maintenanceCurrentUserIdProvider);
    final notifierState = ref.watch(vendorNotifierProvider);
    if (!_initialized) {
      _initialize();
    }
    if (householdId == null || userId == null) {
      return const SizedBox.shrink();
    }
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.initialVendor == null ? 'Add Vendor' : 'Edit Vendor',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        HearthTextField(label: 'Business Name', controller: _businessController),
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
          children: VendorCategory.values.map((VendorCategory category) {
            return HearthChip(
              label: category.label,
              icon: iconForVendorCategory(category),
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
        HearthTextField(label: 'Contact Name', controller: _contactController),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Phone',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Website',
          controller: _websiteController,
          keyboardType: TextInputType.url,
          hintText: 'https://...',
        ),
        const SizedBox(height: AppSpacing.md),
        HearthTextField(
          label: 'Notes',
          controller: _notesController,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.xl),
        HearthButton(
          label: 'Save Vendor',
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
    final initialVendor = widget.initialVendor;
    if (initialVendor != null) {
      _businessController.text = initialVendor.businessName;
      _contactController.text = initialVendor.contactName ?? '';
      _phoneController.text = initialVendor.phone ?? '';
      _emailController.text = initialVendor.email ?? '';
      _websiteController.text = initialVendor.website ?? '';
      _notesController.text = initialVendor.notes ?? '';
      _category = initialVendor.category;
    }
    _initialized = true;
  }

  Future<void> _save(String householdId, String userId) async {
    final name = _businessController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final vendor = Vendor(
      id: widget.initialVendor?.id ?? const Uuid().v4(),
      householdId: householdId,
      businessName: name,
      contactName: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      category: _category,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      averageRating: widget.initialVendor?.averageRating ?? 0,
      createdByUserId: widget.initialVendor?.createdByUserId ?? userId,
      createdAt: widget.initialVendor?.createdAt ?? DateTime.now(),
    );
    try {
      if (widget.initialVendor == null) {
        await ref.read(vendorNotifierProvider.notifier).addVendor(vendor);
      } else {
        await ref.read(vendorNotifierProvider.notifier).updateVendor(vendor);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save vendor right now.')),
      );
    }
  }
}
