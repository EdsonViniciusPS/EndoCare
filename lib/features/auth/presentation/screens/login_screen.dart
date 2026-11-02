import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/features/auth/domain/models/auth_failure.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/auth/presentation/utils/auth_validators.dart';
import 'package:endocare/features/auth/presentation/widgets/auth_page_scaffold.dart';

/// Tela de login por e-mail e senha.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Não foi possível entrar agora. Tente novamente em instantes.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuthPageScaffold(
      title: 'Que bom ter você aqui',
      subtitle: 'Entre na sua conta para acompanhar seus sintomas e seu ciclo.',
      errorMessage: _errorMessage,
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Ainda não tem conta? ', style: textTheme.bodyMedium),
          EndoCareButton(
            label: 'Criar minha conta',
            variant: EndoCareButtonVariant.text,
            onPressed: _isSubmitting
                ? null
                : () => context.push(AppRoutes.register),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.validateEmail,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'voce@exemplo.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: AuthValidators.validatePassword,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: EndoCareButton(
                label: 'Esqueci minha senha',
                variant: EndoCareButtonVariant.text,
                onPressed: _isSubmitting
                    ? null
                    : () => context.push(AppRoutes.forgotPassword),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            EndoCareButton(
              label: 'Entrar',
              isLoading: _isSubmitting,
              isExpanded: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

