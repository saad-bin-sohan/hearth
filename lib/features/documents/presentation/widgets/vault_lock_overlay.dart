import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/features/documents/presentation/screens/vault_lock_screen.dart';
import 'package:hearth/features/documents/presentation/vault_lock_provider.dart';

class VaultLockOverlay extends ConsumerStatefulWidget {
  const VaultLockOverlay({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<VaultLockOverlay> createState() => _VaultLockOverlayState();
}

class _VaultLockOverlayState extends ConsumerState<VaultLockOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ProviderSubscription<VaultLockState>? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
      value: ref.read(vaultLockProvider) == VaultLockState.unlocked ? 0 : 1,
    );
    _subscription = ref.listenManual<VaultLockState>(
      vaultLockProvider,
      (VaultLockState? previous, VaultLockState next) {
        if (next == VaultLockState.unlocked) {
          _controller.reverse();
          return;
        }
        _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(vaultLockProvider);
    return Listener(
      onPointerDown: (_) => ref.read(vaultLockProvider.notifier).registerActivity(),
      onPointerSignal: (_) =>
          ref.read(vaultLockProvider.notifier).registerActivity(),
      child: Stack(
        children: <Widget>[
          widget.child,
          if (lockState != VaultLockState.unlocked || _controller.value > 0)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: lockState == VaultLockState.unlocked,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    final blur = 12 * _controller.value;
                    return Opacity(
                      opacity: _controller.value,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: blur,
                                sigmaY: blur,
                              ),
                              child: Container(
                                color: AppColors.overlay.withValues(
                                  alpha: 0.6 * _controller.value,
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Transform.scale(
                                scale: 0.92 + (0.08 * _controller.value),
                                child: VaultLockScreen(
                                  isAuthenticating:
                                      lockState == VaultLockState.authenticating,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
