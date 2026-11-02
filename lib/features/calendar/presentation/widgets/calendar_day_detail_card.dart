import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/calendar/domain/models/calendar_day_digest.dart';
import 'package:endocare/features/calendar/domain/models/cycle_prediction_engine.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_catalog.dart';

/// Cartão de detalhe unificado do dia selecionado no Calendário, reunindo
/// dados do Módulo 3 (Sintomas + Mapa Corporal) e do Módulo 5 (Ciclo, Ovulação,
/// Crises, Medicamentos e Consultas/Exames).
class CalendarDayDetailCard extends StatelessWidget {
  const CalendarDayDetailCard({
    super.key,
    required this.digest,
    required this.onEditCycleDay,
    required this.onOpenSymptoms,
  });

  final CalendarDayDigest digest;
  final VoidCallback onEditCycleDay;
  final VoidCallback onOpenSymptoms;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    String rawDate;
    try {
      rawDate =
          DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(digest.date);
    } catch (_) {
      rawDate =
          '${digest.date.day}/${digest.date.month}/${digest.date.year}';
    }
    final formattedDate = rawDate.isNotEmpty
        ? '${rawDate[0].toUpperCase()}${rawDate.substring(1)}'
        : rawDate;

    final illustration = AppAssets.forCalendarContext(
      isMenstrualFlow: digest.hasActualFlow,
      isAppointmentView: digest.hasAppointments,
      variantIndex: digest.date.day,
    );

    final statusBadges = _buildStatusBadges(textTheme);
    final log = digest.symptomLog;

    return EndoCareCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    if (statusBadges.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: statusBadges,
                      )
                    else
                      Text(
                        'Nenhum evento de ciclo marcado para esta data.',
                        style: textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StorysetIllustration(
                asset: illustration,
                height: 68,
                width: 68,
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1),
          ),

          // Bloco 1 — Módulo 5: Ciclo, medicamentos e consultas
          Text(
            'Ciclo, medicamentos e consultas',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildCycleDetailsSection(textTheme),

          const SizedBox(height: AppSpacing.md),

          // Bloco 2 — Módulo 3 & 4: Sintomas e Mapa Corporal do dia
          Text(
            'Sintomas registrados no dia',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (log == null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Text(
                'Sem registro diário de sintomas nesta data.',
                style: textTheme.bodySmall,
              ),
            )
          else
            _buildSymptomDetailsSection(textTheme),

          const SizedBox(height: AppSpacing.md),

          // Ações rápidas integradas
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            children: [
              EndoCareButton(
                label: (digest.cycleEntry != null && !digest.cycleEntry!.isEmpty)
                    ? 'Editar ciclo do dia'
                    : 'Marcar fluxo ou evento',
                icon: Icons.edit_calendar_rounded,
                variant: EndoCareButtonVariant.primary,
                onPressed: onEditCycleDay,
              ),
              EndoCareButton(
                label: log != null ? 'Ver sintomas' : 'Registrar sintomas',
                icon: Icons.healing_outlined,
                variant: EndoCareButtonVariant.secondary,
                onPressed: onOpenSymptoms,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatusBadges(TextTheme textTheme) {
    final badges = <Widget>[];

    if (digest.hasActualFlow) {
      badges.add(
        _StatusPill(
          label: 'Fluxo ${digest.flowLevel!.label.toLowerCase()}',
          color: AppColors.cycleMenstruation,
          backgroundColor: AppColors.errorContainer,
        ),
      );
    } else if (digest.isPredictedPeriod) {
      badges.add(
        const _StatusPill(
          label: 'Previsão de menstruação',
          color: AppColors.cycleMenstruation,
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }

    if (digest.hasObservedOvulation) {
      badges.add(
        const _StatusPill(
          label: 'Sinais de ovulação',
          color: AppColors.cycleOvulation,
          backgroundColor: AppColors.infoContainer,
        ),
      );
    } else if (digest.isEstimatedOvulationDay) {
      badges.add(
        const _StatusPill(
          label: 'Ovulação estimada',
          color: AppColors.cycleOvulation,
          backgroundColor: AppColors.infoContainer,
        ),
      );
    } else if (digest.isEstimatedFertileWindow) {
      badges.add(
        const _StatusPill(
          label: 'Janela ovulatória (est.)',
          color: AppColors.cycleOvulation,
          backgroundColor: AppColors.infoContainer,
        ),
      );
    }

    if (digest.cycleDayNumber != null &&
        digest.phase != CyclePhase.unknown) {
      badges.add(
        _StatusPill(
          label: 'Dia ${digest.cycleDayNumber} • ${digest.phase.label}',
          color: AppColors.primary,
          backgroundColor: AppColors.primaryContainer,
        ),
      );
    }

    if (digest.isCrisis) {
      badges.add(
        const _StatusPill(
          label: 'Crise de sintomas',
          color: AppColors.painSevere,
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }

    return badges;
  }

  Widget _buildCycleDetailsSection(TextTheme textTheme) {
    final rows = <Widget>[];

    if (digest.hasActualFlow) {
      rows.add(
        _InfoLine(
          icon: Icons.water_drop_rounded,
          color: AppColors.cycleMenstruation,
          text: 'Menstruação: fluxo ${digest.flowLevel!.label.toLowerCase()}',
        ),
      );
    }
    if (digest.hasMedications) {
      rows.add(
        _InfoLine(
          icon: Icons.medication_outlined,
          color: AppColors.success,
          text: 'Medicamentos: ${digest.medications.join(', ')}',
        ),
      );
    }
    if (digest.hasAppointments) {
      rows.add(
        _InfoLine(
          icon: Icons.event_available_rounded,
          color: AppColors.tertiary,
          text: 'Consulta / exame: ${digest.appointments.join(', ')}',
        ),
      );
    }
    final notes = digest.cycleEntry?.observacoes?.trim();
    if (notes != null && notes.isNotEmpty) {
      rows.add(
        _InfoLine(
          icon: Icons.notes_rounded,
          color: AppColors.primary,
          text: notes,
        ),
      );
    }

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: const BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Text(
          'Toque em "Marcar fluxo ou evento" para anotar menstruação, crise, medicamentos ou consultas.',
          style: textTheme.bodySmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          rows[i],
        ],
      ],
    );
  }

  Widget _buildSymptomDetailsSection(TextTheme textTheme) {
    final log = digest.symptomLog!;
    final painColor = AppColors.forPainLevel(log.dor);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: painColor.withValues(alpha: 0.16),
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
                child: Text(
                  'Dor ${log.dor}/10 • ${AppColors.painLabel(log.dor)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: painColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  [
                    if (log.humor != null) 'Humor: ${log.humor}',
                    'Sono: ${SymptomCatalog.sleepQualityLabel(log.sono)} (${log.sono}/10)',
                  ].join(' • '),
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (log.tipos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Sintomas: ${log.tipos.join(', ')}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (log.regioes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Regiões de dor: ${log.regioes.join(', ')}',
              style: textTheme.bodySmall,
            ),
          ],
          if (log.notas != null && log.notas!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Nota: ${log.notas!.trim()}',
              style: textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

