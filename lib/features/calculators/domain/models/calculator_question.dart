/// Tipo de entrada para a pergunta de uma calculadora clínica.
enum QuestionInputType {
  /// Opções discretas (chips ou botões com pontuação associada).
  options,

  /// Controle deslizante contínuo/discreto (ex.: Escala EVA 0 a 10).
  slider,

  /// Entrada numérica simples (ex.: dias do ciclo menstrual).
  number,
}

/// Opção selecionável de uma pergunta de questionário clínico.
class CalculatorQuestionOption {
  const CalculatorQuestionOption({
    required this.label,
    required this.score,
    this.subtitle,
  });

  final String label;
  final num score;
  final String? subtitle;
}

/// Pergunta individual de uma calculadora clínica.
///
/// Configurada por dados, suportando exibição passo a passo de uma pergunta
/// por tela, de acordo com a seção 07 do EndoCare.md.
class CalculatorQuestion {
  const CalculatorQuestion({
    required this.id,
    required this.text,
    this.hint,
    this.type = QuestionInputType.options,
    this.options = const [],
    this.minSliderValue = 0,
    this.maxSliderValue = 10,
    this.sliderDivisions = 10,
    this.sliderMinLabel,
    this.sliderMaxLabel,
    this.isCrisisTrigger = false,
  });

  final String id;
  final String text;
  final String? hint;
  final QuestionInputType type;
  final List<CalculatorQuestionOption> options;

  final double minSliderValue;
  final double maxSliderValue;
  final int sliderDivisions;
  final String? sliderMinLabel;
  final String? sliderMaxLabel;

  /// Indica se esta questão rastreia pensamentos autolesivos (ex.: PHQ-9 item 9).
  final bool isCrisisTrigger;
}

