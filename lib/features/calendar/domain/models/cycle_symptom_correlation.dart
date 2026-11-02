import 'package:endocare/features/calendar/domain/models/calendar_day_digest.dart';
import 'package:endocare/features/calendar/domain/models/cycle_prediction_engine.dart';

/// Ponto diário para o gráfico de evolução (Ciclo × Intensidade de dor) no mês.
class DailyCyclePainPoint {
  const DailyCyclePainPoint({
    required this.dayOfMonth,
    required this.painLevel,
    required this.hasSymptomLog,
    required this.hasFlow,
    required this.isOvulationWindow,
    required this.isCrisis,
  });

  final int dayOfMonth;
  final int painLevel;
  final bool hasSymptomLog;
  final bool hasFlow;
  final bool isOvulationWindow;
  final bool isCrisis;
}

/// Faixa contínua de dias no mês (ex.: dias 3..7 de fluxo menstrual ou janela ovulatória).
class MonthDaySpan {
  const MonthDaySpan({
    required this.startDay,
    required this.endDay,
  });

  final int startDay;
  final int endDay;
}

/// Agregado descritivo de sintomas por contexto/fase observada (sem causalidade).
class PhaseSymptomBucket {
  const PhaseSymptomBucket({
    required this.phase,
    required this.shortLabel,
    required this.loggedDaysCount,
    required this.averagePain,
    required this.crisisDaysCount,
  });

  final CyclePhase phase;
  final String shortLabel;
  final int loggedDaysCount;
  final double averagePain;
  final int crisisDaysCount;
}

/// Dados consolidados para os gráficos `fl_chart` de cruzamento Ciclo × Sintomas.
class CycleSymptomCorrelation {
  const CycleSymptomCorrelation({
    required this.daysInMonth,
    required this.dailyPoints,
    required this.flowSpans,
    required this.ovulationSpans,
    required this.phaseBuckets,
    required this.totalSymptomDaysInMonth,
    required this.painDaysOutsideFlowCount,
  });

  /// Aviso obrigatório destacando ausência de presunção de causalidade.
  static const String nonCausalityNotice =
      'Leitura descritiva (sem afirmar causa e efeito): estes gráficos mostram '
      'apenas quando seus sintomas e fases do ciclo coincidiram nos registros. '
      'Na endometriose, dores e crises também podem acontecer fora da menstruação '
      'ou sem relação direta com o ciclo.';

  final int daysInMonth;
  final List<DailyCyclePainPoint> dailyPoints;
  final List<MonthDaySpan> flowSpans;
  final List<MonthDaySpan> ovulationSpans;
  final List<PhaseSymptomBucket> phaseBuckets;
  final int totalSymptomDaysInMonth;
  final int painDaysOutsideFlowCount;

  bool get hasAnyLoggedSymptoms => totalSymptomDaysInMonth > 0;

  factory CycleSymptomCorrelation.fromMonthDigests(
    List<CalendarDayDigest> monthDigests,
  ) {
    if (monthDigests.isEmpty) {
      return const CycleSymptomCorrelation(
        daysInMonth: 30,
        dailyPoints: [],
        flowSpans: [],
        ovulationSpans: [],
        phaseBuckets: [],
        totalSymptomDaysInMonth: 0,
        painDaysOutsideFlowCount: 0,
      );
    }

    final sorted = List<CalendarDayDigest>.from(monthDigests)
      ..sort((a, b) => a.date.compareTo(b.date));

    final points = <DailyCyclePainPoint>[];
    final flowDays = <int>[];
    final ovulationDays = <int>[];
    var symptomDaysCount = 0;
    var painOutsideFlow = 0;

    final painSumsByPhase = <CyclePhase, int>{};
    final dayCountsByPhase = <CyclePhase, int>{};
    final crisisCountsByPhase = <CyclePhase, int>{};

    for (final digest in sorted) {
      final dom = digest.date.day;
      final isFlow = digest.hasActualFlow || digest.isPredictedPeriod;
      final isOv =
          digest.isEstimatedFertileWindow || digest.hasObservedOvulation;

      if (isFlow) flowDays.add(dom);
      if (isOv) ovulationDays.add(dom);

      points.add(
        DailyCyclePainPoint(
          dayOfMonth: dom,
          painLevel: digest.painLevel,
          hasSymptomLog: digest.hasSymptomLog,
          hasFlow: digest.hasActualFlow,
          isOvulationWindow: isOv,
          isCrisis: digest.isCrisis,
        ),
      );

      if (digest.hasSymptomLog) {
        symptomDaysCount++;
        if (digest.hasPain && !digest.hasActualFlow) {
          painOutsideFlow++;
        }
        final phase = digest.phase;
        painSumsByPhase[phase] =
            (painSumsByPhase[phase] ?? 0) + digest.painLevel;
        dayCountsByPhase[phase] = (dayCountsByPhase[phase] ?? 0) + 1;
        if (digest.isCrisis) {
          crisisCountsByPhase[phase] = (crisisCountsByPhase[phase] ?? 0) + 1;
        }
      }
    }

    const orderedPhases = [
      (CyclePhase.menstrual, 'Fluxo'),
      (CyclePhase.follicular, 'Folicular'),
      (CyclePhase.ovulationWindow, 'Ovulação est.'),
      (CyclePhase.luteal, 'Lútea'),
      (CyclePhase.unknown, 'Sem ciclo'),
    ];

    final buckets = <PhaseSymptomBucket>[];
    for (final (phase, shortLabel) in orderedPhases) {
      final count = dayCountsByPhase[phase] ?? 0;
      if (count == 0 && phase == CyclePhase.unknown) continue;
      if (count == 0 &&
          phase != CyclePhase.unknown &&
          (dayCountsByPhase[CyclePhase.unknown] ?? 0) == symptomDaysCount &&
          symptomDaysCount > 0) {
        // Quando não há ciclo menstrual base (ex.: bloqueio hormonal contínuo),
        // exibe apenas a barra real "Sem ciclo" em vez de 4 fases vazias.
        continue;
      }
      final sum = painSumsByPhase[phase] ?? 0;
      buckets.add(
        PhaseSymptomBucket(
          phase: phase,
          shortLabel: shortLabel,
          loggedDaysCount: count,
          averagePain: count > 0 ? sum / count : 0,
          crisisDaysCount: crisisCountsByPhase[phase] ?? 0,
        ),
      );
    }

    return CycleSymptomCorrelation(
      daysInMonth: sorted.length,
      dailyPoints: points,
      flowSpans: _buildContiguousSpans(flowDays),
      ovulationSpans: _buildContiguousSpans(ovulationDays),
      phaseBuckets: buckets,
      totalSymptomDaysInMonth: symptomDaysCount,
      painDaysOutsideFlowCount: painOutsideFlow,
    );
  }

  static List<MonthDaySpan> _buildContiguousSpans(List<int> sortedDays) {
    if (sortedDays.isEmpty) return const [];
    final spans = <MonthDaySpan>[];
    var start = sortedDays.first;
    var prev = start;
    for (var i = 1; i < sortedDays.length; i++) {
      final current = sortedDays[i];
      if (current == prev + 1) {
        prev = current;
      } else {
        spans.add(MonthDaySpan(startDay: start, endDay: prev));
        start = current;
        prev = current;
      }
    }
    spans.add(MonthDaySpan(startDay: start, endDay: prev));
    return spans;
  }
}

