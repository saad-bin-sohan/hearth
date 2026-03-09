import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/validators.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/auth/presentation/auth_notifier.dart';
import 'package:hearth/features/auth/presentation/forgot_password_screen.dart';
import 'package:hearth/features/auth/presentation/sign_up_screen.dart';
import 'package:hearth/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:hearth/features/home/presentation/home_screen.dart';
import 'package:hearth/features/household/presentation/create_household_screen.dart';
import 'package:hearth/features/household/presentation/household_notifier.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static const String routePath = '/auth/sign-in';

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  ProviderSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthState>(
      authNotifierProvider,
      _handleAuthChange,
    );
  }

  Future<void> _handleAuthChange(AuthState? previous, AuthState next) async {
    if (!mounted) {
      return;
    }
    if (next.message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.message!)));
      ref.read(authNotifierProvider.notifier).clearMessage();
    }
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to pick up where your household left off.',
      footer: Center(
        child: TextButton(
          onPressed: () => context.go(SignUpScreen.routePath),
          child: const Text('Need an account? Create one'),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            HearthTextField(
              label: 'Email',
              controller: _emailController,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            HearthTextField(
              label: 'Password',
              controller: _passwordController,
              validator: Validators.password,
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(ForgotPasswordScreen.routePath),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HearthButton(
              label: 'Sign In',
              isLoading: authState.status == AuthStatus.loading,
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) {
                  return;
                }
                await ref
                    .read(authNotifierProvider.notifier)
                    .signIn(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                if (!context.mounted) {
                  return;
                }
                final authState = ref.read(authNotifierProvider);
                if (authState.status != AuthStatus.authenticated) {
                  return;
                }
                final household = await ref.read(
                  currentHouseholdProvider.future,
                );
                if (!context.mounted) {
                  return;
                }
                if (household == null) {
                  context.go(CreateHouseholdScreen.routePath);
                } else {
                  context.go(HomeScreen.routePath);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
