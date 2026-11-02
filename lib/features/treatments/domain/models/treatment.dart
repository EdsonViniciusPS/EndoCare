import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Categoria clínica do medicamento ou tratamento acompanhado.
enum TreatmentCategory {
  hormonal('hormonal', 'Hormonal contínuo'),
  analgesic('analgesico', 'Analgésico / Anti-inflamatório'),
  supplement('suplemento', 'Suplemento'),
  therapy('terapia', 'Fisioterapia / Terapia'),
  other('outro', 'Outro tratamento');

  const TreatmentCategory(this.code, this.label);

  final String code;
  final String label;

  static TreatmentCategory fromCode(String? raw) {
    for (final value in values) {
      if (value.code == raw?.trim()) return value;
    }
    return TreatmentCategory.other;
  }
}

/// Modelo de medicamento ou tratamento (`users/{uid}/treatments/{id}`).
class Treatment {
  const Treatment({
    required this.id,
    required this.medicamento,
    required this.inicio,
    this.categoria = TreatmentCategory.hormonal,
    this.dose,
    this.horarios = const [],
    this.fim,
    this.ativo = true,
    this.lembretesAtivos = true,
    this.notas,
  });

  final String id;
  final String medicamento;
  final TreatmentCategory categoria;
  final String? dose;

  /// Lista de horários diários no formato `"HH:mm"` (ex.: `["08:00", "20:00"]`).
  final List<String> horarios;
  final DateTime inicio;
  final DateTime? fim;
  final bool ativo;
  final bool lembretesAtivos;
  final String? notas;

  /// Formata horas e minutos em `"HH:mm"`.
  static String formatTimeSlot(int hour, int minute) {
    final h = hour.clamp(0, 23).toString().padLeft(2, '0');
    final m = minute.clamp(0, 59).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Converte `"HH:mm"` em `(hour, minute)` ou retorna `null` se inválido.
  static ({int hour, int minute})? tryParseTimeSlot(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return (hour: h, minute: m);
  }

  /// Normaliza e ordena uma coleção de horários `"HH:mm"` sem duplicatas.
  static List<String> normalizeTimeSlots(Iterable<String> rawSlots) {
    final normalized = <String>{};
    for (final item in rawSlots) {
      final parsed = tryParseTimeSlot(item);
      if (parsed != null) {
        normalized.add(formatTimeSlot(parsed.hour, parsed.minute));
      }
    }
    final sorted = normalized.toList()..sort();
    return sorted;
  }

  /// Retorna o próximo instante de disparo (`DateTime`) a partir de `reference`
  /// quando o tratamento e seus lembretes estão ativos.
  DateTime? nextReminderFrom(DateTime reference) {
    if (!ativo || !lembretesAtivos || horarios.isEmpty) return null;
    if (fim != null &&
        SymptomLog.normalizeDate(reference)
            .isAfter(SymptomLog.normalizeDate(fim!))) {
      return null;
    }

    final baseDay = SymptomLog.normalizeDate(
      reference.isBefore(inicio) ? inicio : reference,
    );

    DateTime? earliest;
    for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final day = baseDay.add(Duration(days: dayOffset));
      if (fim != null && day.isAfter(SymptomLog.normalizeDate(fim!))) {
        continue;
      }
      for (final slot in horarios) {
        final parsed = tryParseTimeSlot(slot);
        if (parsed == null) continue;
        final candidate = DateTime(
          day.year,
          day.month,
          day.day,
          parsed.hour,
          parsed.minute,
        );
        if (!candidate.isBefore(reference)) {
          if (earliest == null || candidate.isBefore(earliest)) {
            earliest = candidate;
          }
        }
      }
      if (earliest != null) break;
    }
    return earliest;
  }

  Treatment copyWith({
    String? id,
    String? medicamento,
    TreatmentCategory? categoria,
    String? dose,
    bool clearDose = false,
    List<String>? horarios,
    DateTime? inicio,
    DateTime? fim,
    bool clearFim = false,
    bool? ativo,
    bool? lembretesAtivos,
    String? notas,
    bool clearNotas = false,
  }) {
    return Treatment(
      id: id ?? this.id,
      medicamento: medicamento ?? this.medicamento,
      categoria: categoria ?? this.categoria,
      dose: clearDose ? null : (dose ?? this.dose),
      horarios:
          horarios != null ? normalizeTimeSlots(horarios) : this.horarios,
      inicio: inicio != null ? SymptomLog.normalizeDate(inicio) : this.inicio,
      fim: clearFim
          ? null
          : (fim != null ? SymptomLog.normalizeDate(fim) : this.fim),
      ativo: ativo ?? this.ativo,
      lembretesAtivos: lembretesAtivos ?? this.lembretesAtivos,
      notas: clearNotas ? null : (notas ?? this.notas),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final trimmedDose = dose?.trim();
    final trimmedNotas = notas?.trim();
    return <String, dynamic>{
      'medicamento': medicamento.trim(),
      'categoria': categoria.code,
      'dose': (trimmedDose != null && trimmedDose.isNotEmpty)
          ? trimmedDose
          : null,
      'horarios': normalizeTimeSlots(horarios),
      'inicio': Timestamp.fromDate(SymptomLog.normalizeDate(inicio)),
      'fim': fim != null
          ? Timestamp.fromDate(SymptomLog.normalizeDate(fim!))
          : null,
      'ativo': ativo,
      'lembretesAtivos': lembretesAtivos,
      'notas': (trimmedNotas != null && trimmedNotas.isNotEmpty)
          ? trimmedNotas
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Treatment.fromFirestoreDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? const <String, dynamic>{};
    final rawInicio = map['inicio'];
    final rawFim = map['fim'];
    final rawHorarios = map['horarios'];

    final slots = rawHorarios is Iterable
        ? normalizeTimeSlots(rawHorarios.whereType<String>())
        : const <String>[];

    return Treatment(
      id: doc.id,
      medicamento: (map['medicamento'] as String?)?.trim() ?? 'Medicamento',
      categoria: TreatmentCategory.fromCode(map['categoria'] as String?),
      dose: map['dose'] as String?,
      horarios: slots,
      inicio: rawInicio is Timestamp
          ? SymptomLog.normalizeDate(rawInicio.toDate())
          : SymptomLog.normalizeDate(DateTime.now()),
      fim: rawFim is Timestamp
          ? SymptomLog.normalizeDate(rawFim.toDate())
          : null,
      ativo: (map['ativo'] as bool?) ?? true,
      lembretesAtivos: (map['lembretesAtivos'] as bool?) ?? true,
      notas: map['notas'] as String?,
    );
  }
}

