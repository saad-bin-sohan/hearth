import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/animated/hearth_number_ticker.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_section_header.dart';
import 'package:hearth/features/home/presentation/home_screen.dart';
import 'package:hearth/features/household/data/local_household_repository.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hearth/features/household/presentation/widgets/qr_placeholder.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key});

  static const String routePath = '/household/invite';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(currentHouseholdProvider);
    final membersAsync = ref.watch(householdMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Members')),
      body: householdAsync.when(
        data: (household) {
          if (household == null) {
            return const Center(child: Text('No household found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              const HearthSectionHeader(
                title: 'Bring your household in',
                subtitle: 'Share the code or show the QR placeholder to add members quickly.',
              ),
              HearthCard(
                child: Column(
                  children: <Widget>[
                    Text(
                      household.inviteCode,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Center(child: QrPlaceholder()),
                    const SizedBox(height: AppSpacing.lg),
                    HearthButton(
                      label: 'Share Invite',
                      icon: const Icon(HugeIcons.strokeRoundedShare01),
                      onPressed: () async {
                        final shareText = await ref
                            .read(householdRepositoryProvider)
                            .buildInviteShareText(household.id);
                        await SharePlus.instance.share(
                          ShareParams(text: shareText),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              HearthCard(
                child: Row(
                  children: <Widget>[
                    const Icon(HugeIcons.strokeRoundedUserGroup),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Current members', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.xs),
                          membersAsync.when(
                            data: (members) => HearthNumberTicker(
                              value: '${members.length}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            loading: () => const Text('...'),
                            error: (_, __) => const Text('0'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              HearthButton(
                label: 'Continue to Home',
                variant: HearthButtonVariant.ghost,
                onPressed: () => context.go(HomeScreen.routePath),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
