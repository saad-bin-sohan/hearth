import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/features/maintenance/presentation/providers/asset_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/sheets/add_edit_asset_sheet.dart';
import 'package:hearth/features/maintenance/presentation/widgets/asset_card.dart';
import 'package:hugeicons/hugeicons.dart';

class AssetListScreen extends ConsumerWidget {
  const AssetListScreen({super.key});

  static const String routePath = '/maintenance/assets';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(maintenanceHouseholdIdProvider);
    final brightness = Theme.of(context).brightness;
    if (householdId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final assetsAsync = ref.watch(assetsProvider(householdId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assets',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditAssetSheet(context),
        child: const Icon(HugeIcons.strokeRoundedAddCircle),
      ),
      body: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) {
            return const HearthEmptyState(
              icon: HugeIcons.strokeRoundedWrench01,
              title: 'No assets tracked yet',
              body: 'Add an asset to start building your maintenance ledger.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: assets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (BuildContext context, int index) {
              final asset = assets[index];
              return AssetCard(
                asset: asset,
                onTap: () => context.push('/maintenance/assets/${asset.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
