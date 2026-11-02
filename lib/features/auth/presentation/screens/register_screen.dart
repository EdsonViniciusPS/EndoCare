import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/features/auth/domain/models/auth_failure.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/auth/presentation/utils/auth_validators.dart';
import 'package:endocare/features/auth/presentation/widgets/auth_page_scaffold.dart';

/// Tela de cadastro com criação do documento `users/{uid}` e envio de verificação.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _birthDate;
  bool _lgpdAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, 6, 15);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: now,
      helpText: 'Selecione sua data de nascimento',
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_lgpdAccepted) {
      setState(() {
        _errorMessage =
            'Para continuar, confirme o consentimento de proteção dos seus dados de saúde (LGPD).';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).registerWithEmailAndPassword(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            birthDate: _birthDate,
          );
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Não foi possível criar sua conta agora. Tente novamente.',
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
    final birthDateLabel = _birthDate != null
        ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_birthDate!)
        : 'Data de nascimento (opcional)';

    return AuthPageScaffold(
      showBackButton: true,
      title: 'Crie sua conta',
      subtitle: 'Poucos campos para você começar a cuidar de si com leveza.',
      errorMessage: _errorMessage,
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Já tem uma conta? ', style: textTheme.bodyMedium),
          EndoCareButton(
            label: 'Entrar',
            variant: EndoCareButtonVariant.text,
            onPressed: _isSubmitting
                ? null
                : () => context.go(AppRoutes.login),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: AuthValidators.validateName,
              decoration: const InputDecoration(
                labelText: 'Como prefere ser chamada?',
                hintText: 'Ex.: Mariana',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _isSubmitting ? null : _pickBirthDate,
              borderRadius: AppSpacing.borderRadiusMd,
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: _birthDate != null
                      ? IconButton(
                          tooltip: 'Limpar data',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _birthDate = null),
                        )
                      : const Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  birthDateLabel,
                  style: _birthDate != null
                      ? textTheme.bodyLarge
                      : textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: AuthValidators.validatePassword,
              decoration: InputDecoration(
                labelText: 'Senha',
                hintText: 'Mínimo de 6 caracteres',
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
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              validator: (val) => AuthValidators.validateConfirmPassword(
                val,
                _passwordController.text,
              ),
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirmar senha',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirm ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _isSubmitting
                  ? null
                  : () => setState(() => _lgpdAccepted = !_lgpdAccepted),
              borderRadius: AppSpacing.borderRadiusSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _lgpdAccepted,
                      activeColor: AppColors.primary,
                      onChanged: _isSubmitting
                          ? null
                          : (val) {
                              setState(() => _lgpdAccepted = val ?? false);
                            },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Autorizo o tratamento dos meus registros de saúde exclusivamente para meu acompanhamento no EndoCare (LGPD).',
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            EndoCareButton(
              label: 'Criar minha conta',
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

