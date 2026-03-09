import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_empty_state.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_context_providers.dart';
import 'package:hearth/features/maintenance/presentation/providers/maintenance_task_providers.dart';
import 'package:hearth/features/maintenance/presentation/sheets/add_edit_task_sheet.dart';
import 'package:hearth/features/maintenance/presentation/sheets/complete_task_sheet.dart';
import 'package:hearth/features/maintenance/presentation/widgets/task_card.dart';
import 'package:hugeicons/hugeicons.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  static const String routePath = '/maintenance/tasks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(maintenanceHouseholdIdProvider);
    final memberLookupAsync = ref.watch(maintenanceMemberLookupProvider);
    final brightness = Theme.of(context).brightness;
    if (householdId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final tasksAsync = ref.watch(allTasksProvider(householdId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tasks',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditTaskSheet(context),
        child: const Icon(HugeIcons.strokeRoundedAddCircle),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const HearthEmptyState(
              icon: HugeIcons.strokeRoundedCalendarSetting01,
              title: 'No maintenance tasks yet',
              body: 'Add a task to stay ahead of upkeep.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              final task = tasks[index];
              return HearthSwipeToAction(
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
                    ref.read(maintenanceTaskNotifierProvider.notifier).deleteTask(task.id);
                  },
                ),
                child: TaskCard(
                  task: task,
                  assigneeName:
                      memberLookupAsync.valueOrNull?[task.assignedToUserId]?.displayName,
                  onTap: () => context.push('/maintenance/tasks/${task.id}'),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemCount: tasks.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
