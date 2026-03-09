import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/animated/hearth_celebration.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/home/presentation/home_screen.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';

class JoinHouseholdConfirmScreen extends ConsumerStatefulWidget {
  const JoinHouseholdConfirmScreen({required this.inviteCode, super.key});

  static const String routePath = '/household/join/confirm';

  final String inviteCode;

  @override
  ConsumerState<JoinHouseholdConfirmScreen> createState() =>
      _JoinHouseholdConfirmScreenState();
}

class _JoinHouseholdConfirmScreenState
    extends ConsumerState<JoinHouseholdConfirmScreen> {
  final ValueNotifier<bool> _showCelebration = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _showCelebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(invitePreviewProvider(widget.inviteCode));
    final actionState = ref.watch(householdNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Join')),
      body: Stack(
        children: <Widget>[
          previewAsync.when(
            data: (preview) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'You’re joining ${preview.household.name}',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HearthCard(
                      child: Row(
                        children: <Widget>[
                          HearthAvatar(
                            displayName: preview.household.name,
                            size: 56,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${preview.household.emoji} ${preview.household.name}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${preview.memberCount} members • ${preview.household.currencyCode}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    HearthButton(
                      label: 'Join Household',
                      isLoading: actionState.isLoading,
                      onPressed: () async {
                        await ref
                            .read(householdNotifierProvider.notifier)
                            .joinHousehold(widget.inviteCode);
                        _showCelebration.value = true;
                        await Future<void>.delayed(
                          const Duration(milliseconds: 700),
                        );
                        if (context.mounted) {
                          context.go(HomeScreen.routePath);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _showCelebration,
            builder: (context, show, _) {
              return show
                  ? HearthCelebration(
                      onCompleted: () => _showCelebration.value = false,
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
