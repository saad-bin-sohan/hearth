import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/home/presentation/settings_screen.dart';
import 'package:hearth/features/household/presentation/join_household_screen.dart';
import 'package:hearth/features/household/presentation/member_management_screen.dart';
import 'package:hugeicons/hugeicons.dart';

class MoreModulesSheet extends StatelessWidget {
  const MoreModulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
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
        _SheetAction(
          icon: HugeIcons.strokeRoundedSettings02,
          title: 'Settings',
          subtitle: 'Theme, account, and app preferences.',
          onTap: () {
            Navigator.of(context).pop();
            context.push(SettingsScreen.routePath);
          },
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
