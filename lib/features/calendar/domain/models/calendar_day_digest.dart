import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';
import 'package:endocare/features/calendar/domain/models/cycle_prediction_engine.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Resumo leve de consulta/exame/procedimento vindo da coleção `appointments`.
class CalendarExternalAppointment {
  const CalendarExternalAppointment({
    required this.id,
    required this.date,
    required this.title,
    this.location,
  });

  final String id;
  final DateTime date;
  final String title;
  final String? location;
}

/// Visão unificada de um dia no Calendário juntando:
/// - Módulo 3 (`SymptomLog`: dor, sintomas, humor, sono, mapa corporal)
/// - Módulo 5 (`CycleEntry`: fluxo, ovulação, crise, medicamentos, consultas)
/// - Estimativas do `CycleEstimate` (próxima menstruação, janela ovulatória, fase)
class CalendarDayDigest {
  const CalendarDayDigest({
    required this.date,
    required this.phase,
    required this.isPredictedPeriod,
    required this.isEstimatedOvulationDay,
    required this.isEstimatedFertileWindow,
    this.cycleDayNumber,
    this.symptomLog,
    this.cycleEntry,
    this.externalAppointments = const [],
  });

  final DateTime date;
  final CyclePhase phase;
  final int? cycleDayNumber;
  final bool isPredictedPeriod;
  final bool isEstimatedOvulationDay;
  final bool isEstimatedFertileWindow;
  final SymptomLog? symptomLog;
  final CycleEntry? cycleEntry;
  final List<CalendarExternalAppointment> externalAppointments;

  String get dateKey => SymptomLog.dateKeyFor(date);

  MenstrualFlowLevel? get flowLevel => cycleEntry?.fluxo;
  bool get hasActualFlow => flowLevel != null;
  bool get hasObservedOvulation => cycleEntry?.ovulacaoObservada ?? false;

  int get painLevel => symptomLog?.dor ?? 0;
  bool get hasSymptomLog => symptomLog != null;
  bool get hasPain => painLevel > 0;

  /// Considera crise quando marcada explicitamente no dia OU quando a dor registrada é >= 7.
  bool get isCrisis =>
      (cycleEntry?.crise ?? false) || (symptomLog != null && symptomLog!.dor >= 7);

  List<String> get medications {
    return cycleEntry?.medicamentos ?? const [];
  }

  bool get hasMedications => medications.isNotEmpty;

  List<String> get appointments {
    final items = <String>[];
    final local = cycleEntry?.consultaOuExame?.trim();
    if (local != null && local.isNotEmpty) {
      items.add(local);
    }
    for (final ext in externalAppointments) {
      if (!items.contains(ext.title)) {
        items.add(ext.title);
      }
    }
    return items;
  }

  bool get hasAppointments => appointments.isNotEmpty;
}

