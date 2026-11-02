import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_card.dart';
import 'package:endocare/features/calendar/domain/models/cycle_prediction_engine.dart';

/// Cartão de estimativa do ciclo menstrual e ovulação com aviso explícito
/// de que se trata de uma estimativa aproximada.
class CycleEstimateCard extends StatelessWidget {
  const CycleEstimateCard({
    super.key,
    required this.estimate,
  });

  final CycleEstimate estimate;

  String _shortDate(DateTime? date) {
    if (date == null) return '—';
    try {
      return DateFormat("d 'de' MMM", 'pt_BR').format(date);
    } catch (_) {
      return '${date.day}/${date.month}';
    }
  }

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
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.autorenew_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimativa do ciclo e ovulação',
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      estimate.hasCycleHistory
                          ? (estimate.usesDefaultCycleLength
                              ? 'Base inicial de ${estimate.averageCycleLength} dias (registre mais ciclos para personalizar)'
                              : 'Ciclo médio observado: ${estimate.averageCycleLength} dias • Fluxo médio: ${estimate.averagePeriodDuration} dias')
                          : 'Nenhum fluxo menstrual registrado até o momento',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (estimate.hasCycleHistory)
            Row(
              children: [
                Expanded(
                  child: _EstimateMetricTile(
                    icon: Icons.water_drop_outlined,
                    accentColor: AppColors.cycleMenstruation,
                    containerColor: AppColors.errorContainer,
                    label: 'Próximo fluxo (est.)',
                    value: _shortDate(estimate.nextPredictedPeriodStart),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _EstimateMetricTile(
                    icon: Icons.auto_awesome_rounded,
                    accentColor: AppColors.cycleOvulation,
                    containerColor: AppColors.infoContainer,
                    label: 'Ovulação estimada',
                    value: _shortDate(estimate.nextEstimatedOvulationDate),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Text(
                'Toque em um dia do calendário para registrar sua menstruação e ativar as previsões. Se você usa bloqueio hormonal contínuo e não menstrua, seus sintomas e crises continuam sendo acompanhados normalmente.',
                style: textTheme.bodySmall,
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // Aviso obrigatório de estimativa aproximada
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: AppColors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    CyclePredictionEngine.approximateDisclaimer,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onTertiaryContainer,
                      height: 1.38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateMetricTile extends StatelessWidget {
  const _EstimateMetricTile({
    required this.icon,
    required this.accentColor,
    required this.containerColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color accentColor;
  final Color containerColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: containerColor.withValues(alpha: 0.65),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.titleSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

