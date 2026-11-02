import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';
import 'package:endocare/features/calendar/domain/models/cycle_prediction_engine.dart';
import 'package:endocare/features/impact/domain/models/impact_log.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/timeline/domain/models/timeline_event.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';
import 'package:endocare/features/treatments/domain/models/treatment_effect.dart';

/// Motor puro (sem Flutter/Firebase) que unifica os registros de todos os
/// módulos em uma única Linha do tempo da doença, em ordem cronológica.
///
/// Fontes:
/// - Módulo 3/4 (`symptomLogs`): crises (dor >= 7) e mudanças de sintomas.
/// - Módulo 5 (`cycleEntries`): crises marcadas e inícios de menstruação.
/// - Módulo 6 (`treatments`, `treatmentEffects`, `appointments`): tratamentos,
///   efeitos percebidos, consultas, exames, cirurgias e procedimentos.
/// - Módulo 7 (`impactLogs`): impacto na rotina.
///
/// As "mudanças de sintomas" descrevem apenas o que foi registrado, sem
/// atribuir causa a nenhum tratamento, fase do ciclo ou evento.
abstract final class TimelineBuilder {
  /// Dor a partir da qual um dia é tratado como crise.
  static const int crisisPainThreshold = 7;

  /// Variação mínima da dor média semanal para virar "mudança de sintomas".
  static const double painChangeThreshold = 2.0;

  /// Janela para considerar um sintoma como "novo" (não visto antes nela).
  static const int newSymptomLookbackDays = 30;

