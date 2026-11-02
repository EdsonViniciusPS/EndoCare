import 'package:endocare/features/treatments/domain/models/treatment.dart';
import 'package:endocare/features/treatments/domain/models/treatment_effect.dart';

/// Contrato de persistência para medicamentos/tratamentos (`users/{uid}/treatments`)
/// e efeitos percebidos (`users/{uid}/treatmentEffects`).
abstract class TreatmentRepository {
  /// Observa em tempo real todos os tratamentos (ativos e histórico) da usuária.
  Stream<List<Treatment>> watchTreatments({required String uid});

  /// Cria ou atualiza um tratamento e retorna a instância persistida (com `id`).
  Future<Treatment> saveTreatment({
    required String uid,
    required Treatment treatment,
  });

  /// Remove um tratamento de `users/{uid}/treatments/{treatmentId}`.
  Future<void> deleteTreatment({
    required String uid,
    required String treatmentId,
  });

  /// Observa em tempo real os efeitos percebidos registrados pela usuária.
  Stream<List<TreatmentEffect>> watchEffects({required String uid});

  /// Salva um novo efeito percebido de tratamento.
  Future<TreatmentEffect> saveEffect({
    required String uid,
    required TreatmentEffect effect,
  });

  /// Remove um efeito percebido registrado.
  Future<void> deleteEffect({
    required String uid,
    required String effectId,
  });
}

