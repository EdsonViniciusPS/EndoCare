import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/home/domain/models/home_summary_data.dart';
import 'package:endocare/features/home/presentation/providers/home_providers.dart';

/// Aba 1 — Tela Início (dashboard com saudação, ilustração contextual rotativa,
/// atalho de registro rápido, resumo do dia e próximos lembretes).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabeçalho de boas-vindas e data
              Text(
                summary.formattedDate,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summary.greeting,
                style: textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Card principal com ilustração contextual rotativa e atalho de registro
              _HomeHeroCard(summary: summary)
                  .animate()
                  .fadeIn(duration: 340.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.xl),

              // 3. Resumo de hoje
              Text(
                'Resumo de hoje',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _DailySummaryGrid(summary: summary)
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 340.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.xl),

              // 3b. Mapa corporal e heatmap histórico
              _BodyMapHomeCard()
                  .animate()
                  .fadeIn(delay: 110.ms, duration: 340.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.xl),

              // 4. Próximos lembretes
              Text(
                'Próximos lembretes',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _UpcomingRemindersCard(reminders: summary.upcomingReminders)
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 340.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({required this.summary});

  final HomeSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return EndoCareCard(
      elevated: true,
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 360;
              if (isCompact) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: AppSpacing.borderRadiusLg,
                      ),
                      child: StorysetIllustration(
                        asset: summary.heroIllustration,
                        height: 135,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _HeroTextContent(summary: summary),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _HeroTextContent(summary: summary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: AppSpacing.borderRadiusLg,
                      ),
                      child: StorysetIllustration(
                        asset: summary.heroIllustration,
                        height: 130,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          EndoCareButton(
            label: summary.hasLoggedToday
                ? 'Atualizar registro de hoje'
                : 'Registrar como estou hoje',
            icon: summary.hasLoggedToday
                ? Icons.edit_note_rounded
                : Icons.add_circle_outline_rounded,
            isExpanded: true,
            onPressed: () => context.go(AppRoutes.quickLog),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Registro rápido em poucos segundos, sem formulários longos.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _HeroTextContent extends StatelessWidget {
  const _HeroTextContent({required this.summary});

  final HomeSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: const BoxDecoration(
            color: AppColors.secondaryContainer,
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          child: Text(
            'Como você está agora?',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          summary.supportiveMessage,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _DailySummaryGrid extends StatelessWidget {
  const _DailySummaryGrid({required this.summary});

  final HomeSummaryData summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _SummaryMetricCard(
            icon: Icons.healing_outlined,
            accentColor: summary.todayPainLevel != null
                ? AppColors.forPainLevel(summary.todayPainLevel!)
                : AppColors.primary,
            containerColor: AppColors.primaryContainer,
            title: 'Dor hoje',
            value: summary.painStatusLabel,
            subtitle: summary.painStatusSubtitle,
            onTap: () => context.go(AppRoutes.quickLog),
          ),
          _SummaryMetricCard(
            icon: Icons.calendar_month_rounded,
            accentColor: AppColors.tertiary,
            containerColor: AppColors.tertiaryContainer,
            title: 'Ciclo',
            value: summary.cycleStatusLabel,
            subtitle: summary.cycleStatusSubtitle,
            onTap: () => context.go(AppRoutes.calendar),
          ),
          _SummaryMetricCard(
            icon: Icons.spa_outlined,
            accentColor: AppColors.info,
            containerColor: AppColors.infoContainer,
            title: 'Bem-estar',
            value: summary.wellnessStatusLabel,
            subtitle: summary.wellnessStatusSubtitle,
            onTap: () => context.go(AppRoutes.quickLog),
          ),
        ];

        if (constraints.maxWidth < 460) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              cards[2],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: cards[1]),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.icon,
    required this.accentColor,
    required this.containerColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final Color containerColor;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return EndoCareCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(icon, size: 19, color: accentColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _UpcomingRemindersCard extends StatelessWidget {
  const _UpcomingRemindersCard({required this.reminders});

  final List<HomeReminderPreview> reminders;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (reminders.isEmpty) {
      return EndoCareCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhum lembrete pendente hoje',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cadastre medicamentos e consultas na aba Cuidar para vê-los aqui.',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              tooltip: 'Ir para Cuidar',
              onPressed: () => context.go(AppRoutes.care),
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return EndoCareCard(
      child: Column(
        children: reminders
            .map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primary,
                ),
                title: Text(item.title, style: textTheme.titleSmall),
                subtitle: Text(item.subtitle, style: textTheme.bodySmall),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BodyMapHomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return EndoCareCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const StorysetIllustration(
                asset: AppAssets.femaleBodyShapesAmico,
                height: 60,
                width: 60,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mapa corporal da dor',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toque na silhueta frente e costas ou visualize o heatmap histórico para suas consultas.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            children: [
              EndoCareButton(
                label: 'Marcar no mapa',
                icon: Icons.accessibility_new_rounded,
                variant: EndoCareButtonVariant.secondary,
                onPressed: () => context.push(AppRoutes.bodyMap),
              ),
              EndoCareButton(
                label: 'Heatmap histórico',
                icon: Icons.insights_rounded,
                variant: EndoCareButtonVariant.text,
                onPressed: () =>
                    context.push('${AppRoutes.bodyMap}?modo=heatmap'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
