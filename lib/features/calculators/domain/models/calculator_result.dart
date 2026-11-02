import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Resultado persistido de uma calculadora clínica (`users/{uid}/calculatorResults/{id}`).
class CalculatorResult {
  const CalculatorResult({
    required this.id,
    required this.calculadora,
    required this.titulo,
    required this.data,
    required this.pontuacao,
    required this.interpretacao,
    this.respostas = const {},
    this.grau,
    this.isCrisisAlert = false,
  });

  final String id;

  /// Identificador estável da calculadora (ex.: 'eva', 'phq9', 'gad7', 'csi', 'ehp5').
  final String calculadora;

  /// Título descritivo amigável.
  final String titulo;

  /// Momento em que a usuária realizou a avaliação.
  final DateTime data;

  /// Pontuação obtida.
  final num pontuacao;

  /// Interpretação descritiva em linguagem simples.
  final String interpretacao;

  /// Respostas brutas fornecidas pela usuária.
  final Map<String, dynamic> respostas;

  /// Rótulo curto de gravidade/grau (ex.: 'Severa', 'Moderada', 'Leve').
  final String? grau;

  /// Sinalizador de alerta imediato (ex.: item 9 do PHQ-9).
  final bool isCrisisAlert;

  Map<String, dynamic> toFirestoreMap() {
    final trimmedInterpretacao = interpretacao.trim();
    return <String, dynamic>{
      'calculadora': calculadora,
      'titulo': titulo,
      'data': Timestamp.fromDate(data),
      'pontuacao': pontuacao is double
          ? double.parse(pontuacao.toStringAsFixed(2))
          : pontuacao.toInt(),
      'interpretacao': trimmedInterpretacao.length > 2000
          ? trimmedInterpretacao.substring(0, 2000)
          : trimmedInterpretacao,
      'respostas': respostas,
      if (grau != null) 'grau': grau,
      'isCrisisAlert': isCrisisAlert,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  factory CalculatorResult.fromFirestore(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final rawDate = map['data'];
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : (rawDate is DateTime ? rawDate : DateTime.now());

    final rawScore = map['pontuacao'];
    final score = rawScore is num ? rawScore : 0;

    final rawAnswers = map['respostas'];
    final Map<String, dynamic> resolvedAnswers =
        rawAnswers is Map ? Map<String, dynamic>.from(rawAnswers) : const {};

    return CalculatorResult(
      id: id,
      calculadora: (map['calculadora'] as String?)?.trim() ?? 'calculadora',
      titulo: (map['titulo'] as String?)?.trim() ?? 'Avaliação clínica',
      data: date,
      pontuacao: score,
      interpretacao: (map['interpretacao'] as String?)?.trim() ?? '',
      respostas: resolvedAnswers,
      grau: map['grau'] as String?,
      isCrisisAlert: map['isCrisisAlert'] as bool? ?? false,
    );
  }

  String get formattedScore {
    if (pontuacao is int || pontuacao == pontuacao.roundToDouble()) {
      return '${pontuacao.round()}';
    }
    return pontuacao.toStringAsFixed(1).replaceAll('.', ',');
  }

  String get dateKey => SymptomLog.dateKeyFor(data);
}

