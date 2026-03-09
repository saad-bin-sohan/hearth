import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/household/presentation/join_household_screen.dart';
import 'package:hearth/features/household/presentation/member_management_screen.dart';
import 'package:hugeicons/hugeicons.dart';

class MoreModulesSheet extends StatelessWidget {
  const MoreModulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final lockedColor = AppColors.textTertiaryFor(brightness);
    final lockedModules = <({String title, IconData icon})>[
      (title: 'Grocery & Pantry', icon: HugeIcons.strokeRoundedBookmark01),
      (
        title: 'Maintenance Ledger',
        icon: HugeIcons.strokeRoundedCalendarSetting01,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('More', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        _SheetAction(
          icon: HugeIcons.strokeRoundedUserGroup,
          title: 'Members',
          subtitle: 'Review roles, observers, and member access.',
          onTap: () {
            Navigator.of(context).pop();
            context.push(MemberManagementScreen.routePath);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _SheetAction(
          icon: HugeIcons.strokeRoundedAddTeam,
          title: 'Join a household',
          subtitle: 'Use an invite code to join another space.',
          onTap: () {
            Navigator.of(context).pop();
            context.push(JoinHouseholdScreen.routePath);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ...lockedModules.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: HearthCard(
              child: Row(
                children: <Widget>[
                  Icon(item.icon, color: lockedColor),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: lockedColor),
                    ),
                  ),
                  Icon(HugeIcons.strokeRoundedLock, color: lockedColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HearthCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(HugeIcons.strokeRoundedArrowRight01),
        ],
      ),
    );
  }
}
