import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_fab_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/maintenance/presentation/providers/asset_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_task_providers.dart';
import 'package:hearth/features/maintenance/presentation/screens/asset_list_screen.dart';
import 'package:hearth/features/maintenance/presentation/screens/task_list_screen.dart';
import 'package:hearth/features/maintenance/presentation/screens/vendor_list_screen.dart';
import 'package:hearth/features/maintenance/presentation/sheets/add_edit_asset_sheet.dart';
import 'package:hearth/features/maintenance/presentation/sheets/add_edit_task_sheet.dart';
import 'package:hearth/features/maintenance/presentation/sheets/complete_task_sheet.dart';
import 'package:hearth/features/maintenance/presentation/widgets/asset_card.dart';
import 'package:hearth/features/maintenance/presentation/widgets/overdue_task_banner.dart';
import 'package:hearth/features/maintenance/presentation/widgets/task_card.dart';
import 'package:hugeicons/hugeicons.dart';

class MaintenanceDashboardScreen extends ConsumerStatefulWidget {
  const MaintenanceDashboardScreen({super.key});

  static const String routePath = '/maintenance';

  @override
  ConsumerState<MaintenanceDashboardScreen> createState() =>
      _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState
    extends ConsumerState<MaintenanceDashboardScreen> {
  bool _fabOpen = false;

  @override
  Widget build(BuildContext context) {
    final householdId = ref.watch(maintenanceHouseholdIdProvider);
    final memberLookupAsync = ref.watch(maintenanceMemberLookupProvider);
    if (householdId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final assetsAsync = ref.watch(assetsProvider(householdId));
    final overdueAsync = ref.watch(overdueTasksProvider(householdId));
    final upcomingAsync = ref.watch(upcomingTasksProvider(householdId));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Maintenance',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push(VendorListScreen.routePath),
            icon: const Icon(HugeIcons.strokeRoundedStore01),
          ),
          IconButton(
            onPressed: () => showAddEditTaskSheet(context),
            icon: const Icon(HugeIcons.strokeRoundedAdd01),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              OverdueTaskBanner(
                overdueCount: overdueAsync.valueOrNull?.length ?? 0,
                onViewPressed: () => context.push(TaskListScreen.routePath),
              ),
              HearthSectionHeader(
                title: 'Upcoming Tasks',
                actionLabel: 'See All',
                onActionPressed: () => context.push(TaskListScreen.routePath),
              ),
              upcomingAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: HearthEmptyState(
                        icon: HugeIcons.strokeRoundedCalendarSetting01,
                        title: 'No upcoming tasks',
                        body: 'Add one to stay on top of maintenance.',
                      ),
                    );
                  }
                  return Column(
                    children: List<Widget>.generate(tasks.length, (int index) {
                      final task = tasks[index];
                      final assigneeName =
                          memberLookupAsync.valueOrNull?[task.assignedToUserId]
                              ?.displayName;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: HearthListItemEntry(
                          index: index,
                          child: HearthSwipeToAction(
                            leadingAction: HearthSwipeAction(
                              icon: HugeIcons.strokeRoundedTick02,
                              label: 'Complete',
                              color: AppColors.successFor(brightness),
                              onTriggered: () async {
                                await showCompleteTaskSheet(context, task: task);
                              },
                            ),
                            trailingAction: HearthSwipeAction(
                              icon: HugeIcons.strokeRoundedDelete02,
                              label: 'Delete',
                              color: AppColors.errorFor(brightness),
                              onTriggered: () {
                                ref
                                    .read(maintenanceTaskNotifierProvider.notifier)
                                    .deleteTask(task.id);
                              },
                            ),
                            child: TaskCard(
                              task: task,
                              assigneeName: assigneeName,
                              onTap: () => context.push('/maintenance/tasks/${task.id}'),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, _) => Text('$error'),
              ),
              const SizedBox(height: AppSpacing.lg),
              HearthSectionHeader(
                title: 'Home Assets',
                actionLabel: 'See All',
                onActionPressed: () => context.push(AssetListScreen.routePath),
              ),
              assetsAsync.when(
                data: (assets) {
                  if (assets.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: HearthEmptyState(
                        icon: HugeIcons.strokeRoundedWrench01,
                        title: 'No assets tracked yet',
                        body:
                            'Add your appliances, vehicles, and home systems.',
                        ctaLabel: 'Add Asset',
                        onCtaPressed: () => showAddEditAssetSheet(context),
                      ),
                    );
                  }
                  final preview = assets.take(4).toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: preview.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.88,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final asset = preview[index];
                      return HearthListItemEntry(
                        index: index,
                        child: AssetCard(
                          asset: asset,
                          onTap: () => context.push('/maintenance/assets/${asset.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, _) => Text('$error'),
              ),
              const SizedBox(height: 120),
            ],
          ),
          if (_fabOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _fabOpen = false;
                  });
                },
                child: AnimatedOpacity(
                  duration: AppAnimations.standard,
                  opacity: _fabOpen ? 1 : 0,
                  child: Container(color: AppColors.overlay.withValues(alpha: 0.3)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: <Widget>[
          if (_fabOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  HearthFABEntry(
                    child: FloatingActionButton.extended(
                      heroTag: 'maintenance-add-asset',
                      onPressed: () {
                        setState(() {
                          _fabOpen = false;
                        });
                        showAddEditAssetSheet(context);
                      },
                      icon: const Icon(HugeIcons.strokeRoundedWrench01),
                      label: const Text('Add Asset'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  HearthFABEntry(
                    child: FloatingActionButton.extended(
                      heroTag: 'maintenance-add-task',
                      onPressed: () {
                        setState(() {
                          _fabOpen = false;
                        });
                        showAddEditTaskSheet(context);
                      },
                      icon: const Icon(HugeIcons.strokeRoundedCalendarSetting01),
                      label: const Text('Add Task'),
                    ),
                  ),
                ],
              ),
            ),
          FloatingActionButton(
            heroTag: 'maintenance-main-fab',
            onPressed: () {
              setState(() {
                _fabOpen = !_fabOpen;
              });
            },
            child: Icon(
              _fabOpen
                  ? HugeIcons.strokeRoundedCancel01
                  : HugeIcons.strokeRoundedAddCircle,
            ),
          ),
        ],
      ),
    );
  }
}
