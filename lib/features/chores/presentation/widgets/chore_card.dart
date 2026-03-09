import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/theme/app_text_styles.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/chores/domain/chore_models.dart';
import 'package:hearth/features/chores/presentation/widgets/chore_streak_badge.dart';
import 'package:hugeicons/hugeicons.dart';

class ChoreCard extends StatelessWidget {
  const ChoreCard({
    required this.chore,
    required this.memberDisplayNames,
    this.onTap,
    this.animateCompletion = false,
    super.key,
  });

  final ChoreEntity chore;
  final Map<String, String> memberDisplayNames;
  final VoidCallback? onTap;
  final bool animateCompletion;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dueMeta = _dueMeta(context);

    return HearthCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: AppSpacing.xs,
            height: 72,
            decoration: BoxDecoration(
              color: _areaColor(brightness),
              borderRadius: BorderRadius.circular(AppRadius.radiusFull),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (animateCompletion)
                      TweenAnimationBuilder<double>(
                        duration: AppAnimations.standard,
                        tween: Tween<double>(begin: 0, end: 1),
                        builder:
                            (
                              BuildContext context,
                              double value,
                              Widget? child,
                            ) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primaryFor(brightness),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            HugeIcons.strokeRoundedTick02,
                            size: 18,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    if (animateCompletion) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _AnimatedStrikeText(
                        text: chore.title,
                        animate: animateCompletion,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${chore.areaTag.label} • ~${chore.estimatedMinutes} min',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: dueMeta.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                  ),
                  child: Text(
                    dueMeta.label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: dueMeta.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (chore.assignmentType == ChoreAssignmentType.rotation)
                _AvatarStack(
                  userIds: chore.assignedToUserIds,
                  memberDisplayNames: memberDisplayNames,
                  highlightedUserId: chore.currentAssigneeUserId,
                )
              else
                HearthAvatar(
                  displayName:
                      memberDisplayNames[chore.currentAssigneeUserId] ??
                      'House',
                  size: 32,
                ),
              const SizedBox(height: AppSpacing.sm),
              ChoreStreakBadge(streakCount: chore.streakCount),
            ],
          ),
        ],
      ),
    );
  }

  _DueMeta _dueMeta(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final due = DateTime(
      chore.nextDueAt.year,
      chore.nextDueAt.month,
      chore.nextDueAt.day,
    );
    final brightness = Theme.of(context).brightness;
    if (due.isBefore(today)) {
      return _DueMeta(label: 'Overdue', color: AppColors.errorFor(brightness));
    }
    if (due == today) {
      return _DueMeta(label: 'Today', color: AppColors.primaryFor(brightness));
    }
    if (due == tomorrow) {
      return _DueMeta(
        label: 'Tomorrow',
        color: AppColors.accentFor(brightness),
      );
    }
    return _DueMeta(
      label: AppFormatters.shortDate(chore.nextDueAt),
      color: AppColors.textTertiaryFor(brightness),
    );
  }

  Color _areaColor(Brightness brightness) {
    return switch (chore.areaTag) {
      ChoreAreaTag.kitchen => AppColors.primaryFor(brightness),
      ChoreAreaTag.bathroom => AppColors.secondaryFor(brightness),
      ChoreAreaTag.living => AppColors.accentFor(brightness),
      ChoreAreaTag.bedroom => AppColors.accentContainerFor(brightness),
      ChoreAreaTag.garden => AppColors.successFor(brightness),
      ChoreAreaTag.general => AppColors.textTertiaryFor(brightness),
    };
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.userIds,
    required this.memberDisplayNames,
    required this.highlightedUserId,
  });

  final List<String> userIds;
  final Map<String, String> memberDisplayNames;
  final String? highlightedUserId;

  @override
  Widget build(BuildContext context) {
    final visibleIds = userIds.take(3).toList();
    return SizedBox(
      width: 32 + ((visibleIds.length - 1) * 20),
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: List<Widget>.generate(visibleIds.length, (int index) {
          final userId = visibleIds[index];
          final isHighlighted = userId == highlightedUserId;
          return Positioned(
            left: index * 20,
            child: Container(
              padding: EdgeInsets.all(isHighlighted ? 2 : 0),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppColors.primaryFor(Theme.of(context).brightness)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: HearthAvatar(
                displayName: memberDisplayNames[userId] ?? 'House',
                size: 32,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AnimatedStrikeText extends StatelessWidget {
  const _AnimatedStrikeText({required this.text, required this.animate});

  final String text;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return TweenAnimationBuilder<double>(
      duration: AppAnimations.standard,
      tween: Tween<double>(begin: 0, end: animate ? 1 : 0),
      builder: (BuildContext context, double value, Widget? child) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimaryFor(brightness),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: null,
                  child: Container(
                    width: constraints.maxWidth * value,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFor(brightness),
                      borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DueMeta {
  const _DueMeta({required this.label, required this.color});

  final String label;
  final Color color;
}
