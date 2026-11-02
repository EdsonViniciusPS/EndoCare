import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/core/widgets/storyset_illustration.dart';
import 'package:endocare/features/auth/domain/models/auth_failure.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/auth/presentation/widgets/auth_page_scaffold.dart';

/// Tela de confirmação de e-mail exigida pelo guard antes de liberar os dados.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  String? _errorMessage;

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final refreshed =
          await ref.read(authRepositoryProvider).reloadCurrentUser();
      if (!mounted) return;
      if (refreshed != null && !refreshed.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ainda não identificamos a confirmação. Verifique sua caixa de entrada e spam.',
            ),
          ),
        );
      }
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reenviamos o link de confirmação para o seu e-mail.',
          ),
        ),
      );
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authUser = ref.watch(authStateChangesProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    final emailLabel = authUser?.email.isNotEmpty == true
        ? authUser!.email
        : 'seu e-mail';

    return AuthPageScaffold(
      title: 'Confirme seu e-mail',
      subtitle: 'Enviamos um link de confirmação para $emailLabel.',
      errorMessage: _errorMessage,
      footer: EndoCareButton(
        label: 'Sair ou usar outro e-mail',
        icon: Icons.logout_rounded,
        variant: EndoCareButtonVariant.text,
        onPressed: _isChecking || _isResending ? null : _signOut,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StorysetIllustration(
            asset: AppAssets.peaceOfMindBro,
            height: 155,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Essa etapa protege a privacidade dos seus registros de saúde. Assim que clicar no link recebido, toque no botão abaixo.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          EndoCareButton(
            label: 'Já confirmei meu e-mail',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _isChecking,
            isExpanded: true,
            onPressed: _isResending ? null : _checkVerification,
          ),
          const SizedBox(height: AppSpacing.sm),
          EndoCareButton(
            label: 'Reenviar e-mail de confirmação',
            variant: EndoCareButtonVariant.tonal,
            isLoading: _isResending,
            isExpanded: true,
            onPressed: _isChecking ? null : _resendEmail,
          ),
        ],
      ),
    );
  }
}

