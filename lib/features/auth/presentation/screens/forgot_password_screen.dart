import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/core/widgets/storyset_illustration.dart';
import 'package:endocare/features/auth/domain/models/auth_failure.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/auth/presentation/utils/auth_validators.dart';
import 'package:endocare/features/auth/presentation/widgets/auth_page_scaffold.dart';

/// Tela de recuperação de senha via e-mail.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
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
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: _emailController.text);
      if (mounted) {
        setState(() => _emailSent = true);
      }
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Não foi possível enviar o link agora. Tente novamente.',
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

    if (_emailSent) {
      return AuthPageScaffold(
        showBackButton: true,
        title: 'Confira seu e-mail',
        subtitle:
            'Enviamos as instruções de redefinição de senha para ${_emailController.text.trim()}.',
        child: Column(
          children: [
            const StorysetIllustration(
              asset: AppAssets.healthyHabitRafiki,
              height: 150,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Caso não encontre na caixa de entrada, dê uma olhadinha também na pasta de spam ou promoções.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            EndoCareButton(
              label: 'Voltar para o login',
              isExpanded: true,
              onPressed: () => context.go(AppRoutes.login),
            ),
          ],
        ),
      );
    }

    return AuthPageScaffold(
      showBackButton: true,
      title: 'Recuperar senha',
      subtitle:
          'Informe o e-mail da sua conta para receber um link seguro de redefinição.',
      errorMessage: _errorMessage,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.validateEmail,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'E-mail cadastrado',
                hintText: 'voce@exemplo.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            EndoCareButton(
              label: 'Enviar link de recuperação',
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

