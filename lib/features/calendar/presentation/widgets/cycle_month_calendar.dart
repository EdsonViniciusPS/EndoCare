import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_card.dart';
import 'package:endocare/features/calendar/domain/models/calendar_day_digest.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Grade mensal interativa do Calendário Menstrual e de Sintomas.
///
/// Exibe simultaneamente dados do Módulo 3 (dor e crises) e do Módulo 5
/// (fluxo menstrual, previsão de menstruação, janela de ovulação estimada,
/// medicamentos e consultas/exames).
class CycleMonthCalendar extends StatelessWidget {
  const CycleMonthCalendar({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.today,
    required this.digestsByKey,
    required this.onSelectDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onJumpToToday,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final DateTime today;
  final Map<String, CalendarDayDigest> digestsByKey;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onJumpToToday;

  static const List<String> _weekdayLabels = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final firstOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    // DateTime.weekday: 1 = Segunda .. 7 = Domingo
    final leadingEmptyCells = firstOfMonth.weekday - 1;
    final totalCells = ((leadingEmptyCells + daysInMonth + 6) ~/ 7) * 7;

    String rawMonthTitle;
    try {
      rawMonthTitle = DateFormat("MMMM 'de' yyyy", 'pt_BR').format(firstOfMonth);
    } catch (_) {
      rawMonthTitle = '${firstOfMonth.month}/${firstOfMonth.year}';
    }
    final monthTitle = rawMonthTitle.isNotEmpty
        ? '${rawMonthTitle[0].toUpperCase()}${rawMonthTitle.substring(1)}'
        : rawMonthTitle;

    final isCurrentMonth = displayedMonth.year == today.year &&
        displayedMonth.month == today.month;

    return EndoCareCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho de navegação mensal
          Row(
            children: [
              IconButton(
                tooltip: 'Mês anterior',
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  monthTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isCurrentMonth)
                TextButton(
                  onPressed: onJumpToToday,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    minimumSize: const Size(48, 32),
                  ),
                  child: const Text('Hoje'),
                ),
              IconButton(
                tooltip: 'Próximo mês',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Cabeçalho dos dias da semana
          Row(
            children: _weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Grade de semanas
          for (var weekStart = 0; weekStart < totalCells; weekStart += 7)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = weekStart + col;
                  final dayNumber = cellIndex - leadingEmptyCells + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 52));
                  }

                  final cellDate = DateTime(
                    displayedMonth.year,
                    displayedMonth.month,
                    dayNumber,
                  );
                  final key = SymptomLog.dateKeyFor(cellDate);
                  final digest = digestsByKey[key];
                  final isSelected =
                      SymptomLog.normalizeDate(selectedDate) == cellDate;
                  final isToday = SymptomLog.normalizeDate(today) == cellDate;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _CalendarDayCell(
                        date: cellDate,
                        digest: digest,
                        isSelected: isSelected,
                        isToday: isToday,
                        onTap: () => onSelectDate(cellDate),
                      ),
                    ),
                  );
                }),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1),
          ),

          // Legenda visual integrada (Módulos 3 e 5)
          const Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.center,
            children: [
              _LegendItem(
                color: AppColors.cycleMenstruation,
                label: 'Fluxo',
                filled: true,
              ),
              _LegendItem(
                color: AppColors.cycleMenstruation,
                label: 'Previsão',
                filled: false,
              ),
              _LegendItem(
                color: AppColors.cycleOvulation,
                label: 'Ovulação est.',
                filled: true,
              ),
              _LegendItem(
                color: AppColors.painModerate,
                label: 'Dor',
                isDot: true,
              ),
              _LegendItem(
                color: AppColors.painSevere,
                label: 'Crise',
                icon: Icons.bolt_rounded,
              ),
              _LegendItem(
                color: AppColors.success,
                label: 'Medicação',
                isDot: true,
              ),
              _LegendItem(
                color: AppColors.tertiary,
                label: 'Consulta',
                isDot: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.digest,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final CalendarDayDigest? digest;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasFlow = digest?.hasActualFlow ?? false;
    final flowWeight = digest?.flowLevel?.weight ?? 0;
    final isPredictedPeriod = digest?.isPredictedPeriod ?? false;
    final isOvulationDay =
        (digest?.isEstimatedOvulationDay ?? false) ||
        (digest?.hasObservedOvulation ?? false);
    final isFertile = digest?.isEstimatedFertileWindow ?? false;

    Color backgroundColor = Colors.transparent;
    if (hasFlow) {
      final alpha = (0.14 + (flowWeight * 0.04)).clamp(0.16, 0.34);
      backgroundColor = AppColors.cycleMenstruation.withValues(alpha: alpha);
    } else if (isOvulationDay) {
      backgroundColor = AppColors.cycleOvulation.withValues(alpha: 0.20);
    } else if (isFertile) {
      backgroundColor = AppColors.cycleOvulation.withValues(alpha: 0.10);
    } else if (isSelected) {
      backgroundColor = AppColors.primaryContainer;
    }

    Border? border;
    if (isSelected) {
      border = Border.all(color: AppColors.primaryDark, width: 2);
    } else if (isPredictedPeriod) {
      border = Border.all(
        color: AppColors.cycleMenstruation.withValues(alpha: 0.65),
        width: 1.3,
      );
    } else if (isToday) {
      border = Border.all(color: AppColors.primary, width: 1.3);
    } else if (isOvulationDay) {
      border = Border.all(
        color: AppColors.cycleOvulation.withValues(alpha: 0.65),
        width: 1.1,
      );
    }

    final textColor = hasFlow
        ? AppColors.cycleMenstruation
        : (isSelected
            ? AppColors.primaryDark
            : (isOvulationDay ? AppColors.info : AppColors.textPrimary));

    return Semantics(
      button: true,
      selected: isSelected,
      label: _buildSemanticLabel(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('calendar_day_${SymptomLog.dateKeyFor(date)}'),
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusSm,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppSpacing.borderRadiusSm,
              border: border,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: textTheme.labelMedium?.copyWith(
                        color: textColor,
                        fontWeight: (isSelected || isToday || hasFlow)
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    if (isOvulationDay) ...[
                      const SizedBox(width: 1),
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 10,
                        color: AppColors.cycleOvulation,
                      ),
                    ],
                  ],
                ),
                _buildMarkersRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkersRow() {
    final d = digest;
    if (d == null) return const SizedBox(height: 10);

    final markers = <Widget>[];
    if (d.isCrisis) {
      markers.add(
        const Icon(
          Icons.bolt_rounded,
          size: 11,
          color: AppColors.painSevere,
        ),
      );
    } else if (d.hasPain) {
      markers.add(_dot(AppColors.forPainLevel(d.painLevel)));
    }
    if (d.hasMedications) {
      markers.add(_dot(AppColors.success));
    }
    if (d.hasAppointments) {
      markers.add(_dot(AppColors.tertiary));
    }

    if (markers.isEmpty) {
      return const SizedBox(height: 10);
    }

    return SizedBox(
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < markers.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            markers[i],
          ],
        ],
      ),
    );
  }

  static Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  String _buildSemanticLabel() {
    final parts = <String>['Dia ${date.day}'];
    final d = digest;
    if (d != null) {
      if (d.hasActualFlow) parts.add('fluxo ${d.flowLevel!.label}');
      if (d.isPredictedPeriod) parts.add('previsão de menstruação');
      if (d.isEstimatedOvulationDay) parts.add('ovulação estimada');
      if (d.hasPain) parts.add('dor ${d.painLevel} de 10');
      if (d.isCrisis) parts.add('crise');
      if (d.hasMedications) parts.add('medicação registrada');
      if (d.hasAppointments) parts.add('consulta ou exame');
    }
    return parts.join(', ');
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.filled = true,
    this.isDot = false,
    this.icon,
  });

  final Color color;
  final String label;
  final bool filled;
  final bool isDot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget symbol;
    if (icon != null) {
      symbol = Icon(icon, size: 13, color: color);
    } else if (isDot) {
      symbol = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    } else {
      symbol = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color, width: 1.2),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        symbol,
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

