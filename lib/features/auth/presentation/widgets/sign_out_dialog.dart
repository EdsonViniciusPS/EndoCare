import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';

/// Exibe o diálogo de confirmação antes de deslogar o usuário.
/// Retorna `true` se o usuário confirmou a saída.
Future<bool> showConfirmSignOutDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      icon: const Icon(
        Icons.logout_rounded,
        size: 32,
        color: AppColors.error,
      ),
      title: const Text(
        'Deseja sair da conta?',
        textAlign: TextAlign.center,
      ),
      content: const Text(
        'Ao sair, você precisará informar seu e-mail e senha para acessar seus registros novamente.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sair'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

/// Solicita confirmação e encerra a sessão caso o usuário confirme.
Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showConfirmSignOutDialog(context);
  if (confirmed && context.mounted) {
    await ref.read(authRepositoryProvider).signOut();
  }
}

