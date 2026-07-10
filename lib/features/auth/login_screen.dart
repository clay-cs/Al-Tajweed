import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/app_button.dart';
import 'data/auth_repository.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthRepository();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      context.showSnack(context.l10n.fillAllFields);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.login(email, password);
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Routes.shell, (_) => false);
    } catch (e) {
      if (!mounted) return;
      context.showSnack(
          ApiClient.messageFrom(e, context.l10n.networkError));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.welcomeBack,
                  style: context.text.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.signInToContinue,
                style: context.text.bodyLarge
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AuthField(
                label: context.l10n.email,
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: _email,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthField(
                label: context.l10n.password,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                controller: _password,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 21,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context
                      .showSnack(context.l10n.wiredLater('Password reset')),
                  child: Text(context.l10n.forgotPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                  label: context.l10n.signIn,
                  loading: _loading,
                  onPressed: _signIn),
              const SizedBox(height: AppSpacing.xxl),
              const SocialAuthRow(),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.l10n.noAccount,
                      style: context.text.bodyMedium),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(Routes.register),
                    child: Text(context.l10n.createOne),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
