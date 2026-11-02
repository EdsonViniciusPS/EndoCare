import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';

/// Aba 5 — Mais (exibe o resumo de `users/{uid}`, logout e módulos adicionais).
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final authUser = ref.watch(authStateChangesProvider).asData?.value;
    final profile = ref.watch(currentUserProfileProvider).asData?.value;

    final displayName =
        profile?.nome ?? authUser?.displayName ?? 'Usuária EndoCare';
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : (authUser?.email ?? '');

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EndoCareCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            displayName.trim().isNotEmpty
                                ? displayName.trim()[0].toUpperCase()
                                : 'E',
                            style: textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: textTheme.titleMedium,
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: textTheme.bodySmall,
                                ),
                              const SizedBox(height: AppSpacing.xxs),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Conta verificada e protegida',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EndoCareButton(
                      label: 'Rever apresentação inicial',
                      icon: Icons.auto_awesome_outlined,
                      variant: EndoCareButtonVariant.tonal,
                      isExpanded: true,
                      onPressed: () {
                        context.go('${AppRoutes.onboarding}?rever=1');
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    EndoCareButton(
                      label: 'Sair da conta',
                      icon: Icons.logout_rounded,
                      variant: EndoCareButtonVariant.outlined,
                      isExpanded: true,
                      onPressed: () {
                        ref.read(authRepositoryProvider).signOut();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Diário de impacto na rotina
              EndoCareCard(
                elevated: true,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.work_history_outlined,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diário de impacto',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Avalie o efeito da dor em trabalho, estudos, sono, exercícios, relacionamentos e rotina.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EndoCareButton(
                      label: 'Abrir diário de impacto',
                      icon: Icons.edit_note_rounded,
                      variant: EndoCareButtonVariant.tonal,
                      isExpanded: true,
                      onPressed: () => context.push(AppRoutes.impact),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Linha do tempo da doença
              EndoCareCard(
                elevated: true,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timeline_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Linha do tempo da doença',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Visualização cronológica unificada de crises, consultas, cirurgias, tratamentos e mudanças.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EndoCareButton(
                      label: 'Ver linha do tempo',
                      icon: Icons.timeline_rounded,
                      isExpanded: true,
                      onPressed: () => context.push(AppRoutes.timeline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              EndoCareCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    const StorysetIllustration(
                      asset: AppAssets.womanReadingPana,
                      height: 150,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Mais recursos',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Assistente educativo, relatórios para médicos, biblioteca de conhecimento, linha do tempo e configurações.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
