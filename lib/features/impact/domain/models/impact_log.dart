import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Áreas da vida avaliadas no Diário de impacto (seção 4.3 e 5.1 do EndoCare.md).
enum ImpactArea {
  work('trabalho', 'Trabalho', Icons.work_outline_rounded),
  studies('estudos', 'Estudos', Icons.school_outlined),
  sleep('sono', 'Sono', Icons.bedtime_outlined),
  exercise('exercicio', 'Exercícios', Icons.directions_walk_rounded),
  relationships(
    'relacionamentos',
    'Relacionamentos',
    Icons.favorite_border_rounded,
  ),
  routine('rotina', 'Rotina', Icons.home_outlined);

  const ImpactArea(this.code, this.label, this.icon);

  /// Nome do campo no Firestore (`impactLogs/{id}`).
  final String code;
  final String label;
  final IconData icon;
}

/// Níveis rápidos de impacto, para registrar com um toque (0–10).
enum ImpactQuickLevel {
  none('nenhum', 'Nenhum', 0),
  mild('leve', 'Leve', 2),
  moderate('moderado', 'Moderado', 5),
  high('alto', 'Alto', 8),
  veryHigh('muito_alto', 'Muito alto', 10);

  const ImpactQuickLevel(this.code, this.label, this.value);

  final String code;
  final String label;
  final int value;
}

/// Registro diário de impacto da dor na qualidade de vida
/// (`users/{uid}/impactLogs/{yyyy-MM-dd}`).
///
/// Cada área recebe uma nota de 0 (sem impacto) a 10 (impacto muito alto)
/// ou `null` quando não se aplica naquele dia (ex.: não houve aula).
class ImpactLog {
  const ImpactLog({
    required this.id,
    required this.data,
    this.niveis = const {},
    this.notas,
  });

  final String id;
  final DateTime data;
  final Map<ImpactArea, int> niveis;
  final String? notas;

  /// Nível considerado "alto impacto" para destaque na linha do tempo.
  static const int highImpactThreshold = 7;

  factory ImpactLog.emptyForDate(DateTime date) {
    final normalized = SymptomLog.normalizeDate(date);
    return ImpactLog(id: SymptomLog.dateKeyFor(normalized), data: normalized);
  }

  int? levelFor(ImpactArea area) => niveis[area];

  bool get hasAnyLevel => niveis.isNotEmpty;

