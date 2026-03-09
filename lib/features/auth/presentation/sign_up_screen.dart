import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/validators.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/auth/presentation/auth_notifier.dart';
import 'package:hearth/features/auth/presentation/sign_in_screen.dart';
import 'package:hearth/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:hearth/features/household/presentation/create_household_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  static const String routePath = '/auth/sign-up';

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
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
      title: 'Create your account',
      subtitle:
          'Start with a secure local account. Cloud sync arrives in Phase 7.',
      footer: Center(
        child: TextButton(
          onPressed: () => context.go(SignInScreen.routePath),
          child: const Text('Already have an account? Sign in'),
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
            Text(
              'Passwords stay on-device for now and are hashed before storage.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            HearthButton(
              label: 'Create Account',
              isLoading: authState.status == AuthStatus.loading,
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) {
                  return;
                }
                await ref
                    .read(authNotifierProvider.notifier)
                    .signUp(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                if (!context.mounted) {
                  return;
                }
                final authState = ref.read(authNotifierProvider);
                if (authState.status == AuthStatus.authenticated) {
                  context.go(CreateHouseholdScreen.routePath);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
