import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/validators.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/auth/presentation/auth_notifier.dart';
import 'package:hearth/features/auth/presentation/reset_password_screen.dart';
import 'package:hearth/features/auth/presentation/widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const String routePath = '/auth/forgot-password';

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return AuthScaffold(
      title: 'Reset your password',
      subtitle: 'We verify the local account and let you set a new password right away.',
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            HearthTextField(
              label: 'Email',
              controller: _emailController,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            HearthButton(
              label: 'Continue',
              isLoading: authState.status == AuthStatus.loading,
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) {
                  return;
                }
                await ref
                    .read(authNotifierProvider.notifier)
                    .requestPasswordReset(_emailController.text);
                final state = ref.read(authNotifierProvider);
                if (!context.mounted) {
                  return;
                }
                if (state.status != AuthStatus.error) {
                  final encoded = Uri.encodeComponent(_emailController.text.trim());
                  context.push('${ResetPasswordScreen.routePath}?email=$encoded');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
