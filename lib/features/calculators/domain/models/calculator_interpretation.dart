/// Interpretação clínica retornada pelo motor de cálculo de um questionário.
///
/// Todas as calculadoras devem retornar pontuação, interpretação simples e
/// aviso explícito de não diagnóstico (conforme seção 3, 07 e 8 do EndoCare.md).
class CalculatorInterpretation {
  const CalculatorInterpretation({
    required this.score,
    required this.maxScore,
    required this.severityLabel,
    required this.summary,
    this.recommendations = const [],
    this.isCrisisAlert = false,
    this.crisisHelpText,
    this.disclaimer = defaultMedicalDisclaimer,
  });

  /// Pontuação calculada.
  final num score;

  /// Pontuação máxima possível na calculadora.
  final num maxScore;

  /// Rótulo de gravidade em linguagem simples (ex.: 'Leve', 'Moderada', 'Severa').
  final String severityLabel;

  /// Explicação compreensível do significado da pontuação.
  final String summary;

  /// Recomendações práticas e acolhedoras para levar ao médico ou rotina.
  final List<String> recommendations;

  /// Ativado se houver sinal de alerta imediato (ex.: item 9 do PHQ-9 > 0).
  final bool isCrisisAlert;

  /// Texto orientando apoio urgente e canais de ajuda (ex.: CVV 188).
  final String? crisisHelpText;

  /// Aviso de não diagnóstico obrigatório.
  final String disclaimer;

  static const String defaultMedicalDisclaimer =
      'Este questionário é uma ferramenta educativa de triagem e acompanhamento. '
      'O resultado obtido não constitui diagnóstico clínico nem dispensa consulta, '
      'investigação ou orientação médica e multiprofissional individualizada.';
}