  static List<TimelineEvent> build({
    required DateTime now,
    Iterable<SymptomLog> symptomLogs = const [],
    Iterable<CycleEntry> cycleEntries = const [],
    Iterable<Treatment> treatments = const [],
    Iterable<TreatmentEffect> treatmentEffects = const [],
    Iterable<MedicalAppointment> appointments = const [],
    Iterable<ImpactLog> impactLogs = const [],
    bool newestFirst = true,
  }) {
    final sortedLogs = symptomLogs.toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    final sortedCycle = cycleEntries.toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    final events = <TimelineEvent>[
      ..._crisisEvents(sortedLogs, sortedCycle),
      ..._painChangeEvents(sortedLogs),
      ..._newSymptomEvents(sortedLogs),
      ..._periodStartEvents(sortedCycle, now),
      ..._treatmentEvents(treatments, now),
      ..._effectEvents(treatmentEffects),
      ..._appointmentEvents(appointments, now),
      ..._impactEvents(impactLogs),
    ];

    events.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byType = a.type.index.compareTo(b.type.index);
      if (byType != 0) return byType;
      return a.id.compareTo(b.id);
    });
    return newestFirst ? events.reversed.toList(growable: false) : events;
  }

  /// Filtra por categorias e por data mínima (inclusive), mantendo a ordem.
  static List<TimelineEvent> filter(
    Iterable<TimelineEvent> events, {
    Set<TimelineCategory>? categories,
    DateTime? since,
  }) {
    final normalizedSince =
        since != null ? SymptomLog.normalizeDate(since) : null;
    return events
        .where(
          (e) =>
              (categories == null ||
                  categories.isEmpty ||
                  categories.contains(e.category)) &&
              (normalizedSince == null || !e.date.isBefore(normalizedSince)),
        )
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Crises (dor >= 7 em symptomLogs ou crise marcada no calendário),
  // agrupando dias consecutivos em um único episódio.
  // ---------------------------------------------------------------------------
  static List<TimelineEvent> _crisisEvents(
    List<SymptomLog> logs,
    List<CycleEntry> cycle,
  ) {
    final painByDay = <String, int>{};
    final symptomsByDay = <String, Set<String>>{};
    final crisisDays = <String, DateTime>{};

    for (final log in logs) {
      if (log.dor >= crisisPainThreshold) {
        final key = SymptomLog.dateKeyFor(log.data);
        crisisDays[key] = SymptomLog.normalizeDate(log.data);
      }
    }
    for (final entry in cycle) {
      if (entry.crise) {
        final key = SymptomLog.dateKeyFor(entry.data);
        crisisDays[key] = SymptomLog.normalizeDate(entry.data);
      }
    }
    if (crisisDays.isEmpty) return const [];

    for (final log in logs) {
      final key = SymptomLog.dateKeyFor(log.data);
      if (!crisisDays.containsKey(key)) continue;
      painByDay[key] = log.dor;
      symptomsByDay[key] = {...log.tipos};
    }

    final days = crisisDays.values.toList()..sort();
    final episodes = <List<DateTime>>[];
    for (final day in days) {
      if (episodes.isNotEmpty &&
          day.difference(episodes.last.last).inDays == 1) {
        episodes.last.add(day);
      } else {
        episodes.add([day]);
      }
    }

    return episodes.map((episode) {
      final first = episode.first;
      final last = episode.last;
      final keys = episode.map(SymptomLog.dateKeyFor).toList(growable: false);
      final pains = keys.map((k) => painByDay[k]).whereType<int>().toList();
      final peak = pains.isEmpty ? null : pains.reduce((a, b) => a > b ? a : b);
      final symptoms = <String>{
        for (final k in keys) ...?symptomsByDay[k],
      }.take(3).toList(growable: false);

      final parts = <String>[
        if (peak != null) 'Pico de dor $peak/10',
        if (episode.length > 1) 'Até ${_dayMonth(last)}',
        if (symptoms.isNotEmpty) symptoms.join(', '),
      ];

      return TimelineEvent(
        id: 'crise_${keys.first}',
        type: TimelineEventType.crisis,
        date: first,
        title: episode.length > 1
            ? 'Crise de sintomas • ${episode.length} dias'
            : 'Crise de sintomas',
        subtitle: parts.isEmpty ? 'Marcada no calendário' : parts.join(' • '),
        isHighlighted: peak != null && peak >= 9,
      );
    }).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Mudanças de sintomas: variação >= 2 pontos na dor média entre semanas
  // próximas com registro (sem afirmar causa).
  // ---------------------------------------------------------------------------
  static List<TimelineEvent> _painChangeEvents(List<SymptomLog> logs) {
    if (logs.length < 2) return const [];

    final byWeek = <DateTime, List<SymptomLog>>{};
    for (final log in logs) {
      final day = SymptomLog.normalizeDate(log.data);
      final weekStart = day.subtract(Duration(days: day.weekday - 1));
      byWeek.putIfAbsent(weekStart, () => []).add(log);
    }
    final weeks = byWeek.keys.toList()..sort();

    final events = <TimelineEvent>[];
    for (var i = 1; i < weeks.length; i++) {
      final prevWeek = weeks[i - 1];
      final currWeek = weeks[i];
      // Só compara semanas próximas (até 14 dias de distância).
      if (currWeek.difference(prevWeek).inDays > 14) continue;

      final prevAvg = _averagePain(byWeek[prevWeek]!);
      final currAvg = _averagePain(byWeek[currWeek]!);
      final delta = currAvg - prevAvg;
      if (delta.abs() < painChangeThreshold) continue;

      final increased = delta > 0;
      final firstLogOfWeek = byWeek[currWeek]!
          .map((l) => SymptomLog.normalizeDate(l.data))
          .reduce((a, b) => a.isBefore(b) ? a : b);

      events.add(
        TimelineEvent(
          id: 'dor_semana_${SymptomLog.dateKeyFor(currWeek)}',
          type: increased
              ? TimelineEventType.painIncreased
              : TimelineEventType.painDecreased,
          date: firstLogOfWeek,
          title: increased ? 'Dor média aumentou' : 'Dor média diminuiu',
          subtitle:
              'De ${_decimal(prevAvg)} para ${_decimal(currAvg)}/10 em relação à semana anterior registrada',
        ),
      );
    }
    return events;
  }

  // ---------------------------------------------------------------------------
  // Mudanças de sintomas: sintomas registrados pela primeira vez na janela de
  // 30 dias (ignora o primeiro registro do histórico, que é a linha de base).
  // ---------------------------------------------------------------------------
  static List<TimelineEvent> _newSymptomEvents(List<SymptomLog> logs) {
    if (logs.length < 2) return const [];

    final lastSeen = <String, DateTime>{};
    final events = <TimelineEvent>[];

    for (var i = 0; i < logs.length; i++) {
      final log = logs[i];
      final day = SymptomLog.normalizeDate(log.data);
      final symptoms = <String>{
        ...log.tipos,
        ...log.intestinal,
        ...log.urinario,
      };

      if (i > 0) {
        final fresh = symptoms.where((s) {
          final seen = lastSeen[s];
          return seen == null ||
              day.difference(seen).inDays > newSymptomLookbackDays;
        }).toList(growable: false);

        if (fresh.isNotEmpty) {
          events.add(
            TimelineEvent(
              id: 'novo_sintoma_${SymptomLog.dateKeyFor(day)}',
              type: TimelineEventType.newSymptom,
              date: day,
              title: fresh.length == 1
                  ? 'Novo sintoma registrado: ${fresh.first}'
                  : 'Novos sintomas registrados: ${fresh.join(', ')}',
              subtitle:
                  'Não aparecia nos seus registros dos $newSymptomLookbackDays dias anteriores',
            ),
          );
        }
      }

      for (final s in symptoms) {
        lastSeen[s] = day;
      }
    }
    return events;
  }

  // ---------------------------------------------------------------------------
  // Ciclo: inícios de menstruação detectados pelo motor do calendário.
  // ---------------------------------------------------------------------------
  static List<TimelineEvent> _periodStartEvents(
    List<CycleEntry> cycle,
    DateTime now,
  ) {
    if (cycle.isEmpty) return const [];
    final estimate = CyclePredictionEngine.compute(
      entries: cycle,
      referenceDate: SymptomLog.normalizeDate(now),
    );
    final flowByKey = <String, MenstrualFlowLevel?>{
      for (final e in cycle) SymptomLog.dateKeyFor(e.data): e.fluxo,
    };

    return estimate.periodStarts.map((start) {
      final key = SymptomLog.dateKeyFor(start);
      final flow = flowByKey[key];
      return TimelineEvent(
        id: 'menstruacao_$key',
        type: TimelineEventType.periodStarted,
        date: SymptomLog.normalizeDate(start),
        title: 'Início da menstruação',
        subtitle: flow != null ? 'Fluxo ${flow.label.toLowerCase()}' : null,
      );
    }).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Tratamentos: início e encerramento.
  // ---------------------------------------------------------------------------
  static List<TimelineEvent> _treatmentEvents(
    Iterable<Treatment> treatments,
    DateTime now,
  ) {
    final events = <TimelineEvent>[];
    for (final t in treatments) {
      final details = <String>[
        t.categoria.label,
        if (t.dose != null && t.dose!.trim().isNotEmpty) t.dose!.trim(),
      ].join(' • ');

      events.add(
        TimelineEvent(
          id: 'tratamento_inicio_${t.id}',
          type: TimelineEventType.treatmentStarted,
          date: SymptomLog.normalizeDate(t.inicio),
          title: 'Início do tratamento: ${t.medicamento}',
          subtitle: details,
          isUpcoming: t.inicio.isAfter(now),
        ),
      );

      final end = t.fim;
      if (end != null && (!t.ativo || !end.isAfter(now))) {
        events.add(
          TimelineEvent(
            id: 'tratamento_fim_${t.id}',
            type: TimelineEventType.treatmentEnded,
            date: SymptomLog.normalizeDate(end),
            title: 'Tratamento encerrado: ${t.medicamento}',
            subtitle:
                'Em uso de ${_fullDate(t.inicio)} até ${_fullDate(end)}',
          ),
        );
      }
    }
    return events;
  }

  static List<TimelineEvent> _effectEvents(Iterable<TreatmentEffect> effects) {
    return effects.map((eff) {
      return TimelineEvent(
        id: 'efeito_${eff.id}',
        type: TimelineEventType.treatmentEffect,
        date: SymptomLog.normalizeDate(eff.data),
        title: 'Efeito percebido: ${eff.efeito}',
        subtitle:
            '${eff.tipo.label} • ${eff.treatmentName} • ${eff.intensidade}/10',
      );
    }).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Consultas, exames, cirurgias e procedimentos.
  // ---------------------------------------------------------------------------
  static List<TimelineEvent> _appointmentEvents(
    Iterable<MedicalAppointment> appointments,
    DateTime now,
  ) {
    return appointments.map((appt) {
      final type = switch (appt.tipo) {
        AppointmentType.consultation => TimelineEventType.consultation,
        AppointmentType.exam => TimelineEventType.exam,
        AppointmentType.procedure => TimelineEventType.procedure,
      };
      final isUpcoming =
          appt.status == AppointmentStatus.scheduled && appt.data.isAfter(now);
      final statusLabel = switch (appt.status) {
        AppointmentStatus.scheduled =>
          isUpcoming ? 'Agendado' : 'Agendado (data passada)',
        AppointmentStatus.completed => 'Realizado',
        AppointmentStatus.canceled => 'Cancelado',
      };
      final h = appt.data.hour.toString().padLeft(2, '0');
      final m = appt.data.minute.toString().padLeft(2, '0');

      final parts = <String>[
        '$statusLabel • ${_dayMonth(appt.data)} às $h:$m',
        if (appt.local != null && appt.local!.trim().isNotEmpty)
          appt.local!.trim(),
        if (appt.profissional != null && appt.profissional!.trim().isNotEmpty)
          appt.profissional!.trim(),
      ];

      return TimelineEvent(
        id: 'agendamento_${appt.id}',
        type: type,
        date: appt.data,
        title: '${appt.tipo.label}: ${appt.titulo}',
        subtitle: parts.join(' • '),
        isUpcoming: isUpcoming,
        isHighlighted: type == TimelineEventType.procedure &&
            appt.status == AppointmentStatus.completed,
      );
    }).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Diário de impacto.
  // ---------------------------------------------------------------------------
  static List<TimelineEvent> _impactEvents(Iterable<ImpactLog> logs) {
    final events = <TimelineEvent>[];
    for (final log in logs) {
      if (!log.hasAnyLevel) continue;
      final high = log.highImpactAreas;
      final shown = (high.isNotEmpty ? high : log.rankedAreas.take(2))
          .map((e) => '${e.key.label} ${e.value}/10')
          .join(', ');
      events.add(
        TimelineEvent(
          id: 'impacto_${SymptomLog.dateKeyFor(log.data)}',
          type: TimelineEventType.impactLogged,
          date: SymptomLog.normalizeDate(log.data),
          title: high.isNotEmpty
              ? 'Alto impacto na rotina'
              : 'Impacto na rotina registrado',
          subtitle: shown,
          isHighlighted: high.isNotEmpty,
        ),
      );
    }
    return events;
  }

  // ---------------------------------------------------------------------------
  // Utilitários de formatação independentes de locale (seguros em testes).
  // ---------------------------------------------------------------------------
  static double _averagePain(List<SymptomLog> logs) {
    final total = logs.fold<int>(0, (sum, l) => sum + l.dor);
    return total / logs.length;
  }

  static String _decimal(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');

  static String _dayMonth(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  static String _fullDate(DateTime date) =>
      '${_dayMonth(date)}/${date.year}';
}

