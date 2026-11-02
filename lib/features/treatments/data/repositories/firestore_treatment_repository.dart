import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';
import 'package:endocare/features/treatments/domain/models/treatment_effect.dart';
import 'package:endocare/features/treatments/domain/repositories/treatment_repository.dart';

/// Implementação Cloud Firestore de `TreatmentRepository`.
class FirestoreTreatmentRepository implements TreatmentRepository {
  const FirestoreTreatmentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _treatmentsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('treatments');
  }

  CollectionReference<Map<String, dynamic>> _effectsRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('treatmentEffects');
  }

  @override
  Stream<List<Treatment>> watchTreatments({required String uid}) {
    return _treatmentsRef(uid)
        .orderBy('inicio', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(Treatment.fromFirestoreDoc)
              .toList(growable: false),
        );
  }

  @override
  Future<Treatment> saveTreatment({
    required String uid,
    required Treatment treatment,
  }) async {
    final col = _treatmentsRef(uid);
    final docRef = treatment.id.trim().isEmpty
        ? col.doc()
        : col.doc(treatment.id.trim());
    final saved = treatment.copyWith(id: docRef.id);
    await docRef.set(saved.toFirestoreMap());
    return saved;
  }

  @override
  Future<void> deleteTreatment({
    required String uid,
    required String treatmentId,
  }) async {
    await _treatmentsRef(uid).doc(treatmentId).delete();
  }

  @override
  Stream<List<TreatmentEffect>> watchEffects({required String uid}) {
    return _effectsRef(uid)
        .orderBy('data', descending: true)
        .limit(120)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(TreatmentEffect.fromFirestoreDoc)
              .toList(growable: false),
        );
  }

  @override
  Future<TreatmentEffect> saveEffect({
    required String uid,
    required TreatmentEffect effect,
  }) async {
    final col = _effectsRef(uid);
    final docRef =
        effect.id.trim().isEmpty ? col.doc() : col.doc(effect.id.trim());
    final persisted = TreatmentEffect(
      id: docRef.id,
      treatmentId: effect.treatmentId,
      treatmentName: effect.treatmentName,
      data: effect.data,
      efeito: effect.efeito,
      tipo: effect.tipo,
      intensidade: effect.intensidade,
      notas: effect.notas,
    );
    await docRef.set(persisted.toFirestoreMap());
    return persisted;
  }

  @override
  Future<void> deleteEffect({
    required String uid,
    required String effectId,
  }) async {
    await _effectsRef(uid).doc(effectId).delete();
  }
}

