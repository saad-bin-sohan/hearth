import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/features/grocery/domain/grocery_models.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';
import 'package:hearth/features/grocery/presentation/screens/shopping_list_screen.dart';
import 'package:hugeicons/hugeicons.dart';

class ListTemplatesScreen extends ConsumerWidget {
  const ListTemplatesScreen({super.key});

  static const String routePath = '/grocery/templates';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final householdId = ref.watch(groceryHouseholdIdProvider);
    if (householdId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Templates',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryFor(brightness),
            ),
          ),
        ),
        body: const Center(
          child: Text('Create or join a household to save reusable templates.'),
        ),
      );
    }

    final templatesAsync = ref.watch(templatesProvider(householdId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Templates',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        actions: <Widget>[
          Tooltip(
            message:
                'Save your shopping list as a template to reuse it anytime.',
            child: Icon(
              HugeIcons.strokeRoundedInformationCircle,
              color: AppColors.textSecondaryFor(brightness),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const HearthEmptyState(
              icon: HugeIcons.strokeRoundedFile02,
              title: 'No templates saved',
              body:
                  'Go to your shopping list, tap ⋯, and save it as a template.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: HearthListItemEntry(
                  index: index,
                  child: HearthSwipeToAction(
                    leadingAction: HearthSwipeAction(
                      icon: HugeIcons.strokeRoundedDelete02,
                      label: 'Delete',
                      color: AppColors.errorFor(brightness),
                      onTriggered: () async {
                        final confirmed = await _confirmDelete(
                          context,
                          template.name,
                        );
                        if (confirmed == true) {
                          await ref
                              .read(groceryNotifierProvider.notifier)
                              .deleteTemplate(template.id);
                        }
                      },
                    ),
                    trailingAction: HearthSwipeAction(
                      icon: HugeIcons.strokeRoundedEdit02,
                      label: 'Rename',
                      color: AppColors.warningFor(brightness),
                      onTriggered: () async {
                        final renamed = await _promptForName(
                          context,
                          initialValue: template.name,
                          title: 'Rename Template',
                        );
                        if (renamed == null || renamed.isEmpty) {
                          return;
                        }
                        await ref
                            .read(groceryNotifierProvider.notifier)
                            .saveTemplate(template.copyWith(name: renamed));
                      },
                    ),
                    child: HearthCard(
                      onTap: () => _showTemplatePreview(
                        context: context,
                        ref: ref,
                        householdId: householdId,
                        template: template,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(template.name, style: AppTextStyles.titleLarge),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${template.items.length} items',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryFor(brightness),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            template.items
                                .take(3)
                                .map((item) => item.name)
                                .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiaryFor(brightness),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            AppFormatters.shortDate(template.createdAt),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiaryFor(brightness),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }

  Future<void> _showTemplatePreview({
    required BuildContext context,
    required WidgetRef ref,
    required String householdId,
    required ListTemplateEntity template,
  }) {
    final currentItems = ref.read(effectiveShoppingItemsProvider(householdId));
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(brightness),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.radiusLg),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(template.name, style: AppTextStyles.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${template.items.length} items',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: template.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = template.items[index];
                      return Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          Text(
                            item.quantityDisplay,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryFor(brightness),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () async {
                    final replaceCurrent = currentItems.isNotEmpty
                        ? await _askApplyMode(context, currentItems.length)
                        : false;
                    if (!context.mounted || replaceCurrent == null) {
                      return;
                    }
                    await ref
                        .read(groceryNotifierProvider.notifier)
                        .applyTemplate(
                          template,
                          replaceCurrent: replaceCurrent,
                        );
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                    context.go(ShoppingListScreen.routePath);
                  },
                  child: const Text('Load to Shopping List'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _promptForName(
    BuildContext context, {
    required String initialValue,
    required String title,
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: AppTextStyles.headlineSmall),
          content: TextField(controller: controller),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete $name?', style: AppTextStyles.headlineSmall),
          content: const Text('This removes the template permanently.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _askApplyMode(BuildContext context, int existingCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Current list has $existingCount items',
            style: AppTextStyles.headlineSmall,
          ),
          content: const Text(
            'Add template items to the existing list or replace the list entirely?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Add to List'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace List'),
            ),
          ],
        );
      },
    );
  }
}
