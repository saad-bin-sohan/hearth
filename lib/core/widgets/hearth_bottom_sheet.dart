import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';

Future<T?> showHearthBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double initialChildSize = 0.72,
  double minChildSize = 0.4,
  double maxChildSize = 0.92,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlay,
    builder: (BuildContext context) {
      return HearthBottomSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        child: builder(context),
      );
    },
  );
}

class HearthBottomSheet extends StatefulWidget {
  const HearthBottomSheet({
    required this.child,
    this.initialChildSize = 0.72,
    this.minChildSize = 0.4,
    this.maxChildSize = 0.92,
    super.key,
  });

  final Widget child;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  State<HearthBottomSheet> createState() => _HearthBottomSheetState();
}

class _HearthBottomSheetState extends State<HearthBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.emphasized,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curved),
      child: DraggableScrollableSheet(
        initialChildSize: widget.initialChildSize,
        minChildSize: widget.minChildSize,
        maxChildSize: widget.maxChildSize,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(brightness),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.radiusLg),
              ),
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.dividerFor(brightness),
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.xl,
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
