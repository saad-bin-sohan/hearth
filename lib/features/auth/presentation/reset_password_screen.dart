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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({required this.email, super.key});

  static const String routePath = '/auth/reset-password';

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return AuthScaffold(
      title: 'Choose a new password',
      subtitle: 'Use a strong password for ${widget.email}.',
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            HearthTextField(
              label: 'New Password',
              controller: _passwordController,
              validator: Validators.password,
              obscureText: true,
            ),
            const SizedBox(height: AppSpacing.md),
            HearthTextField(
              label: 'Confirm Password',
              controller: _confirmController,
              obscureText: true,
              validator: (String? value) {
                if (value != _passwordController.text) {
                  return 'Passwords must match.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            HearthButton(
              label: 'Update Password',
              isLoading: authState.status == AuthStatus.loading,
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) {
                  return;
                }
                await ref.read(authNotifierProvider.notifier).resetPassword(
                      email: widget.email,
                      newPassword: _passwordController.text,
                    );
                if (!context.mounted) {
                  return;
                }
                context.go(SignInScreen.routePath);
              },
            ),
          ],
        ),
      ),
    );
  }
}
