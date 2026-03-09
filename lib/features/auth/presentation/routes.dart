import 'package:go_router/go_router.dart';
import 'package:hearth/features/auth/presentation/forgot_password_screen.dart';
import 'package:hearth/features/auth/presentation/onboarding_screen.dart';
import 'package:hearth/features/auth/presentation/reset_password_screen.dart';
import 'package:hearth/features/auth/presentation/sign_in_screen.dart';
import 'package:hearth/features/auth/presentation/sign_up_screen.dart';
import 'package:hearth/features/auth/presentation/splash_screen.dart';

List<RouteBase> get authRoutes => <RouteBase>[
  GoRoute(
    path: SplashScreen.routePath,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: OnboardingScreen.routePath,
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(
    path: SignInScreen.routePath,
    builder: (context, state) => const SignInScreen(),
  ),
  GoRoute(
    path: SignUpScreen.routePath,
    builder: (context, state) => const SignUpScreen(),
  ),
  GoRoute(
    path: ForgotPasswordScreen.routePath,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: ResetPasswordScreen.routePath,
    builder: (context, state) =>
        ResetPasswordScreen(email: state.uri.queryParameters['email'] ?? ''),
  ),
];
