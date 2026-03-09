import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';
import 'package:hearth/features/grocery/presentation/screens/barcode_scanner_screen.dart';
import 'package:hearth/features/grocery/presentation/widgets/grocery_visuals.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:uuid/uuid.dart';

Future<void> showAddItemSheet(
  BuildContext context, {
  ShoppingItemEntity? initialItem,
  ShoppingSection? initialSection,
}) {
  return showHearthBottomSheet<void>(
    context: context,
    initialChildSize: 0.82,
    maxChildSize: 0.95,
    builder: (BuildContext context) {
      return AddItemSheet(
        initialItem: initialItem,
        initialSection: initialSection,
      );
    },
  );
}

class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({this.initialItem, this.initialSection, super.key});

  final ShoppingItemEntity? initialItem;
  final ShoppingSection? initialSection;

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _unitFocusNode = FocusNode();

  static const List<String> _unitSuggestions = <String>[
    'pcs',
    'kg',
    'g',
    'L',
    'mL',
    'cup',
    'bunch',
    'box',
    'bag',
    'bottle',
    'can',
    'pack',
  ];

  final Uuid _uuid = const Uuid();

  ShoppingSection _selectedSection = ShoppingSection.other;
  String? _assignedToUserId;
  String? _lookupQuantityHint;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _unitFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _noteController.dispose();
    _nameFocusNode.dispose();
    _unitFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(groceryNotifierProvider);
    final householdAsync = ref.watch(currentHouseholdProvider);
    final currentUserId = ref.watch(groceryCurrentUserIdProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    return householdAsync.when(
      data: (household) => membersAsync.when(
        data: (List<HouseholdMember> members) {
          if (household == null || currentUserId == null) {
            return const SizedBox.shrink();
          }
          _initialize();
          final isEdit = widget.initialItem != null;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isEdit ? 'Edit Item' : 'Add Item',
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Keep the list tidy by aisle, quantity, and who is grabbing what.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                      if (!isEdit) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        _BarcodeShortcutCard(
                          quantityHint: _lookupQuantityHint,
                          onTap: _openScanner,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      HearthTextField(
                        label: 'Name',
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        validator: (String? value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Enter an item name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: HearthTextField(
                              label: 'Quantity',
                              controller: _quantityController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (String? value) {
                                final quantity = double.tryParse(
                                  (value ?? '').trim(),
                                );
                                if (quantity == null || quantity <= 0) {
                                  return 'Use a number.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 3,
                            child: HearthTextField(
                              label: 'Unit',
                              controller: _unitController,
                              focusNode: _unitFocusNode,
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: AppAnimations.standard,
                        curve: AppAnimations.easeInOut,
                        child: _unitFocusNode.hasFocus
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: _unitSuggestions.map((String unit) {
                                    return HearthChip(
                                      label: unit,
                                      selected: _unitController.text == unit,
                                      onTap: () {
                                        setState(() {
                                          _unitController.text = unit;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Section', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: kSectionOrder.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (BuildContext context, int index) {
                            final section = kSectionOrder[index];
                            return HearthChip(
                              label: section.label,
                              selected: section == _selectedSection,
                              icon: shoppingSectionIcon(section),
                              onTap: () {
                                setState(() {
                                  _selectedSection = section;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Assign to', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
                          _AssigneeChip(
                            label: 'Anyone',
                            selected: _assignedToUserId == null,
                            onTap: () {
                              setState(() {
                                _assignedToUserId = null;
                              });
                            },
                          ),
                          ...members.map((HouseholdMember member) {
                            final selected = _assignedToUserId == member.userId;
                            return InkWell(
                              borderRadius: BorderRadius.circular(
                                AppRadius.radiusMd,
                              ),
                              onTap: () {
                                setState(() {
                                  _assignedToUserId = member.userId;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primaryContainerFor(
                                          Theme.of(context).brightness,
                                        )
                                      : AppColors.surfaceVariantFor(
                                          Theme.of(context).brightness,
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primaryFor(
                                            Theme.of(context).brightness,
                                          )
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    HearthAvatar(
                                      displayName: member.displayName,
                                      size: 40,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      member.displayName,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textSecondaryFor(
                                          Theme.of(context).brightness,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      HearthTextField(
                        label: 'Note',
                        controller: _noteController,
                        maxLines: 2,
                      ),
                      if (actionState.message != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          actionState.message!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.errorFor(
                              Theme.of(context).brightness,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      HearthButton(
                        label: isEdit ? 'Save Changes' : 'Add to List',
                        isLoading: actionState.isLoading,
                        onPressed: () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          final quantity = double.parse(
                            _quantityController.text.trim(),
                          );
                          final item = ShoppingItemEntity(
                            id: widget.initialItem?.id ?? _uuid.v4(),
                            householdId: household.id,
                            name: _nameController.text.trim(),
                            quantity: quantity,
                            unit: _unitController.text.trim().isEmpty
                                ? null
                                : _unitController.text.trim(),
                            section: _selectedSection,
                            addedByUserId:
                                widget.initialItem?.addedByUserId ??
                                currentUserId,
                            assignedToUserId: _assignedToUserId,
                            isChecked: widget.initialItem?.isChecked ?? false,
                            checkedByUserId:
                                widget.initialItem?.checkedByUserId,
                            checkedAt: widget.initialItem?.checkedAt,
                            note: _noteController.text.trim().isEmpty
                                ? null
                                : _noteController.text.trim(),
                            createdAt:
                                widget.initialItem?.createdAt ?? DateTime.now(),
                          );
                          try {
                            await ref
                                .read(groceryNotifierProvider.notifier)
                                .saveShoppingItem(item);
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                          } on StateError {
                            return;
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
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Text('$error'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, _) => Text('$error'),
    );
  }

  void _initialize() {
    if (_initialized) {
      return;
    }
    final initialItem = widget.initialItem;
    _selectedSection =
        initialItem?.section ?? widget.initialSection ?? ShoppingSection.other;
    _assignedToUserId = initialItem?.assignedToUserId;
    _nameController.text = initialItem?.name ?? '';
    _quantityController.text = initialItem == null
        ? '1'
        : (initialItem.quantity == initialItem.quantity.truncateToDouble()
              ? initialItem.quantity.toInt().toString()
              : initialItem.quantity.toStringAsFixed(1));
    _unitController.text = initialItem?.unit ?? '';
    _noteController.text = initialItem?.note ?? '';
    _initialized = true;
  }

  Future<void> _openScanner() async {
    final result = await context.push<OpenFoodProduct?>(
      BarcodeScannerScreen.routePath,
    );
    if (!mounted) {
      return;
    }
    if (result == null) {
      _nameFocusNode.requestFocus();
      return;
    }
    setState(() {
      _nameController.text = result.name;
      _selectedSection = result.inferredSection;
      _lookupQuantityHint = result.quantityString.isEmpty
          ? null
          : result.quantityString;
    });
    _nameFocusNode.requestFocus();
  }
}

class _BarcodeShortcutCard extends StatelessWidget {
  const _BarcodeShortcutCard({required this.quantityHint, required this.onTap});

  final String? quantityHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryContainerFor(brightness),
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              HugeIcons.strokeRoundedBarCode01,
              color: AppColors.primaryFor(brightness),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Scan barcode to auto-fill',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryFor(brightness),
                    ),
                  ),
                  if (quantityHint != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Last match: $quantityHint',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.primaryFor(brightness),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainerFor(brightness)
              : AppColors.surfaceVariantFor(brightness),
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected
                ? AppColors.primaryFor(brightness)
                : AppColors.textSecondaryFor(brightness),
          ),
        ),
      ),
    );
  }
}
