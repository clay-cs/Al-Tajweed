import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/app_button.dart';
import 'data/auth_repository.dart';
import 'widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthRepository();
  bool _obscure = true;
  bool _agreed = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      context.showSnack(context.l10n.fillAllFields);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.register(name, email, password);
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
              Text(context.l10n.createAccountTitle,
                  style: context.text.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.startJourney,
                style: context.text.bodyLarge
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AuthField(
                label: context.l10n.fullName,
                hint: 'Yusuf Karimov',
                icon: Icons.person_outline_rounded,
                controller: _name,
              ),
              const SizedBox(height: AppSpacing.xl),
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
                hint: context.l10n.passwordHint8,
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
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: context.l10n.agreePrefix,
                        style: context.text.bodySmall,
                        children: [
                          TextSpan(
                            text: context.l10n.termsOfService,
                            style: context.text.bodySmall?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: context.l10n.andWord),
                          TextSpan(
                            text: context.l10n.privacyPolicy,
                            style: context.text.bodySmall?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: context.l10n.agreeSuffix),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: context.l10n.createAccount,
                loading: _loading,
                onPressed: _agreed ? _createAccount : null,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SocialAuthRow(),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.l10n.haveAccount,
                      style: context.text.bodyMedium),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(Routes.login),
                    child: Text(context.l10n.signInAction),
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
