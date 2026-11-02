import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Contrato de persistência dos registros diários de sintomas em
/// `users/{uid}/symptomLogs/{logId}`.
abstract interface class SymptomLogRepository {
  /// Observa em tempo real o registro de sintomas de uma data específica.
  Stream<SymptomLog?> watchLogForDate({
    required String uid,
    required DateTime date,
  });

  /// Observa os registros históricos da usuária a partir de `sinceDate` (opcional).
  Stream<List<SymptomLog>> watchLogs({
    required String uid,
    DateTime? sinceDate,
  });

  /// Busca o registro de uma data específica (se existir).
  Future<SymptomLog?> getLogForDate({
    required String uid,
    required DateTime date,
  });

  /// Busca o registro do dia imediatamente anterior (ou o último registro anterior
  /// disponível) para pré-preencher valores padrão e agilizar o registro.
  Future<SymptomLog?> getPreviousLogBefore({
    required String uid,
    required DateTime date,
  });

  /// Salva ou atualiza o registro diário em `users/{uid}/symptomLogs/{yyyy-MM-dd}`.
  Future<void> saveLog({
    required String uid,
    required SymptomLog log,
  });
}
