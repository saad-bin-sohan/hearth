import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/features/grocery/presentation/grocery_notifier.dart';

class MemberPresenceIndicator extends ConsumerStatefulWidget {
  const MemberPresenceIndicator({super.key});

  @override
  ConsumerState<MemberPresenceIndicator> createState() =>
      _MemberPresenceIndicatorState();
}

class _MemberPresenceIndicatorState
    extends ConsumerState<MemberPresenceIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.verySlow,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final currentUserId = ref.watch(groceryCurrentUserIdProvider);
    final activeMembersAsync = ref.watch(activeShoppingMembersProvider);
    return activeMembersAsync.when(
      data: (members) {
        final otherMembers = members
            .where((member) => member.userId != currentUserId)
            .toList();
        if (otherMembers.isEmpty) {
          return const SizedBox.shrink();
        }
        final label = otherMembers.length == 1
            ? '${otherMembers.first.displayName} is shopping'
            : '${otherMembers.length} members shopping';
        return AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final ringOpacity = 0.5 + (_controller.value * 0.5);
            return Row(
              children: <Widget>[
                SizedBox(
                  width: otherMembers.length > 1
                      ? 32 + ((otherMembers.length - 1) * 20)
                      : 32,
                  height: 32,
                  child: Stack(
                    children: List<Widget>.generate(
                      otherMembers.take(3).length,
                      (int index) {
                        final member = otherMembers[index];
                        return Positioned(
                          left: index * 20,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.successFor(
                                  brightness,
                                ).withValues(alpha: ringOpacity),
                                width: 2,
                              ),
                            ),
                            child: HearthAvatar(
                              displayName: member.displayName,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (otherMembers.length > 3) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '+${otherMembers.length - 3}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ),
                Container(
                  width: AppSpacing.sm,
                  height: AppSpacing.sm,
                  decoration: BoxDecoration(
                    color: AppColors.successFor(
                      brightness,
                    ).withValues(alpha: ringOpacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
