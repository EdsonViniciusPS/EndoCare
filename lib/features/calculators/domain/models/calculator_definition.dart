import 'package:endocare/features/calculators/domain/models/calculator_category.dart';
import 'package:endocare/features/calculators/domain/models/calculator_interpretation.dart';
import 'package:endocare/features/calculators/domain/models/calculator_question.dart';

/// Definição completa e configurada por dados de uma calculadora clínica.
class CalculatorDefinition {
  const CalculatorDefinition({
    required this.id,
    required this.title,
    required this.shortName,
    required this.category,
    required this.description,
    required this.instructions,
    required this.estimatedMinutes,
    required this.questions,
    required this.compute,
    this.forDoctorUse = false,
    this.doctorNotes,
  });

  final String id;
  final String title;
  final String shortName;
  final CalculatorCategory category;
  final String description;
  final String instructions;
  final int estimatedMinutes;
  final List<CalculatorQuestion> questions;
  final CalculatorInterpretation Function(Map<String, dynamic> answers) compute;

  /// Indica se a calculadora é de estadiamento ou preenchimento conjunto com médico (ex.: rASRM, Enzian).
  final bool forDoctorUse;
  final String? doctorNotes;

  int get totalQuestions => questions.length;
}

