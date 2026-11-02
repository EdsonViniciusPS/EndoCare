import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Fases observadas ou estimadas do ciclo menstrual.
enum CyclePhase {
  menstrual('Menstruação'),
  follicular('Fase folicular'),
  ovulationWindow('Janela ovulatória (est.)'),
  luteal('Fase lútea'),
  unknown('Sem ciclo ativo');

  const CyclePhase(this.label);

  final String label;
}

/// Resumo das estimativas de ciclo e ovulação com janelas futuras projetadas.
class CycleEstimate {
  const CycleEstimate({
    required this.referenceDate,
    required this.periodStarts,
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    required this.usesDefaultCycleLength,
    required this.recordedFlowDateKeys,
    required this.predictedPeriodDateKeys,
    required this.estimatedOvulationDateKeys,
    required this.estimatedFertileDateKeys,
    this.lastPeriodStart,
    this.nextPredictedPeriodStart,
    this.nextEstimatedOvulationDate,
    this.currentCycleDay,
  });

  final DateTime referenceDate;
  final List<DateTime> periodStarts;
  final int averageCycleLength;
  final int averagePeriodDuration;
  final bool usesDefaultCycleLength;

  final DateTime? lastPeriodStart;
  final DateTime? nextPredictedPeriodStart;
  final DateTime? nextEstimatedOvulationDate;
  final int? currentCycleDay;

  final Set<String> recordedFlowDateKeys;
  final Set<String> predictedPeriodDateKeys;
  final Set<String> estimatedOvulationDateKeys;
  final Set<String> estimatedFertileDateKeys;

  bool get hasCycleHistory => lastPeriodStart != null;

  bool isPredictedPeriod(DateTime date) {
    final key = SymptomLog.dateKeyFor(date);
    return !recordedFlowDateKeys.contains(key) &&
        predictedPeriodDateKeys.contains(key);
  }

  bool isEstimatedOvulationDay(DateTime date) {
    return estimatedOvulationDateKeys.contains(SymptomLog.dateKeyFor(date));
  }

  bool isEstimatedFertileWindow(DateTime date) {
    return estimatedFertileDateKeys.contains(SymptomLog.dateKeyFor(date));
  }

  /// Dia do ciclo correspondente a `date` (1 = primeiro dia da menstruação).
  int? cycleDayFor(DateTime date) {
    if (periodStarts.isEmpty) return null;
    final target = SymptomLog.normalizeDate(date);

    DateTime? anchor;
    for (final start in periodStarts) {
      if (!start.isAfter(target)) {
        anchor = start;
      } else {
        break;
      }
    }
    if (anchor == null) return null;

    final diff = target.difference(anchor).inDays;
    // Se já passou muito além de 2 ciclos sem nova menstruação (ex.: bloqueio
    // hormonal contínuo), evita exibir "Dia 120 do ciclo".
    if (diff >= averageCycleLength * 2) return null;
    if (anchor == periodStarts.last && diff >= averageCycleLength) {
      // Para datas futuras projetadas, calcula o dia dentro do ciclo previsto.
      return (diff % averageCycleLength) + 1;
    }
    return diff + 1;
  }

  /// Classifica a fase aproximada de `date` com base nos fluxos registrados e projeções.
  CyclePhase phaseFor(DateTime date) {
    final normalized = SymptomLog.normalizeDate(date);
    final key = SymptomLog.dateKeyFor(normalized);

    if (recordedFlowDateKeys.contains(key) || isPredictedPeriod(normalized)) {
      return CyclePhase.menstrual;
    }
    if (!hasCycleHistory) {
      return CyclePhase.unknown;
    }
    if (estimatedFertileDateKeys.contains(key)) {
      return CyclePhase.ovulationWindow;
    }

    final dayInCycle = cycleDayFor(normalized);
    if (dayInCycle == null) return CyclePhase.unknown;

    final estimatedOvulationDayInCycle =
        (averageCycleLength - 14).clamp(8, averageCycleLength - 5);
    if (dayInCycle <= averagePeriodDuration) {
      return CyclePhase.menstrual;
    }
    if (dayInCycle < estimatedOvulationDayInCycle - 3) {
      return CyclePhase.follicular;
    }
    if (dayInCycle <= estimatedOvulationDayInCycle + 1) {
      return CyclePhase.ovulationWindow;
    }
    return CyclePhase.luteal;
  }
}

