import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/impact/domain/models/impact_log.dart';

/// Card que sintetiza os últimos dias do Diário de impacto, destacando as áreas
/// mais comprometidas e a frequência de dias com alto impacto.
class ImpactSummaryCard extends StatelessWidget {
  const ImpactSummaryCard({
    super.key,
    required this.summary,
  });

  final ImpactSummary summary;

  Color _severityColor(double val) {
    return AppColors.forPainLevel(val.round());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (summary.daysLogged == 0) {
      return EndoCareCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Panorama dos últimos ${summary.periodDays} dias',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Nenhum registro de impacto salvo nos últimos ${summary.periodDays} dias. Registre como a dor tem afetado suas atividades para visualizar o panorama consolidado.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return EndoCareCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Panorama dos últimos ${summary.periodDays} dias',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Pílulas com total de dias e dias de alto impacto
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${summary.daysLogged} de ${summary.periodDays} dias registrados',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (summary.highImpactDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.painSevere.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.painSevere,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.highImpactDays} dias com alto impacto (≥7)',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.painSevere,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Áreas mais afetadas pela dor:',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Listagem ordenada por média de comprometimento
          ...summary.areaStats.take(4).map((stats) {
            final color = _severityColor(stats.average);
            final ratio = (stats.average / 10.0).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(stats.area.icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          stats.area.label,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${stats.average.toStringAsFixed(1).replaceAll('.', ',')}/10',
                        style: textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${stats.daysRegistered} d)',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: AppColors.outline.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
