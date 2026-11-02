import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/firebase/firebase_providers.dart';
import 'package:endocare/core/time/clock_provider.dart';
import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/calendar/data/repositories/firestore_cycle_repository.dart';
import 'package:endocare/features/calendar/domain/models/calendar_day_digest.dart';
import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';
import 'package:endocare/features/calendar/domain/models/cycle_prediction_engine.dart';
import 'package:endocare/features/calendar/domain/models/cycle_symptom_correlation.dart';
import 'package:endocare/features/calendar/domain/repositories/cycle_repository.dart';
import 'package:endocare/features/care/presentation/providers/care_providers.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/symptoms/presentation/providers/symptom_providers.dart';

/// Provider do repositório de ciclo menstrual e agendamentos do calendário.
final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  return FirestoreCycleRepository(ref.watch(firestoreProvider));
});

/// Stream em tempo real das entradas de ciclo (`users/{uid}/cycleEntries`).
final cycleEntriesStreamProvider = StreamProvider<List<CycleEntry>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream<List<CycleEntry>>.value(const []);
  }
  return ref.watch(cycleRepositoryProvider).watchEntries(uid: authUser.uid);
});

/// Stream em tempo real dos registros de sintomas (`users/{uid}/symptomLogs`)
/// para cruzamento com o calendário menstrual.
final calendarSymptomLogsProvider = StreamProvider<List<SymptomLog>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream<List<SymptomLog>>.value(const []);
  }
  return ref
      .watch(symptomLogRepositoryProvider)
      .watchLogs(uid: authUser.uid);
});

/// Consolida consultas/exames/procedimentos ativos (`appointmentsStreamProvider`)
/// para exibição automática na grade mensal do Calendário.
final calendarExternalAppointmentsProvider =
    Provider<List<CalendarExternalAppointment>>((ref) {
  final managed = ref.watch(appointmentsStreamProvider).asData?.value ??
      const <MedicalAppointment>[];
  return managed
      .where((item) => item.status != AppointmentStatus.canceled)
      .map(
        (item) => CalendarExternalAppointment(
          id: item.id,
          date: SymptomLog.normalizeDate(item.data),
          title: '${item.tipo.label}: ${item.titulo}',
          location: item.local,
        ),
      )
      .toList(growable: false);
});

/// Estimativa viva de ciclo e ovulação calculada a partir do histórico da usuária.
final cycleEstimateProvider = Provider<CycleEstimate>((ref) {
  final now = SymptomLog.normalizeDate(ref.watch(homeClockProvider)());
  final entries = ref.watch(cycleEntriesStreamProvider).asData?.value ??
      const <CycleEntry>[];
  return CyclePredictionEngine.compute(
    entries: entries,
    referenceDate: now,
  );
});

/// Consolida todos os dias do mês `monthAnchor` (`DateTime(ano, mes, 1)`)
/// unificando Módulo 3 (`SymptomLog`) + Módulo 5 (`CycleEntry` + `CycleEstimate`).
final calendarMonthDigestsProvider =
    Provider.family<Map<String, CalendarDayDigest>, DateTime>((ref, monthAnchor) {
  final year = monthAnchor.year;
  final month = monthAnchor.month;
  final daysInMonth = DateTime(year, month + 1, 0).day;

  final estimate = ref.watch(cycleEstimateProvider);
  final cycleEntries = ref.watch(cycleEntriesStreamProvider).asData?.value ??
      const <CycleEntry>[];
  final symptomLogs = ref.watch(calendarSymptomLogsProvider).asData?.value ??
      const <SymptomLog>[];
  final externalAppointments = ref.watch(calendarExternalAppointmentsProvider);

  final cycleByKey = <String, CycleEntry>{
    for (final e in cycleEntries) SymptomLog.dateKeyFor(e.data): e,
  };
  final symptomByKey = <String, SymptomLog>{
    for (final s in symptomLogs) SymptomLog.dateKeyFor(s.data): s,
  };
  final appointmentsByKey = <String, List<CalendarExternalAppointment>>{};
  for (final item in externalAppointments) {
    final key = SymptomLog.dateKeyFor(item.date);
    appointmentsByKey
        .putIfAbsent(key, () => <CalendarExternalAppointment>[])
        .add(item);
  }

  final map = <String, CalendarDayDigest>{};
  for (var day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, month, day);
    final key = SymptomLog.dateKeyFor(date);

    map[key] = CalendarDayDigest(
      date: date,
      phase: estimate.phaseFor(date),
      cycleDayNumber: estimate.cycleDayFor(date),
      isPredictedPeriod: estimate.isPredictedPeriod(date),
      isEstimatedOvulationDay: estimate.isEstimatedOvulationDay(date),
      isEstimatedFertileWindow: estimate.isEstimatedFertileWindow(date),
      symptomLog: symptomByKey[key],
      cycleEntry: cycleByKey[key],
      externalAppointments: appointmentsByKey[key] ?? const [],
    );
  }

  return map;
});

/// Provider dos dados para os gráficos `fl_chart` (Ciclo × Sintomas) no mês exibido.
final cycleSymptomCorrelationProvider =
    Provider.family<CycleSymptomCorrelation, DateTime>((ref, monthAnchor) {
  final digests = ref.watch(calendarMonthDigestsProvider(monthAnchor));
  return CycleSymptomCorrelation.fromMonthDigests(
    digests.values.toList(growable: false),
  );
});
