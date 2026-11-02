import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/body_map/domain/models/body_region_pain_entry.dart';

/// Dados de dor durante ou após relações sexuais (`dorRelacao{local, escala}`).
class SexualPainEntry {
  const SexualPainEntry({
    required this.local,
    required this.escala,
  });

  final String local;
  final int escala;

  factory SexualPainEntry.fromMap(Map<String, dynamic> map) {
    return SexualPainEntry(
      local: (map['local'] as String?)?.trim() ?? '',
      escala: ((map['escala'] as num?)?.round() ?? 0).clamp(0, 10),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'local': local.trim(),
      'escala': escala.clamp(0, 10),
    };
  }
}

/// Modelo do documento `users/{uid}/symptomLogs/{logId}` conforme a seção 5.1
/// do EndoCare.md, integrado ao Mapa Corporal (`mapaCorporal`).
class SymptomLog {
  const SymptomLog({
    required this.id,
    required this.data,
    required this.dor,
    this.sono = 7,
    this.humor,
    this.tipos = const [],
    this.regioes = const [],
    this.mapaCorporal = const [],
    this.colica,
    this.dorRelacao,
    this.intestinal = const [],
    this.urinario = const [],
    this.fadiga,
    this.nausea,
    this.inchaco,
    this.notas,
    this.atualizadoEm,
  });

  /// Identificador canônico do dia (`yyyy-MM-dd`).
  final String id;

  /// Data normalizada (início do dia local) do registro.
  final DateTime data;

  /// Intensidade geral da dor (0–10).
  final int dor;

  /// Qualidade do sono (0–10).
  final int sono;

  /// Humor selecionado no dia.
  final String? humor;

  /// Chips rápidos de sintomas marcados no dia (`tipos[]`).
  final List<String> tipos;

  /// Lista legível de regiões anatômicas de dor (`regioes[]`).
  final List<String> regioes;

  /// Entradas estruturadas do Mapa Corporal (intensidade, tipo, duração, frequência).
  final List<BodyRegionPainEntry> mapaCorporal;

  /// Intensidade específica de cólicas e dores pélvicas (0–10, opcional).
  final int? colica;

  /// Registro opcional de dor durante/após relação sexual.
  final SexualPainEntry? dorRelacao;

  /// Sintomas intestinais detalhados.
  final List<String> intestinal;

  /// Sintomas urinários detalhados.
  final List<String> urinario;

  /// Escala opcional de fadiga (0–10).
  final int? fadiga;

  /// Escala opcional de náusea (0–10).
  final int? nausea;

  /// Escala opcional de inchaço (0–10).
  final int? inchaco;

  /// Observações livres da paciente (até 2000 caracteres).
  final String? notas;

  /// Data/hora da última gravação.
  final DateTime? atualizadoEm;

  /// Quantidade de campos preenchidos na seção de detalhes opcionais.
  int get optionalDetailsCount {
    var count = 0;
    if (colica != null) count++;
    if (regioes.isNotEmpty) count++;
    if (dorRelacao != null) count++;
    if (intestinal.isNotEmpty) count++;
    if (urinario.isNotEmpty) count++;
    if (fadiga != null) count++;
    if (nausea != null) count++;
    if (inchaco != null) count++;
    if (notas != null && notas!.trim().isNotEmpty) count++;
    return count;
  }

