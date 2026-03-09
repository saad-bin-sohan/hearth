import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/maintenance/domain/entities/vendor.dart';
import 'package:hearth/features/maintenance/presentation/providers/asset_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/vendor_providers.dart';
import 'package:hearth/features/maintenance/presentation/sheets/add_edit_vendor_sheet.dart';
import 'package:hearth/features/maintenance/presentation/widgets/maintenance_visuals.dart';
import 'package:hearth/features/maintenance/presentation/widgets/star_rating_widget.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  const VendorDetailScreen({required this.vendorId, super.key});

  final String vendorId;

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  double _selectedRating = 0;
  bool _initialized = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorAsync = ref.watch(vendorDetailProvider(widget.vendorId));
    final currentRatingAsync = ref.watch(
      vendorCurrentUserRatingProvider(widget.vendorId),
    );
    final ratingsAsync = ref.watch(vendorRatingsProvider(widget.vendorId));
    final tasksAsync = ref.watch(completedVendorTasksProvider(widget.vendorId));
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(
        title: vendorAsync.when(
          data: (vendor) => Text(
            vendor?.businessName ?? 'Vendor',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          loading: () => Text(
            'Vendor',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
          error: (_, __) => Text(
            'Vendor',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
        ),
        actions: <Widget>[
          vendorAsync.when(
            data: (vendor) => vendor == null
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: () =>
                        showAddEditVendorSheet(context, initialVendor: vendor),
                    icon: const Icon(HugeIcons.strokeRoundedEdit02),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: vendorAsync.when(
        data: (vendor) {
          if (vendor == null) {
            return const Center(child: Text('Vendor not found.'));
          }
          final currentRating = currentRatingAsync.valueOrNull;
          if (!_initialized && currentRating != null) {
            _selectedRating = currentRating.stars.toDouble();
            _notesController.text = currentRating.notes ?? '';
            _initialized = true;
          }
          final ratingsCount = ratingsAsync.valueOrNull?.length ?? 0;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              HearthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      vendor.businessName,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                      ),
                    ),
                    if (vendor.contactName != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        vendor.contactName!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryFor(brightness),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    HearthChip(
                      label: vendor.category.label,
                      icon: iconForVendorCategory(vendor.category),
                      selected: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (vendor.phone != null)
                      _ContactRow(
                        icon: HugeIcons.strokeRoundedSmartPhone01,
                        label: vendor.phone!,
                        onTap: () => _launch('tel:${vendor.phone!}'),
                      ),
                    if (vendor.email != null)
                      _ContactRow(
                        icon: HugeIcons.strokeRoundedMail01,
                        label: vendor.email!,
                        onTap: () => _launch('mailto:${vendor.email!}'),
                      ),
                    if (vendor.website != null)
                      _ContactRow(
                        icon: HugeIcons.strokeRoundedInternet,
                        label: vendor.website!,
                        onTap: () => _launch(vendor.website!),
                      ),
                    if (vendor.notes != null) ...<Widget>[
                      const Divider(height: AppSpacing.xl),
                      Text(
                        vendor.notes!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryFor(brightness),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              HearthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        StarRatingWidget(rating: vendor.averageRating),
                        const SizedBox(width: AppSpacing.md),
                        HearthNumberTicker(
                          value: vendor.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.numericMedium.copyWith(
                            color: AppColors.accentFor(brightness),
                          ),
                          suffix: '/5',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Based on $ratingsCount rating${ratingsCount == 1 ? '' : 's'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiaryFor(brightness),
                      ),
                    ),
                    const Divider(height: AppSpacing.xl),
                    Text(
                      'Your Rating',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimaryFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StarRatingWidget(
                      rating: _selectedRating,
                      interactive: true,
                      onRatingChanged: (value) {
                        setState(() {
                          _selectedRating = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    HearthTextField(
                      label: 'Notes',
                      controller: _notesController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    HearthButton(
                      label: 'Submit Rating',
                      isLoading: ref.watch(vendorNotifierProvider).isLoading,
                      onPressed: _selectedRating == 0
                          ? null
                          : () async {
                              await ref.read(vendorNotifierProvider.notifier).submitRating(
                                    vendorId: vendor.id,
                                    stars: _selectedRating.round(),
                                    notes: _notesController.text.trim().isEmpty
                                        ? null
                                        : _notesController.text.trim(),
                                  );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const HearthSectionHeader(title: 'Service History with this Vendor'),
              tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text('No completed tasks with this vendor yet.'),
                    );
                  }
                  return Column(
                    children: tasks.map<Widget>((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: HearthCard(
                          onTap: () => context.push('/maintenance/tasks/${task.id}'),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(task.title, style: AppTextStyles.titleMedium),
                                    if (task.assetId != null)
                                      Consumer(
                                        builder: (
                                          BuildContext context,
                                          WidgetRef ref,
                                          Widget? child,
                                        ) {
                                          final assetAsync = ref.watch(
                                            assetDetailProvider(task.assetId!),
                                          );
                                          return Text(
                                            assetAsync.valueOrNull?.name ?? 'Asset',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondaryFor(brightness),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  if (task.completedAt != null)
                                    Text(
                                      AppFormatters.shortDate(task.completedAt!),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textTertiaryFor(brightness),
                                      ),
                                    ),
                                  if (task.actualCost != null)
                                    Text(
                                      '\$${task.actualCost!.toStringAsFixed(2)}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondaryFor(brightness),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, _) => Text('$error'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Center(child: Text('$error')),
      ),
    );
  }

  Future<void> _launch(String value) async {
    final uri = Uri.parse(value.startsWith('http') ? value : value);
    await launchUrl(uri);
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: AppColors.secondaryFor(brightness)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimaryFor(brightness),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
