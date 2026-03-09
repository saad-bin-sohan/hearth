import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/household/data/local_household_repository.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hearth/features/household/presentation/invite_screen.dart';
import 'package:hearth/features/household/presentation/join_household_screen.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

class HouseholdOverviewScreen extends ConsumerWidget {
  const HouseholdOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(currentHouseholdProvider);
    return householdAsync.when(
      data: (household) {
        if (household == null) {
          return const SizedBox.shrink();
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            HearthSectionHeader(
              title: household.name,
              subtitle: 'Invite code ${household.inviteCode} • ${household.currencyCode}',
            ),
            HearthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${household.emoji} ${household.name}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Keep membership, roles, and invites in one place so the household stays clear and current.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  HearthButton(
                    label: 'Share Invite',
                    icon: const Icon(HugeIcons.strokeRoundedShare01),
                    onPressed: () async {
                      final text = await ref
                          .read(householdRepositoryProvider)
                          .buildInviteShareText(household.id);
                      await SharePlus.instance.share(ShareParams(text: text));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            HearthButton(
              label: 'Open Invite Screen',
              variant: HearthButtonVariant.ghost,
              onPressed: () => context.push(InviteScreen.routePath),
            ),
            const SizedBox(height: AppSpacing.sm),
            HearthButton(
              label: 'Join Another Household',
              variant: HearthButtonVariant.ghost,
              onPressed: () => context.push(JoinHouseholdScreen.routePath),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
    );
  }
}
