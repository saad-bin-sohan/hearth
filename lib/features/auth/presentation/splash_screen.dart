import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/features/auth/presentation/auth_notifier.dart';
import 'package:hearth/features/auth/presentation/onboarding_screen.dart';
import 'package:hearth/features/auth/presentation/sign_in_screen.dart';
import 'package:hearth/features/home/presentation/home_screen.dart';
import 'package:hearth/features/household/presentation/create_household_screen.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';
import 'package:hugeicons/hugeicons.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const String routePath = '/splash';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppAnimations.slow)
      ..forward();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await ref.read(sessionControllerProvider.notifier).bootstrap();
    await ref.read(authNotifierProvider.notifier).hydrate();
    await Future<void>.delayed(AppAnimations.slow);
    if (!mounted) {
      return;
    }

    final session = ref.read(sessionControllerProvider);
    if (!session.onboardingComplete) {
      context.go(OnboardingScreen.routePath);
      return;
    }

    if (!session.hasSession) {
      context.go(SignInScreen.routePath);
      return;
    }

    final household = await ref.read(currentHouseholdProvider.future);
    if (!mounted) {
      return;
    }

    if (household == null) {
      context.go(CreateHouseholdScreen.routePath);
    } else {
      context.go(HomeScreen.routePath);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              AppColors.backgroundFor(brightness),
              AppColors.surfaceVariantFor(brightness),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainerFor(brightness),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    HugeIcons.strokeRoundedFirePit,
                    size: 36,
                    color: AppColors.primaryFor(brightness),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Hearth',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primaryFor(brightness),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Makes the home feel like it runs itself.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryFor(brightness),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
