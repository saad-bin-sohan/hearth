import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/animated/hearth_list_item_entry.dart';
import 'package:hearth/core/widgets/animated/hearth_swipe_to_action.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/household/domain/household_models.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hearth/features/household/presentation/widgets/role_badge.dart';
import 'package:hugeicons/hugeicons.dart';

class MemberManagementScreen extends ConsumerWidget {
  const MemberManagementScreen({this.showAppBar = true, super.key});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(householdMembersProvider);
    final session = ref.watch(sessionControllerProvider);
    final roleAsync = ref.watch(currentHouseholdRoleProvider);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Members')) : null,
      body: membersAsync.when(
        data: (members) => roleAsync.when(
          data: (viewerRole) {
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (context, index) {
                final member = members[index];
                final isSelf = member.userId == session.userId;
                final canManage = viewerRole == HouseholdRole.admin && !isSelf;
                final tile = HearthListItemEntry(
                  index: index,
                  child: HearthSwipeToAction(
                    trailingAction: canManage
                        ? HearthSwipeAction(
                            icon: HugeIcons.strokeRoundedDelete02,
                            label: 'Remove',
                            color: AppColors.errorFor(Theme.of(context).brightness),
                            onTriggered: () async {
                              await ref
                                  .read(householdNotifierProvider.notifier)
                                  .removeMember(member.userId);
                            },
                          )
                        : null,
                    child: HearthCard(
                      child: Row(
                        children: <Widget>[
                          HearthAvatar(displayName: member.displayName, size: 48),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  member.displayName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(member.email, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          RoleBadge(role: member.role),
                          if (canManage)
                            PopupMenuButton<HouseholdRole>(
                              icon: const Icon(HugeIcons.strokeRoundedMoreVertical),
                              onSelected: (role) async {
                                await ref
                                    .read(householdNotifierProvider.notifier)
                                    .updateRole(
                                      memberUserId: member.userId,
                                      role: role,
                                    );
                              },
                              itemBuilder: (context) {
                                return HouseholdRole.values
                                    .map(
                                      (role) => PopupMenuItem<HouseholdRole>(
                                        value: role,
                                        child: Text(role.label),
                                      ),
                                    )
                                    .toList();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
                return tile;
              },
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemCount: members.length,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
