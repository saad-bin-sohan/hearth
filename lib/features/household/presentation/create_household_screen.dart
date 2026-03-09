import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/validators.dart';
import 'package:hearth/core/widgets/animated/hearth_celebration.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hearth/features/household/presentation/invite_screen.dart';
import 'package:hearth/features/household/presentation/widgets/emoji_picker_sheet.dart';

class CreateHouseholdScreen extends ConsumerStatefulWidget {
  const CreateHouseholdScreen({super.key});

  static const String routePath = '/household/create';

  @override
  ConsumerState<CreateHouseholdScreen> createState() =>
      _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends ConsumerState<CreateHouseholdScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final ValueNotifier<String> _emoji = ValueNotifier<String>('🏡');
  final ValueNotifier<String> _colorKey = ValueNotifier<String>('terracotta');
  final ValueNotifier<String> _currency = ValueNotifier<String>('USD');
  final ValueNotifier<bool> _showCelebration = ValueNotifier<bool>(false);

  static const Map<String, Color> _swatches = <String, Color>{
    'terracotta': AppColors.primary,
    'olive': AppColors.secondary,
    'amber': AppColors.accent,
    'cream': AppColors.primaryLight,
  };

  static const List<String> _currencies = <String>[
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'SGD',
    'AED',
    'INR',
    'BDT',
    'JPY',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emoji.dispose();
    _colorKey.dispose();
    _currency.dispose();
    _showCelebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(householdNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Household')),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Set the tone for your home',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choose a name, avatar, and currency so the shared space feels personal from day one.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  HearthCard(
                    child: Column(
                      children: <Widget>[
                        ValueListenableBuilder<String>(
                          valueListenable: _emoji,
                          builder: (context, emoji, _) {
                            return GestureDetector(
                              onTap: () async {
                                final result = await showHearthBottomSheet<String>(
                                  context: context,
                                  builder: (context) => const EmojiPickerSheet(),
                                );
                                if (result != null) {
                                  _emoji.value = result;
                                }
                              },
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: _swatches[_colorKey.value],
                                child: Text(emoji, style: const TextStyle(fontSize: 32)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () async {
                            final result = await showHearthBottomSheet<String>(
                              context: context,
                              builder: (context) => const EmojiPickerSheet(),
                            );
                            if (result != null) {
                              _emoji.value = result;
                            }
                          },
                          child: const Text('Choose Emoji'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  HearthTextField(
                    label: 'Household Name',
                    controller: _nameController,
                    validator: Validators.householdName,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Avatar Color', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  ValueListenableBuilder<String>(
                    valueListenable: _colorKey,
                    builder: (context, colorKey, _) {
                      return Wrap(
                        spacing: AppSpacing.sm,
                        children: _swatches.entries.map((entry) {
                          final selected = entry.key == colorKey;
                          return GestureDetector(
                            onTap: () => _colorKey.value = entry.key,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Currency', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  ValueListenableBuilder<String>(
                    valueListenable: _currency,
                    builder: (context, currency, _) {
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _currencies
                            .map(
                              (code) => HearthChip(
                                label: code,
                                selected: code == currency,
                                onTap: () => _currency.value = code,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  if (actionState.message != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      actionState.message!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  HearthButton(
                    label: 'Create Household',
                    isLoading: actionState.isLoading,
                    onPressed: () async {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      await ref.read(householdNotifierProvider.notifier).createHousehold(
                            name: _nameController.text,
                            emoji: _emoji.value,
                            avatarColorKey: _colorKey.value,
                            currencyCode: _currency.value,
                          );
                      _showCelebration.value = true;
                      await Future<void>.delayed(const Duration(milliseconds: 700));
                      if (context.mounted) {
                        context.go(InviteScreen.routePath);
                      }
                    },
                  ),
                ],
              ),
            ),
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