  /// Áreas registradas, da mais impactada para a menos impactada.
  List<MapEntry<ImpactArea, int>> get rankedAreas {
    final items = niveis.entries.toList()
      ..sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        return byValue != 0 ? byValue : a.key.index.compareTo(b.key.index);
      });
    return items;
  }

  /// Áreas com impacto alto (>= 7) no dia.
  List<MapEntry<ImpactArea, int>> get highImpactAreas => rankedAreas
      .where((e) => e.value >= highImpactThreshold)
      .toList(growable: false);

  bool get isHighImpact => highImpactAreas.isNotEmpty;

  /// Média das áreas registradas (ou `null` se nenhuma).
  double? get averageLevel {
    if (niveis.isEmpty) return null;
    final total = niveis.values.fold<int>(0, (acc, v) => acc + v);
    return total / niveis.length;
  }

  /// Rótulo em linguagem simples para uma nota 0–10.
  static String levelLabel(num value) {
    final level = value.round().clamp(0, 10);
    if (level == 0) return 'Sem impacto';
    if (level <= 3) return 'Leve';
    if (level <= 6) return 'Moderado';
    if (level <= 8) return 'Alto';
    return 'Muito alto';
  }

  ImpactLog copyWithLevel(ImpactArea area, int? level) {
    final next = Map<ImpactArea, int>.from(niveis);
    if (level == null) {
      next.remove(area);
    } else {
      next[area] = level.clamp(0, 10);
    }
    return ImpactLog(id: id, data: data, niveis: next, notas: notas);
  }

  ImpactLog copyWith({
    String? id,
    DateTime? data,
    Map<ImpactArea, int>? niveis,
    String? notas,
    bool clearNotas = false,
  }) {
    return ImpactLog(
      id: id ?? this.id,
      data: data ?? this.data,
      niveis: niveis ?? this.niveis,
      notas: clearNotas ? null : (notas ?? this.notas),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final normalized = SymptomLog.normalizeDate(data);
    final trimmedNotes = notas?.trim();
    return <String, dynamic>{
      'dateKey': SymptomLog.dateKeyFor(normalized),
      'data': Timestamp.fromDate(normalized),
      for (final area in ImpactArea.values)
        area.code: niveis[area]?.clamp(0, 10),
      'notas': (trimmedNotes != null && trimmedNotes.isNotEmpty)
          ? (trimmedNotes.length > 1000
              ? trimmedNotes.substring(0, 1000)
              : trimmedNotes)
          : null,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  factory ImpactLog.fromFirestore(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final rawDate = map['data'];
    final resolvedDate = rawDate is Timestamp
        ? SymptomLog.normalizeDate(rawDate.toDate())
        : (rawDate is DateTime
            ? SymptomLog.normalizeDate(rawDate)
            : SymptomLog.tryParseDateKey(id) ??
                SymptomLog.normalizeDate(DateTime.now()));

    final levels = <ImpactArea, int>{};
    for (final area in ImpactArea.values) {
      final raw = map[area.code];
      if (raw is num) {
        levels[area] = raw.round().clamp(0, 10);
      }
    }

    final rawNotes = (map['notas'] as String?)?.trim();
    return ImpactLog(
      id: id,
      data: resolvedDate,
      niveis: levels,
      notas: (rawNotes != null && rawNotes.isNotEmpty) ? rawNotes : null,
    );
  }
}

/// Média e frequência de impacto por área em um período, para o resumo do diário.
class ImpactAreaStats {
  const ImpactAreaStats({
    required this.area,
    required this.daysRegistered,
    required this.average,
    required this.highImpactDays,
  });

  final ImpactArea area;
  final int daysRegistered;
  final double average;
  final int highImpactDays;
}

/// Agregado do Diário de impacto em uma janela de dias.
class ImpactSummary {
  const ImpactSummary({
    required this.periodDays,
    required this.daysLogged,
    required this.highImpactDays,
    required this.areaStats,
  });

  final int periodDays;
  final int daysLogged;
  final int highImpactDays;

  /// Estatísticas por área ordenadas da maior para a menor média.
  final List<ImpactAreaStats> areaStats;

  ImpactAreaStats? get mostAffectedArea =>
      areaStats.isEmpty ? null : areaStats.first;

  static ImpactSummary aggregate({
    required Iterable<ImpactLog> logs,
    required DateTime referenceDate,
    int periodDays = 30,
  }) {
    final end = SymptomLog.normalizeDate(referenceDate);
    final start = end.subtract(Duration(days: periodDays - 1));
    final inPeriod = logs
        .where(
          (log) =>
              log.hasAnyLevel &&
              !log.data.isBefore(start) &&
              !log.data.isAfter(end),
        )
        .toList(growable: false);

    final stats = <ImpactAreaStats>[];
    for (final area in ImpactArea.values) {
      final values = inPeriod
          .map((log) => log.levelFor(area))
          .whereType<int>()
          .toList(growable: false);
      if (values.isEmpty) continue;
      stats.add(
        ImpactAreaStats(
          area: area,
          daysRegistered: values.length,
          average: values.reduce((a, b) => a + b) / values.length,
          highImpactDays: values
              .where((v) => v >= ImpactLog.highImpactThreshold)
              .length,
        ),
      );
    }
    stats.sort((a, b) {
      final byAvg = b.average.compareTo(a.average);
      return byAvg != 0 ? byAvg : a.area.index.compareTo(b.area.index);
    });

    return ImpactSummary(
      periodDays: periodDays,
      daysLogged: inPeriod.length,
      highImpactDays: inPeriod.where((log) => log.isHighImpact).length,
      areaStats: stats,
    );
  }
}

