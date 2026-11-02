import 'package:endocare/features/calculators/domain/models/calculator_result.dart';

/// Contrato de persistência dos resultados de calculadoras clínicas
/// (`users/{uid}/calculatorResults/{id}`).
abstract class CalculatorRepository {
  /// Observa todos os resultados de calculadoras da usuária em ordem cronológica decrescente.
  Stream<List<CalculatorResult>> watchResults({required String uid});

  /// Busca o histórico de avaliações de uma calculadora específica.
  Future<List<CalculatorResult>> getResultsForCalculator({
    required String uid,
    required String calculatorId,
  });

  /// Retorna a última avaliação realizada para determinada calculadora (ou null se nunca realizada).
  Future<CalculatorResult?> getLatestResult({
    required String uid,
    required String calculatorId,
  });

  /// Salva um novo resultado de questionário.
  Future<void> saveResult({
    required String uid,
    required CalculatorResult result,
  });

  /// Remove um resultado de avaliação.
  Future<void> deleteResult({
    required String uid,
    required String resultId,
  });
}