  SymptomLog copyWith({
    String? id,
    DateTime? data,
    int? dor,
    int? sono,
    String? humor,
    List<String>? tipos,
    List<String>? regioes,
    List<BodyRegionPainEntry>? mapaCorporal,
    int? colica,
    SexualPainEntry? dorRelacao,
    List<String>? intestinal,
    List<String>? urinario,
    int? fadiga,
    int? nausea,
    int? inchaco,
    String? notas,
    DateTime? atualizadoEm,
  }) {
    return SymptomLog(
      id: id ?? this.id,
      data: data ?? this.data,
      dor: dor ?? this.dor,
      sono: sono ?? this.sono,
      humor: humor ?? this.humor,
      tipos: tipos ?? this.tipos,
      regioes: regioes ?? this.regioes,
      mapaCorporal: mapaCorporal ?? this.mapaCorporal,
      colica: colica ?? this.colica,
      dorRelacao: dorRelacao ?? this.dorRelacao,
      intestinal: intestinal ?? this.intestinal,
      urinario: urinario ?? this.urinario,
      fadiga: fadiga ?? this.fadiga,
      nausea: nausea ?? this.nausea,
      inchaco: inchaco ?? this.inchaco,
      notas: notas ?? this.notas,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  /// Normaliza uma data para `00:00:00` local.
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gera a chave determinística `yyyy-MM-dd` para `symptomLogs/{logId}`.
  static String dateKeyFor(DateTime date) {
    final normalized = normalizeDate(date);
    final y = normalized.year.toString().padLeft(4, '0');
    final m = normalized.month.toString().padLeft(2, '0');
    final d = normalized.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Converte uma string `yyyy-MM-dd` em `DateTime` normalizado (ou `null`).
  static DateTime? tryParseDateKey(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Cria valores iniciais para `targetDate` reaproveitando os sintomas habituais
  /// do registro anterior (sem copiar notas livres ou evento pontual de relação).
  factory SymptomLog.prefilledFromPrevious({
    required DateTime targetDate,
    required SymptomLog previous,
  }) {
    final normalized = normalizeDate(targetDate);
    return SymptomLog(
      id: dateKeyFor(normalized),
      data: normalized,
      dor: previous.dor,
      sono: previous.sono,
      humor: previous.humor,
      tipos: List<String>.from(previous.tipos),
      regioes: List<String>.from(previous.regioes),
      mapaCorporal: List<BodyRegionPainEntry>.from(previous.mapaCorporal),
      colica: previous.colica,
      intestinal: List<String>.from(previous.intestinal),
      urinario: List<String>.from(previous.urinario),
      fadiga: previous.fadiga,
      nausea: previous.nausea,
      inchaco: previous.inchaco,
    );
  }

  /// Estado inicial limpo quando ainda não há registro anterior.
  factory SymptomLog.emptyForDate(DateTime targetDate) {
    final normalized = normalizeDate(targetDate);
    return SymptomLog(
      id: dateKeyFor(normalized),
      data: normalized,
      dor: 0,
      sono: 7,
    );
  }

  factory SymptomLog.fromFirestore(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final rawDate = map['data'];
    final resolvedDate = rawDate is Timestamp
        ? normalizeDate(rawDate.toDate())
        : (rawDate is DateTime ? normalizeDate(rawDate) : DateTime.now());

    final rawSexualPain = map['dorRelacao'];
    final sexualPain = rawSexualPain is Map<String, dynamic>
        ? SexualPainEntry.fromMap(rawSexualPain)
        : null;

    final rawBodyMap = map['mapaCorporal'];
    final bodyEntries = rawBodyMap is Iterable
        ? rawBodyMap
            .whereType<Map<String, dynamic>>()
            .map(BodyRegionPainEntry.fromMap)
            .where((e) => e.regionId.isNotEmpty)
            .toList(growable: false)
        : const <BodyRegionPainEntry>[];

    final rawUpdated = map['atualizadoEm'];
    final updatedAt = rawUpdated is Timestamp
        ? rawUpdated.toDate()
        : (rawUpdated is DateTime ? rawUpdated : null);

    return SymptomLog(
      id: id,
      data: resolvedDate,
      dor: ((map['dor'] as num?)?.round() ?? 0).clamp(0, 10),
      sono: ((map['sono'] as num?)?.round() ?? 7).clamp(0, 10),
      humor: (map['humor'] as String?)?.trim().isNotEmpty == true
          ? (map['humor'] as String).trim()
          : null,
      tipos: _toStringList(map['tipos']),
      regioes: _toStringList(map['regioes']),
      mapaCorporal: bodyEntries,
      colica: _toOptionalScore(map['colica']),
      dorRelacao: sexualPain,
      intestinal: _toStringList(map['intestinal']),
      urinario: _toStringList(map['urinario']),
      fadiga: _toOptionalScore(map['fadiga']),
      nausea: _toOptionalScore(map['nausea']),
      inchaco: _toOptionalScore(map['inchaco']),
      notas: (map['notas'] as String?)?.trim().isNotEmpty == true
          ? (map['notas'] as String).trim()
          : null,
      atualizadoEm: updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final normalized = normalizeDate(data);
    final trimmedNotes = notas?.trim();
    final safeNotes = trimmedNotes != null && trimmedNotes.isNotEmpty
        ? (trimmedNotes.length > 2000
            ? trimmedNotes.substring(0, 2000)
            : trimmedNotes)
        : null;

    // Mantém `regioes` sincronizado com os nomes das regiões do Mapa Corporal.
    final mergedRegions = <String>{
      ...regioes,
      ...mapaCorporal.map((e) => e.regionLabel),
    }.toList(growable: false);

    return {
      'dateKey': dateKeyFor(normalized),
      'data': Timestamp.fromDate(normalized),
      'dor': dor.clamp(0, 10),
      'sono': sono.clamp(0, 10),
      'humor': humor,
      'tipos': tipos,
      'regioes': mergedRegions,
      'mapaCorporal': mapaCorporal.map((e) => e.toMap()).toList(growable: false),
      'colica': colica?.clamp(0, 10),
      'dorRelacao': dorRelacao?.toMap(),
      'intestinal': intestinal,
      'urinario': urinario,
      'fadiga': fadiga?.clamp(0, 10),
      'nausea': nausea?.clamp(0, 10),
      'inchaco': inchaco?.clamp(0, 10),
      'notas': safeNotes,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  static List<String> _toStringList(Object? raw) {
    if (raw is Iterable) {
      return raw
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  static int? _toOptionalScore(Object? raw) {
    if (raw is num) {
      return raw.round().clamp(0, 10);
    }
    return null;
  }
}
