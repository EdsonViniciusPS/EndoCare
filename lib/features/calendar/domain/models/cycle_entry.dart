import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Intensidade do fluxo menstrual ou sangramento de escape.
enum MenstrualFlowLevel {
  spotting('escape', 'Escape', 1),
  light('leve', 'Leve', 2),
  moderate('moderado', 'Moderado', 3),
  heavy('intenso', 'Intenso', 4),
  veryHeavy('muito_intenso', 'Muito intenso', 5);

  const MenstrualFlowLevel(this.code, this.label, this.weight);

  final String code;
  final String label;
  final int weight;

  /// Considera fluxo menstrual propriamente dito (exclui escape isolado para
  /// não reiniciar falsamente a contagem de um novo ciclo).
  bool get isMenstrualPeriodFlow => this != MenstrualFlowLevel.spotting;

  static MenstrualFlowLevel? fromCode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    for (final value in values) {
      if (value.code == raw.trim()) return value;
    }
    return null;
  }
}

/// Opções rápidas de apoio para marcação no calendário do ciclo.
abstract final class CycleCatalog {
  static const List<String> commonMedications = [
    'Analgésico',
    'Anti-inflamatório',
    'Antiespasmódico',
    'Hormonal contínuo',
    'Suplemento',
    'Bolsa térmica / alívio',
  ];

  static const List<String> commonAppointments = [
    'Consulta ginecológica',
    'Ultrassom / Ressonância',
    'Exame laboratorial',
    'Fisioterapia pélvica',
    'Nutrição / Psicologia',
  ];
}

/// Registro diário do módulo de Calendário e Ciclo (`users/{uid}/cycleEntries/{yyyy-MM-dd}`).
class CycleEntry {
  const CycleEntry({
    required this.id,
    required this.data,
    this.fluxo,
    this.ovulacaoObservada = false,
    this.crise = false,
    this.medicamentos = const [],
    this.consultaOuExame,
    this.observacoes,
    this.updatedAt,
  });

  final String id;
  final DateTime data;
  final MenstrualFlowLevel? fluxo;
  final bool ovulacaoObservada;
  final bool crise;
  final List<String> medicamentos;
  final String? consultaOuExame;
  final String? observacoes;
  final DateTime? updatedAt;

  factory CycleEntry.emptyForDate(DateTime date) {
    final normalized = SymptomLog.normalizeDate(date);
    return CycleEntry(
      id: SymptomLog.dateKeyFor(normalized),
      data: normalized,
    );
  }

  /// Verdadeiro quando não há nenhum marcador preenchido para este dia.
  bool get isEmpty {
    return fluxo == null &&
        !ovulacaoObservada &&
        !crise &&
        medicamentos.isEmpty &&
        (consultaOuExame == null || consultaOuExame!.trim().isEmpty) &&
        (observacoes == null || observacoes!.trim().isEmpty);
  }

  CycleEntry copyWith({
    String? id,
    DateTime? data,
    MenstrualFlowLevel? fluxo,
    bool clearFluxo = false,
    bool? ovulacaoObservada,
    bool? crise,
    List<String>? medicamentos,
    String? consultaOuExame,
    bool clearConsultaOuExame = false,
    String? observacoes,
    bool clearObservacoes = false,
    DateTime? updatedAt,
  }) {
    return CycleEntry(
      id: id ?? this.id,
      data: data != null ? SymptomLog.normalizeDate(data) : this.data,
      fluxo: clearFluxo ? null : (fluxo ?? this.fluxo),
      ovulacaoObservada: ovulacaoObservada ?? this.ovulacaoObservada,
      crise: crise ?? this.crise,
      medicamentos: medicamentos ?? this.medicamentos,
      consultaOuExame: clearConsultaOuExame
          ? null
          : (consultaOuExame ?? this.consultaOuExame),
      observacoes:
          clearObservacoes ? null : (observacoes ?? this.observacoes),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final normalized = SymptomLog.normalizeDate(data);
    final trimmedAppointment = consultaOuExame?.trim();
    final trimmedNotes = observacoes?.trim();

    return <String, dynamic>{
      'data': Timestamp.fromDate(normalized),
      'fluxo': fluxo?.code,
      'ovulacaoEstimada': ovulacaoObservada,
      'ovulacaoObservada': ovulacaoObservada,
      'crise': crise,
      'medicamentos': medicamentos,
      'consultaOuExame': (trimmedAppointment != null &&
              trimmedAppointment.isNotEmpty)
          ? trimmedAppointment
          : null,
      'observacoes':
          (trimmedNotes != null && trimmedNotes.isNotEmpty) ? trimmedNotes : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CycleEntry.fromFirestoreDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? const <String, dynamic>{};
    final rawDate = map['data'];
    final parsedDate = rawDate is Timestamp
        ? SymptomLog.normalizeDate(rawDate.toDate())
        : (SymptomLog.tryParseDateKey(doc.id) ??
            SymptomLog.normalizeDate(DateTime.now()));
    final rawUpdated = map['updatedAt'];

    List<String> readStrings(dynamic value) {
      if (value is Iterable) {
        return value
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
      return const [];
    }

    final observed = (map['ovulacaoObservada'] as bool?) ??
        (map['ovulacaoEstimada'] as bool?) ??
        false;

    return CycleEntry(
      id: doc.id,
      data: parsedDate,
      fluxo: MenstrualFlowLevel.fromCode(map['fluxo'] as String?),
      ovulacaoObservada: observed,
      crise: (map['crise'] as bool?) ?? false,
      medicamentos: readStrings(map['medicamentos']),
      consultaOuExame: map['consultaOuExame'] as String?,
      observacoes: map['observacoes'] as String?,
      updatedAt: rawUpdated is Timestamp ? rawUpdated.toDate() : null,
    );
  }
}

