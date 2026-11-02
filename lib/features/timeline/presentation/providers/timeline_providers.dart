import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/time/clock_provider.dart';
import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';
import 'package:endocare/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:endocare/features/care/presentation/providers/care_providers.dart';
import 'package:endocare/features/impact/domain/models/impact_log.dart';
import 'package:endocare/features/impact/presentation/providers/impact_providers.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/timeline/domain/models/timeline_event.dart';
import 'package:endocare/features/timeline/domain/timeline_builder.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';
import 'package:endocare/features/treatments/domain/models/treatment_effect.dart';

/// Notifier que gerencia as categorias selecionadas no filtro (vazio = todas).
class TimelineCategoryFilterNotifier extends Notifier<Set<TimelineCategory>> {
  @override
  Set<TimelineCategory> build() => const <TimelineCategory>{};

  void toggle(TimelineCategory category) {
    if (state.contains(category)) {
      state = state.where((c) => c != category).toSet();
    } else {
      state = {...state, category};
    }
  }

  void reset() {
    state = const <TimelineCategory>{};
  }

  void setFilter(Set<TimelineCategory> categories) {
    state = categories;
  }
}

final timelineCategoryFilterProvider =
    NotifierProvider<TimelineCategoryFilterNotifier, Set<TimelineCategory>>(
  TimelineCategoryFilterNotifier.new,
);

/// Notifier que gerencia a direção da ordenação (true = mais recentes primeiro).
class TimelineSortNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }

  void setSort({required bool newestFirst}) {
    state = newestFirst;
  }
}

final timelineSortNewestFirstProvider =
    NotifierProvider<TimelineSortNotifier, bool>(
  TimelineSortNotifier.new,
);

/// Constrói a lista completa de eventos da linha do tempo agregando todos os
/// módulos da doença (sintomas, ciclo, tratamentos, consultas e impacto).
final allTimelineEventsProvider = Provider<List<TimelineEvent>>((ref) {
  final now = ref.watch(homeClockProvider)();
  final symptomLogs = ref.watch(calendarSymptomLogsProvider).asData?.value ??
      const <SymptomLog>[];
  final cycleEntries = ref.watch(cycleEntriesStreamProvider).asData?.value ??
      const <CycleEntry>[];
  final treatments = ref.watch(treatmentsStreamProvider).asData?.value ??
      const <Treatment>[];
  final treatmentEffects =
      ref.watch(treatmentEffectsStreamProvider).asData?.value ??
          const <TreatmentEffect>[];
  final appointments = ref.watch(appointmentsStreamProvider).asData?.value ??
      const <MedicalAppointment>[];
  final impactLogs = ref.watch(impactLogsStreamProvider).asData?.value ??
      const <ImpactLog>[];
  final newestFirst = ref.watch(timelineSortNewestFirstProvider);

  return TimelineBuilder.build(
    now: now,
    symptomLogs: symptomLogs,
    cycleEntries: cycleEntries,
    treatments: treatments,
    treatmentEffects: treatmentEffects,
    appointments: appointments,
    impactLogs: impactLogs,
    newestFirst: newestFirst,
  );
});

/// Eventos filtrados pela categoria selecionada.
final filteredTimelineEventsProvider = Provider<List<TimelineEvent>>((ref) {
  final allEvents = ref.watch(allTimelineEventsProvider);
  final selectedCategories = ref.watch(timelineCategoryFilterProvider);

  if (selectedCategories.isEmpty) {
    return allEvents;
  }
  return TimelineBuilder.filter(
    allEvents,
    categories: selectedCategories,
  );
});

/// Contagem de eventos por categoria para exibição nos chips de filtro.
final timelineCategoryCountsProvider =
    Provider<Map<TimelineCategory, int>>((ref) {
  final allEvents = ref.watch(allTimelineEventsProvider);
  final counts = <TimelineCategory, int>{};
  for (final cat in TimelineCategory.values) {
    counts[cat] = 0;
  }
  for (final ev in allEvents) {
    counts[ev.category] = (counts[ev.category] ?? 0) + 1;
  }
  return counts;
});
