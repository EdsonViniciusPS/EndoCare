import 'package:endocare/features/calendar/domain/models/calendar_day_digest.dart';
import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';

/// Contrato de persistência de `users/{uid}/cycleEntries/{yyyy-MM-dd}`
/// e leitura integrada de agendamentos em `users/{uid}/appointments`.
abstract class CycleRepository {
  /// Observa em tempo real as entradas de ciclo da usuária ordenadas por data.
  Stream<List<CycleEntry>> watchEntries({
    required String uid,
    DateTime? sinceDate,
  });

  /// Busca a entrada de ciclo de uma data específica (`yyyy-MM-dd`).
  Future<CycleEntry?> getEntryForDate({
    required String uid,
    required DateTime date,
  });

  /// Salva ou atualiza a entrada de ciclo do dia (`yyyy-MM-dd`).
  /// Se `entry.isEmpty` for verdadeiro, remove o documento correspondente.
  Future<void> saveEntry({
    required String uid,
    required CycleEntry entry,
  });

  /// Remove a entrada de ciclo da data informada (`yyyy-MM-dd`).
  Future<void> deleteEntry({
    required String uid,
    required DateTime date,
  });

  /// Observa consultas, exames e procedimentos agendados em `users/{uid}/appointments`.
  Stream<List<CalendarExternalAppointment>> watchAppointments({
    required String uid,
  });
}

