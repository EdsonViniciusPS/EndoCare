import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_card.dart';
import 'package:endocare/features/calendar/domain/models/cycle_prediction_engine.dart';
import 'package:endocare/features/calendar/domain/models/cycle_symptom_correlation.dart';

/// Gráficos `fl_chart` de cruzamento descritivo Ciclo × Sintomas (sem afirmar causalidade).
///
/// 1. `LineChart`: evolução diária da intensidade da dor (0–10) no mês sobreposta
///    às faixas de fluxo menstrual e janela ovulatória estimada.
/// 2. `BarChart`: média descritiva de dor registrada em cada fase/contexto observado.
class CycleSymptomChartsCard extends StatelessWidget {
  const CycleSymptomChartsCard({
    super.key,
    required this.correlation,
  });

  final CycleSymptomCorrelation correlation;

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
                  color: AppColors.primaryContainer,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.stacked_line_chart_rounded,
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
                      'Cruzamento ciclo × sintomas',
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      correlation.hasAnyLoggedSymptoms
                          ? '${correlation.totalSymptomDaysInMonth} ${correlation.totalSymptomDaysInMonth == 1 ? 'dia registrado' : 'dias registrados'} neste mês (${correlation.painDaysOutsideFlowCount} com dor fora do fluxo)'
                          : 'Registre sintomas e dias do ciclo para visualizar padrões do mês',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Aviso clínico obrigatório: sem presumir relação de causa e efeito
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.infoContainer.withValues(alpha: 0.7),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.balance_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    CycleSymptomCorrelation.nonCausalityNotice,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.38,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (!correlation.hasAnyLoggedSymptoms)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Text(
                'Ainda não há sintomas registrados neste mês para traçar os gráficos.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            )
          else ...[
            Text(
              'Dor diária (0–10) ao longo do mês',
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              'Faixas rosadas indicam dias de menstruação; faixas azuis indicam janela ovulatória estimada.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 185,
              child: _buildMonthlyLineChart(textTheme),
            ),

            if (correlation.phaseBuckets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Média descritiva de dor nos dias registrados',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Comparação descritiva entre fases observadas nos seus registros do mês.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 170,
                child: _buildPhaseBarChart(textTheme),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyLineChart(TextTheme textTheme) {
    final loggedPoints = correlation.dailyPoints
        .where((p) => p.hasSymptomLog)
        .toList(growable: false);

    final spots = loggedPoints
        .map((p) => FlSpot(p.dayOfMonth.toDouble(), p.painLevel.toDouble()))
        .toList(growable: false);

    final verticalAnnotations = <VerticalRangeAnnotation>[
      for (final span in correlation.flowSpans)
        VerticalRangeAnnotation(
          x1: (span.startDay - 0.4).clamp(1.0, correlation.daysInMonth.toDouble()),
          x2: (span.endDay + 0.4).clamp(1.0, correlation.daysInMonth.toDouble()),
          color: AppColors.cycleMenstruation.withValues(alpha: 0.14),
        ),
      for (final span in correlation.ovulationSpans)
        VerticalRangeAnnotation(
          x1: (span.startDay - 0.4).clamp(1.0, correlation.daysInMonth.toDouble()),
          x2: (span.endDay + 0.4).clamp(1.0, correlation.daysInMonth.toDouble()),
          color: AppColors.cycleOvulation.withValues(alpha: 0.14),
        ),
    ];

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: correlation.daysInMonth.toDouble(),
        minY: 0,
        maxY: 10,
        rangeAnnotations: RangeAnnotations(
          verticalRangeAnnotations: verticalAnnotations,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.outline.withValues(alpha: 0.65),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: AppColors.outline),
            left: BorderSide(color: AppColors.outline),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 2,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 5,
              getTitlesWidget: (value, _) {
                final day = value.toInt();
                if (day < 1 || day > correlation.daysInMonth) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$day',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 2.6,
            color: AppColors.primary,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) {
                final pain = spot.y.round();
                final dotColor = pain >= 7
                    ? AppColors.painSevere
                    : AppColors.forPainLevel(pain);
                return FlDotCirclePainter(
                  radius: pain >= 7 ? 4.8 : 3.6,
                  color: dotColor,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseBarChart(TextTheme textTheme) {
    final buckets = correlation.phaseBuckets;

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 10,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.outline.withValues(alpha: 0.65),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: AppColors.outline),
            left: BorderSide(color: AppColors.outline),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 2,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= buckets.length) {
                  return const SizedBox.shrink();
                }
                final bucket = buckets[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${bucket.shortLabel} (${bucket.loggedDaysCount}d)',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: double.parse(buckets[i].averagePain.toStringAsFixed(1)),
                  width: 24,
                  color: _colorForPhase(buckets[i].phase),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 10,
                    color: AppColors.surfaceSoft,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Color _colorForPhase(CyclePhase phase) {
    return switch (phase) {
      CyclePhase.menstrual => AppColors.cycleMenstruation,
      CyclePhase.follicular => AppColors.primaryLight,
      CyclePhase.ovulationWindow => AppColors.cycleOvulation,
      CyclePhase.luteal => AppColors.cycleLuteal,
      CyclePhase.unknown => AppColors.primary,
    };
  }
}

