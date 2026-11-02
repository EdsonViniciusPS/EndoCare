import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Natureza do efeito percebido durante um tratamento.
enum TreatmentEffectKind {
  relief('alivio', 'Alívio percebido'),
  sideEffect('colateral', 'Efeito adverso'),
  observation('observacao', 'Observação');

  const TreatmentEffectKind(this.code, this.label);

  final String code;
  final String label;

  static TreatmentEffectKind fromCode(String? raw) {
    for (final item in values) {
      if (item.code == raw?.trim()) return item;
    }
    return TreatmentEffectKind.observation;
  }
}

/// Sugestões rápidas de efeitos percebidos comuns em tratamentos para endometriose.
abstract final class TreatmentEffectCatalog {
  static const List<String> reliefExamples = [
    'Redução da cólica',
    'Menor dor pélvica',
    'Controle do fluxo',
    'Melhora do sono',
  ];

  static const List<String> sideEffectExamples = [
    'Escape / spotting',
    'Náusea leve',
    'Dor de cabeça',
    'Inchaço / retenção',
    'Oscilação de humor',
    'Sensibilidade mamária',
  ];
}

/// Registro de efeito percebido (`users/{uid}/treatmentEffects/{id}`).
class TreatmentEffect {
  const TreatmentEffect({
    required this.id,
    required this.treatmentId,
    required this.treatmentName,
    required this.data,
    required this.efeito,
    this.tipo = TreatmentEffectKind.relief,
    this.intensidade = 5,
    this.notas,
  });

  final String id;
  final String treatmentId;
  final String treatmentName;
  final DateTime data;
  final String efeito;
  final TreatmentEffectKind tipo;
  final int intensidade;
  final String? notas;

  Map<String, dynamic> toFirestoreMap() {
    final trimmedNotas = notas?.trim();
    return <String, dynamic>{
      'treatmentId': treatmentId,
      'treatmentName': treatmentName.trim(),
      'data': Timestamp.fromDate(SymptomLog.normalizeDate(data)),
      'efeito': efeito.trim(),
      'tipo': tipo.code,
      'intensidade': intensidade.clamp(0, 10),
      'notas': (trimmedNotas != null && trimmedNotas.isNotEmpty)
          ? trimmedNotas
          : null,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory TreatmentEffect.fromFirestoreDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? const <String, dynamic>{};
    final rawDate = map['data'];
    final rawIntensity = map['intensidade'];

    return TreatmentEffect(
      id: doc.id,
      treatmentId: (map['treatmentId'] as String?) ?? '',
      treatmentName:
          (map['treatmentName'] as String?)?.trim() ?? 'Tratamento',
      data: rawDate is Timestamp
          ? SymptomLog.normalizeDate(rawDate.toDate())
          : SymptomLog.normalizeDate(DateTime.now()),
      efeito: (map['efeito'] as String?)?.trim() ?? '',
      tipo: TreatmentEffectKind.fromCode(map['tipo'] as String?),
      intensidade:
          rawIntensity is num ? rawIntensity.round().clamp(0, 10) : 5,
      notas: map['notas'] as String?,
    );
  }
}

