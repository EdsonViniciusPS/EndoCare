import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';

/// Contrato de persistência para consultas, exames e procedimentos
/// (`users/{uid}/appointments/{id}`).
abstract class AppointmentRepository {
  /// Observa em tempo real os agendamentos e procedimentos da usuária.
  Stream<List<MedicalAppointment>> watchAppointments({required String uid});

  /// Cria ou atualiza uma consulta, exame ou procedimento.
  Future<MedicalAppointment> saveAppointment({
    required String uid,
    required MedicalAppointment appointment,
  });

  /// Remove um agendamento ou procedimento.
  Future<void> deleteAppointment({
    required String uid,
    required String appointmentId,
  });
}

