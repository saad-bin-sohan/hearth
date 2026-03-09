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
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/vendor_providers.dart';
import 'package:hearth/features/maintenance/presentation/sheets/add_edit_vendor_sheet.dart';
import 'package:hearth/features/maintenance/presentation/widgets/vendor_card.dart';
import 'package:hugeicons/hugeicons.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  static const String routePath = '/maintenance/vendors';

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  VendorCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdId = ref.watch(maintenanceHouseholdIdProvider);
    final brightness = Theme.of(context).brightness;
    if (householdId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final vendorsAsync = ref.watch(vendorsProvider(householdId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vendors',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditVendorSheet(context),
        child: const Icon(HugeIcons.strokeRoundedAddCircle),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: HearthTextField(
              label: 'Search vendors',
              controller: _searchController,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                HearthChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: AppSpacing.sm),
                ...VendorCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: HearthChip(
                      label: category.label,
                      selected: _selectedCategory == category,
                      onTap: () => setState(() => _selectedCategory = category),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: vendorsAsync.when(
              data: (vendors) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = vendors.where((vendor) {
                  final matchesQuery = query.isEmpty ||
                      vendor.businessName.toLowerCase().contains(query) ||
                      (vendor.contactName?.toLowerCase().contains(query) ?? false);
                  final matchesCategory = _selectedCategory == null ||
                      vendor.category == _selectedCategory;
                  return matchesQuery && matchesCategory;
                }).toList()
                  ..sort((left, right) => right.averageRating.compareTo(left.averageRating));
                if (filtered.isEmpty) {
                  return const HearthEmptyState(
                    icon: HugeIcons.strokeRoundedBuilding01,
                    title: 'No vendors saved',
                    body:
                        'Save trusted contractors and service providers for your household.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemBuilder: (BuildContext context, int index) {
                    final vendor = filtered[index];
                    return HearthListItemEntry(
                      index: index,
                      child: HearthSwipeToAction(
                        trailingAction: HearthSwipeAction(
                          icon: HugeIcons.strokeRoundedDelete02,
                          label: 'Delete',
                          color: AppColors.errorFor(brightness),
                          onTriggered: () {
                            ref.read(vendorNotifierProvider.notifier).deleteVendor(vendor.id);
                          },
                        ),
                        child: VendorCard(
                          vendor: vendor,
                          onTap: () => context.push('/maintenance/vendors/${vendor.id}'),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemCount: filtered.length,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, _) => Center(child: Text('$error')),
            ),
          ),
        ],
      ),
    );
  }
}
