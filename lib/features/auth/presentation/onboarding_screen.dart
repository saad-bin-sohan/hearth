import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/providers/session_provider.dart';
import 'package:hearth/core/theme/app_animations.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_card.dart';
import 'package:hearth/features/auth/presentation/sign_in_screen.dart';
import 'package:hearth/features/auth/presentation/sign_up_screen.dart';
import 'package:hugeicons/hugeicons.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const String routePath = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const List<_OnboardingStep> _steps = <_OnboardingStep>[
    _OnboardingStep(
      icon: HugeIcons.strokeRoundedHouse03,
      title: 'One calm place for home life',
      body:
          'Replace scattered notes, chats, and spreadsheets with a shared rhythm that lives in one app.',
    ),
    _OnboardingStep(
      icon: HugeIcons.strokeRoundedDashboardSquare02,
      title: 'See the household at a glance',
      body:
          'Quick summaries, activity, and upcoming responsibilities stay visible without feeling noisy.',
    ),
    _OnboardingStep(
      icon: HugeIcons.strokeRoundedUserGroup,
      title: 'Built for adults sharing a home',
      body:
          'Roles, invites, and ownership are designed for couples, roommates, and families living together.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(sessionControllerProvider.notifier).markOnboardingComplete();
    if (mounted) {
      context.go(SignUpScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (int value) {
                    setState(() {
                      _page = value;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final step = _steps[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        HearthCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainerFor(
                                    brightness,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.radiusXl,
                                  ),
                                ),
                                child: Icon(
                                  step.icon,
                                  size: 44,
                                  color: AppColors.primaryFor(brightness),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                step.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                step.body,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.textSecondaryFor(
                                        brightness,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_steps.length, (int index) {
                  final selected = index == _page;
                  return AnimatedContainer(
                    duration: AppAnimations.standard,
                    curve: AppAnimations.easeInOut,
                    width: selected ? 28 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryFor(brightness)
                          : AppColors.dividerFor(brightness),
                      borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              HearthButton(
                label: _page == _steps.length - 1 ? 'Get Started' : 'Next',
                onPressed: () async {
                  if (_page == _steps.length - 1) {
                    await _finish();
                    return;
                  }
                  await _pageController.nextPage(
                    duration: AppAnimations.medium,
                    curve: AppAnimations.easeInOut,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go(SignInScreen.routePath),
                child: const Text('I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