/// Motor determinístico de estimativa de ciclo menstrual e ovulação.
abstract final class CyclePredictionEngine {
  static const int defaultCycleLength = 28;
  static const int defaultPeriodDuration = 5;
  static const int minValidCycleDays = 18;
  static const int maxValidCycleDays = 60;

  /// Aviso clínico obrigatório sobre a natureza aproximada das estimativas.
  static const String approximateDisclaimer =
      'Aviso: as datas de próximo ciclo e ovulação são estimativas aproximadas '
      'calculadas a partir dos seus registros. Na endometriose ou durante tratamentos '
      'hormonais, os ciclos podem variar bastante. Não utilize como método contraceptivo.';

  static CycleEstimate compute({
    required Iterable<CycleEntry> entries,
    required DateTime referenceDate,
  }) {
    final normalizedRef = SymptomLog.normalizeDate(referenceDate);

    // Filtra dias com fluxo menstrual (excluindo escape isolado) em ordem crescente.
    final flowDays = entries
        .where((e) => e.fluxo != null && e.fluxo!.isMenstrualPeriodFlow)
        .map((e) => SymptomLog.normalizeDate(e.data))
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    final recordedFlowKeys = flowDays.map(SymptomLog.dateKeyFor).toSet();

    if (flowDays.isEmpty) {
      return CycleEstimate(
        referenceDate: normalizedRef,
        periodStarts: const [],
        averageCycleLength: defaultCycleLength,
        averagePeriodDuration: defaultPeriodDuration,
        usesDefaultCycleLength: true,
        recordedFlowDateKeys: const {},
        predictedPeriodDateKeys: const {},
        estimatedOvulationDateKeys: const {},
        estimatedFertileDateKeys: const {},
      );
    }

    // Agrupa dias contíguos de sangramento (intervalo <= 2 dias no mesmo episódio;
    // novo ciclo inicia após >= 10 dias do início do episódio anterior).
    final episodes = <List<DateTime>>[];
    for (final day in flowDays) {
      if (episodes.isEmpty) {
        episodes.add([day]);
        continue;
      }
      final currentEpisode = episodes.last;
      final gapFromLastBleedingDay =
          day.difference(currentEpisode.last).inDays;
      final gapFromEpisodeStart = day.difference(currentEpisode.first).inDays;

      if (gapFromLastBleedingDay <= 2 || gapFromEpisodeStart < 10) {
        currentEpisode.add(day);
      } else {
        episodes.add([day]);
      }
    }

    final periodStarts =
        episodes.map((ep) => ep.first).toList(growable: false);

    // Calcula comprimentos observados entre inícios consecutivos (18..60 dias).
    final validCycleLengths = <int>[];
    for (var i = 1; i < periodStarts.length; i++) {
      final length = periodStarts[i].difference(periodStarts[i - 1]).inDays;
      if (length >= minValidCycleDays && length <= maxValidCycleDays) {
        validCycleLengths.add(length);
      }
    }

    final recentLengths = validCycleLengths.length > 6
        ? validCycleLengths.sublist(validCycleLengths.length - 6)
        : validCycleLengths;

    final usesDefault = recentLengths.isEmpty;
    final avgCycleLength = usesDefault
        ? defaultCycleLength
        : (recentLengths.reduce((a, b) => a + b) / recentLengths.length)
            .round()
            .clamp(minValidCycleDays, maxValidCycleDays);

    // Duração média do fluxo menstrual (limitada entre 3 e 8 dias; ignora episódio
    // recém-iniciado hoje com apenas 1 dia quando já existem episódios anteriores).
    final completedDurations = <int>[];
    for (var i = 0; i < episodes.length; i++) {
      final ep = episodes[i];
      final span = ep.last.difference(ep.first).inDays + 1;
      final isOngoingSingleDay =
          i == episodes.length - 1 &&
          span == 1 &&
          normalizedRef.difference(ep.first).inDays <= 1 &&
          episodes.length > 1;
      if (!isOngoingSingleDay) {
        completedDurations.add(span.clamp(2, 10));
      }
    }
    final avgPeriodDuration = completedDurations.isEmpty
        ? defaultPeriodDuration
        : (completedDurations.reduce((a, b) => a + b) /
                completedDurations.length)
            .round()
            .clamp(3, 8);

    final lastStart = periodStarts.last;
    final predictedPeriodKeys = <String>{};
    final ovulationKeys = <String>{};
    final fertileKeys = <String>{};

    // Marca também as janelas ovulatórias aproximadas entre ciclos históricos
    // e projeta os próximos 3 ciclos a partir do último início registrado.
    for (var i = 1; i < periodStarts.length; i++) {
      final nextStart = periodStarts[i];
      final prevStart = periodStarts[i - 1];
      final span = nextStart.difference(prevStart).inDays;
      if (span >= minValidCycleDays && span <= maxValidCycleDays) {
        final ovDay = nextStart.subtract(const Duration(days: 14));
        _populateOvulationWindow(
          ovulationDay: ovDay,
          recordedFlowKeys: recordedFlowKeys,
          ovulationKeys: ovulationKeys,
          fertileKeys: fertileKeys,
        );
      }
    }

    // Inclui também marcadores manuais de ovulação observada pela usuária.
    for (final entry in entries) {
      if (entry.ovulacaoObservada) {
        final day = SymptomLog.normalizeDate(entry.data);
        _populateOvulationWindow(
          ovulationDay: day,
          recordedFlowKeys: recordedFlowKeys,
          ovulationKeys: ovulationKeys,
          fertileKeys: fertileKeys,
        );
      }
    }

    DateTime? nextPredictedStart;
    DateTime? nextEstimatedOvulation;

    // Se o último início não está distante demais (> 90 dias sem menstruar),
    // projeta até 3 ciclos futuros para exibição no calendário.
    if (normalizedRef.difference(lastStart).inDays <= 90) {
      for (var cycleOffset = 1; cycleOffset <= 3; cycleOffset++) {
        final projectedStart =
            lastStart.add(Duration(days: avgCycleLength * cycleOffset));
        final projectedOvulation =
            projectedStart.subtract(const Duration(days: 14));

        _populateOvulationWindow(
          ovulationDay: projectedOvulation,
          recordedFlowKeys: recordedFlowKeys,
          ovulationKeys: ovulationKeys,
          fertileKeys: fertileKeys,
        );

        for (var d = 0; d < avgPeriodDuration; d++) {
          final pDay = projectedStart.add(Duration(days: d));
          final pKey = SymptomLog.dateKeyFor(pDay);
          if (!recordedFlowKeys.contains(pKey)) {
            predictedPeriodKeys.add(pKey);
          }
        }

        if (nextPredictedStart == null &&
            !projectedStart
                .add(Duration(days: avgPeriodDuration - 1))
                .isBefore(normalizedRef)) {
          nextPredictedStart = projectedStart;
        }
        if (nextEstimatedOvulation == null &&
            !projectedOvulation.isBefore(normalizedRef)) {
          nextEstimatedOvulation = projectedOvulation;
        }
      }
      nextPredictedStart ??= lastStart.add(Duration(days: avgCycleLength));
      nextEstimatedOvulation ??=
          nextPredictedStart.subtract(const Duration(days: 14));
    }

    final diffFromLast = normalizedRef.difference(lastStart).inDays;
    final currentCycleDay = (diffFromLast >= 0 && diffFromLast < avgCycleLength * 2)
        ? diffFromLast + 1
        : null;

    return CycleEstimate(
      referenceDate: normalizedRef,
      periodStarts: periodStarts,
      averageCycleLength: avgCycleLength,
      averagePeriodDuration: avgPeriodDuration,
      usesDefaultCycleLength: usesDefault,
      lastPeriodStart: lastStart,
      nextPredictedPeriodStart: nextPredictedStart,
      nextEstimatedOvulationDate: nextEstimatedOvulation,
      currentCycleDay: currentCycleDay,
      recordedFlowDateKeys: recordedFlowKeys,
      predictedPeriodDateKeys: predictedPeriodKeys,
      estimatedOvulationDateKeys: ovulationKeys,
      estimatedFertileDateKeys: fertileKeys,
    );
  }

  static void _populateOvulationWindow({
    required DateTime ovulationDay,
    required Set<String> recordedFlowKeys,
    required Set<String> ovulationKeys,
    required Set<String> fertileKeys,
  }) {
    final ovKey = SymptomLog.dateKeyFor(ovulationDay);
    if (!recordedFlowKeys.contains(ovKey)) {
      ovulationKeys.add(ovKey);
    }
    for (var delta = -3; delta <= 1; delta++) {
      final fDay = ovulationDay.add(Duration(days: delta));
      final fKey = SymptomLog.dateKeyFor(fDay);
      if (!recordedFlowKeys.contains(fKey)) {
        fertileKeys.add(fKey);
      }
    }
  }
}

