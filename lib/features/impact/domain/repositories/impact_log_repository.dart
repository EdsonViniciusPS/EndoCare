import 'package:endocare/features/impact/domain/models/impact_log.dart';

/// Contrato de persistência do Diário de impacto
/// (`users/{uid}/impactLogs/{yyyy-MM-dd}`).
abstract class ImpactLogRepository {
  /// Observa em tempo real os registros de impacto (mais recentes primeiro).
  Stream<List<ImpactLog>> watchLogs({required String uid});

  /// Busca o registro de impacto de um dia específico.
  Future<ImpactLog?> getLogForDate({
    required String uid,
    required DateTime date,
  });

  /// Cria ou atualiza o registro do dia (`id` = `yyyy-MM-dd`).
  Future<void> saveLog({
    required String uid,
    required ImpactLog log,
  });

  /// Remove o registro de impacto do dia.
  Future<void> deleteLog({
    required String uid,
    required DateTime date,
  });
}

