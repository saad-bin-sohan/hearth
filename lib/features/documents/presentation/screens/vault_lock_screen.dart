import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/documents/presentation/vault_lock_provider.dart';
import 'package:hugeicons/hugeicons.dart';

class VaultLockScreen extends ConsumerStatefulWidget {
  const VaultLockScreen({this.isAuthenticating = false, super.key});

  final bool isAuthenticating;

  @override
  ConsumerState<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends ConsumerState<VaultLockScreen> {
  Future<void> _handleUnlock() async {
    final unlockLabel = await ref.read(vaultUnlockLabelProvider.future);
    if (!mounted) {
      return;
    }
    if (unlockLabel == 'Enter PIN') {
      await _showPinSheet();
      return;
    }
    await ref.read(vaultLockProvider.notifier).requestUnlock();
    if (!mounted) {
      return;
    }
    if (ref.read(vaultLockProvider) != VaultLockState.unlocked) {
      await _showPinSheet();
    }
  }

  Future<void> _showPinSheet() async {
    final hasPin = await ref.read(vaultHasPinProvider.future);
    if (!mounted) {
      return;
    }
    await showHearthBottomSheet<void>(
      context: context,
      initialChildSize: 0.64,
      maxChildSize: 0.78,
      builder: (BuildContext context) {
        return _VaultPinSheet(hasExistingPin: hasPin);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockLabelAsync = ref.watch(vaultUnlockLabelProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppSpacing.xxl + AppSpacing.xxl,
              height: AppSpacing.xxl + AppSpacing.xxl,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                HugeIcons.strokeRoundedFirePit,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Document Vault',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.surface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Icon(
              HugeIcons.strokeRoundedLock,
              size: 48,
              color: AppColors.surface,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This vault is protected',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.surface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            unlockLabelAsync.when(
              data: (String unlockLabel) => HearthButton(
                label: unlockLabel,
                icon: Icon(
                  unlockLabel.contains('PIN')
                      ? HugeIcons.strokeRoundedSquareLock02
                      : HugeIcons.strokeRoundedFingerprintScan,
                ),
                isLoading: widget.isAuthenticating,
                onPressed: widget.isAuthenticating ? null : _handleUnlock,
              ),
              loading: () => const HearthButton(
                label: 'Preparing secure access',
                onPressed: null,
                isLoading: true,
              ),
              error: (_, __) => HearthButton(
                label: 'Enter PIN',
                icon: const Icon(HugeIcons.strokeRoundedSquareLock02),
                isLoading: widget.isAuthenticating,
                onPressed: widget.isAuthenticating ? null : _handleUnlock,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PinStage { enter, create, confirm }

class _VaultPinSheet extends ConsumerStatefulWidget {
  const _VaultPinSheet({required this.hasExistingPin});

  final bool hasExistingPin;

  @override
  ConsumerState<_VaultPinSheet> createState() => _VaultPinSheetState();
}

class _VaultPinSheetState extends ConsumerState<_VaultPinSheet> {
  late _PinStage _stage;
  String _pin = '';
  String _firstPin = '';
  String? _errorMessage;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _stage = widget.hasExistingPin ? _PinStage.enter : _PinStage.create;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          switch (_stage) {
            _PinStage.enter => 'Enter PIN',
            _PinStage.create => 'Create a 4-digit PIN',
            _PinStage.confirm => 'Confirm your PIN',
          },
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          switch (_stage) {
            _PinStage.enter => 'Use your four-digit vault PIN to unlock this screen.',
            _PinStage.create =>
              'This device does not have biometrics ready. Set a vault PIN to continue.',
            _PinStage.confirm => 'Re-enter the same four digits to finish vault setup.',
          },
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryFor(brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(4, (int index) {
            final filled = index < _pin.length;
            return Container(
              width: AppSpacing.lg,
              height: AppSpacing.lg,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: filled
                    ? AppColors.primaryFor(brightness)
                    : AppColors.surfaceVariantFor(brightness),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorFor(brightness),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.2,
          children: <Widget>[
            ...List<Widget>.generate(9, (int index) {
              return _PinButton(
                label: '${index + 1}',
                onTap: _submitting ? null : () => _appendDigit('${index + 1}'),
              );
            }),
            const SizedBox.shrink(),
            _PinButton(
              label: '0',
              onTap: _submitting ? null : () => _appendDigit('0'),
            ),
            _PinButton(
              icon: HugeIcons.strokeRoundedDelete02,
              onTap: _submitting || _pin.isEmpty ? null : _removeDigit,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _appendDigit(String digit) async {
    if (_pin.length >= 4) {
      return;
    }
    setState(() {
      _pin = '$_pin$digit';
      _errorMessage = null;
    });
    if (_pin.length == 4) {
      await _submitPin();
    }
  }

  void _removeDigit() {
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _submitPin() async {
    setState(() {
      _submitting = true;
    });
    if (_stage == _PinStage.enter) {
      final success = await ref.read(vaultLockProvider.notifier).validatePin(_pin);
      if (!mounted) {
        return;
      }
      if (success) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _pin = '';
        _submitting = false;
        _errorMessage = 'That PIN does not match.';
      });
      return;
    }
    if (_stage == _PinStage.create) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _submitting = false;
        _stage = _PinStage.confirm;
      });
      return;
    }
    if (_pin != _firstPin) {
      setState(() {
        _pin = '';
        _firstPin = '';
        _submitting = false;
        _stage = _PinStage.create;
        _errorMessage = 'The PINs did not match. Try again.';
      });
      return;
    }
    await ref.read(vaultLockProvider.notifier).setPin(_pin);
    await ref.read(vaultLockProvider.notifier).validatePin(_pin);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return HearthCard(
      onTap: onTap,
      backgroundColor: AppColors.surfaceVariantFor(brightness),
      child: Center(
        child: label != null
            ? Text(
                label!,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimaryFor(brightness),
                ),
              )
            : Icon(
                icon,
                size: 24,
                color: AppColors.textPrimaryFor(brightness),
              ),
      ),
    );
  }
}
