import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/time/clock_provider.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';
import 'package:endocare/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:endocare/features/care/presentation/providers/care_providers.dart';
import 'package:endocare/features/home/domain/models/home_summary_data.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/symptoms/presentation/providers/symptom_providers.dart';

export 'package:endocare/core/time/clock_provider.dart';

/// Provider que monta o resumo diário e a ilustração rotativa da tela Início,
/// sincronizado em tempo real com `symptomLogs` e `cycleEntries`.
final homeSummaryProvider = Provider<HomeSummaryData>((ref) {
  final now = ref.watch(homeClockProvider)();
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  final todayLog = ref.watch(todaySymptomLogProvider).asData?.value;
  final cycleEntries =
      ref.watch(cycleEntriesStreamProvider).asData?.value ?? const <CycleEntry>[];
  final cycleEstimate = ref.watch(cycleEstimateProvider);
  final upcomingReminders = ref.watch(homeUpcomingReminderPreviewsProvider);

  final firstName = profile?.primeiroNome ??
      (authUser?.displayName?.trim().isNotEmpty == true
          ? authUser!.displayName!.trim().split(RegExp(r'\s+')).first
          : null);

  String rawDate;
  try {
    rawDate = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);
  } catch (_) {
    rawDate = '${now.day}/${now.month}/${now.year}';
  }
  final formattedDate = rawDate.isNotEmpty
      ? '${rawDate[0].toUpperCase()}${rawDate.substring(1)}'
      : rawDate;

  final todayKey = SymptomLog.dateKeyFor(now);
  CycleEntry? todayCycle;
  for (final item in cycleEntries) {
    if (SymptomLog.dateKeyFor(item.data) == todayKey) {
      todayCycle = item;
      break;
    }
  }

  String? cycleLabel;
  String? cycleSubtitle;
  if (todayCycle?.fluxo != null) {
    cycleLabel = 'Fluxo ${todayCycle!.fluxo!.label.toLowerCase()}';
    cycleSubtitle = cycleEstimate.currentCycleDay != null
        ? 'Dia ${cycleEstimate.currentCycleDay} do ciclo'
        : 'Registrado hoje';
  } else if (cycleEstimate.hasCycleHistory &&
      cycleEstimate.currentCycleDay != null) {
    cycleLabel = 'Dia ${cycleEstimate.currentCycleDay} do ciclo';
    cycleSubtitle = cycleEstimate.phaseFor(now).label;
  }

  return HomeSummaryData.forToday(
    now: now,
    formattedDate: formattedDate,
    firstName: firstName,
    todayLog: todayLog,
    cycleStatusLabel: cycleLabel,
    cycleStatusSubtitle: cycleSubtitle,
    upcomingReminders: upcomingReminders,
  );
});
