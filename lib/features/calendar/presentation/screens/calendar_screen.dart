import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/time/clock_provider.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/calendar/domain/models/calendar_day_digest.dart';
import 'package:endocare/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:endocare/features/calendar/presentation/widgets/calendar_day_detail_card.dart';
import 'package:endocare/features/calendar/presentation/widgets/cycle_day_editor_sheet.dart';
import 'package:endocare/features/calendar/presentation/widgets/cycle_estimate_card.dart';
import 'package:endocare/features/calendar/presentation/widgets/cycle_month_calendar.dart';
import 'package:endocare/features/calendar/presentation/widgets/cycle_symptom_charts_card.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Aba 2 — Calendário Menstrual e Ciclo integrado aos registros de sintomas.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _displayedMonth;
  DateTime? _selectedDate;

  void _changeMonth(DateTime nextMonth, DateTime today) {
    final normalizedMonth = DateTime(nextMonth.year, nextMonth.month, 1);
    setState(() {
      _displayedMonth = normalizedMonth;
      if (normalizedMonth.year == today.year &&
          normalizedMonth.month == today.month) {
        _selectedDate = today;
      } else {
        _selectedDate = normalizedMonth;
      }
    });
  }

  Future<void> _editSelectedCycleDay(CalendarDayDigest digest) async {
    final authUser = ref.read(authStateChangesProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    if (authUser == null) return;

    final outcome = await CycleDayEditorSheet.show(
      context: context,
      date: digest.date,
      existingEntry: digest.cycleEntry,
    );
    if (outcome == null || !mounted) return;

    final repo = ref.read(cycleRepositoryProvider);
    try {
      if (outcome.cleared) {
        await repo.deleteEntry(uid: authUser.uid, date: digest.date);
      } else if (outcome.entry != null) {
        await repo.saveEntry(uid: authUser.uid, entry: outcome.entry!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            outcome.cleared
                ? 'Registro do ciclo removido para este dia.'
                : 'Calendário atualizado com sucesso.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar no calendário agora. Tente novamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = SymptomLog.normalizeDate(ref.watch(homeClockProvider)());
    final activeDate = _selectedDate ?? today;
    final monthAnchor =
        _displayedMonth ?? DateTime(activeDate.year, activeDate.month, 1);

    final estimate = ref.watch(cycleEstimateProvider);
    final digestsByKey = ref.watch(calendarMonthDigestsProvider(monthAnchor));
    final correlation =
        ref.watch(cycleSymptomCorrelationProvider(monthAnchor));

    final selectedKey = SymptomLog.dateKeyFor(activeDate);
    final selectedDigest = digestsByKey[selectedKey] ??
        CalendarDayDigest(
          date: activeDate,
          phase: estimate.phaseFor(activeDate),
          cycleDayNumber: estimate.cycleDayFor(activeDate),
          isPredictedPeriod: estimate.isPredictedPeriod(activeDate),
          isEstimatedOvulationDay: estimate.isEstimatedOvulationDay(activeDate),
          isEstimatedFertileWindow:
              estimate.isEstimatedFertileWindow(activeDate),
        );

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
              // 1. Grade mensal interativa juntando Módulos 3 e 5
              CycleMonthCalendar(
                displayedMonth: monthAnchor,
                selectedDate: activeDate,
                today: today,
                digestsByKey: digestsByKey,
                onSelectDate: (date) => setState(() => _selectedDate = date),
                onPreviousMonth: () => _changeMonth(
                  DateTime(monthAnchor.year, monthAnchor.month - 1, 1),
                  today,
                ),
                onNextMonth: () => _changeMonth(
                  DateTime(monthAnchor.year, monthAnchor.month + 1, 1),
                  today,
                ),
                onJumpToToday: () {
                  setState(() {
                    _displayedMonth = DateTime(today.year, today.month, 1);
                    _selectedDate = today;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. Detalhe consolidado do dia selecionado (Ciclo + Sintomas)
              CalendarDayDetailCard(
                digest: selectedDigest,
                onEditCycleDay: () => _editSelectedCycleDay(selectedDigest),
                onOpenSymptoms: () => context.go(AppRoutes.quickLog),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Estimativa do ciclo e ovulação com aviso de aproximação
              CycleEstimateCard(estimate: estimate),

              const SizedBox(height: AppSpacing.lg),

              // 4. Gráficos `fl_chart` de cruzamento ciclo × sintomas sem causalidade
              CycleSymptomChartsCard(correlation: correlation),
            ],
          ),
        ),
      ),
    );
  }
}
