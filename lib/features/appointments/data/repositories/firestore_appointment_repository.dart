import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/appointments/domain/repositories/appointment_repository.dart';

/// Implementação Cloud Firestore de `AppointmentRepository`.
class FirestoreAppointmentRepository implements AppointmentRepository {
  const FirestoreAppointmentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _appointmentsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('appointments');
  }

  @override
  Stream<List<MedicalAppointment>> watchAppointments({required String uid}) {
    return _appointmentsRef(uid)
        .orderBy('data', descending: false)
        .limit(200)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(MedicalAppointment.fromFirestoreDoc)
              .toList(growable: false),
        );
  }

  @override
  Future<MedicalAppointment> saveAppointment({
    required String uid,
    required MedicalAppointment appointment,
  }) async {
    final col = _appointmentsRef(uid);
    final docRef = appointment.id.trim().isEmpty
        ? col.doc()
        : col.doc(appointment.id.trim());
    final saved = appointment.copyWith(id: docRef.id);
    await docRef.set(saved.toFirestoreMap());
    return saved;
  }

  @override
  Future<void> deleteAppointment({
    required String uid,
    required String appointmentId,
  }) async {
    await _appointmentsRef(uid).doc(appointmentId).delete();
  }
}

