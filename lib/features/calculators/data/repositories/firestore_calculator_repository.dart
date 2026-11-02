import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/calculators/domain/models/calculator_result.dart';
import 'package:endocare/features/calculators/domain/repositories/calculator_repository.dart';

/// Implementação do repositório de calculadoras clínicas usando o Cloud Firestore.
///
/// Coleção: `users/{uid}/calculatorResults/{id}`
class FirestoreCalculatorRepository implements CalculatorRepository {
  const FirestoreCalculatorRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('calculatorResults');
  }

  @override
  Stream<List<CalculatorResult>> watchResults({required String uid}) {
    return _collection(uid)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CalculatorResult.fromFirestore(doc.data(), id: doc.id))
          .toList(growable: false);
    });
  }

  @override
  Future<List<CalculatorResult>> getResultsForCalculator({
    required String uid,
    required String calculatorId,
  }) async {
    final snapshot = await _collection(uid)
        .where('calculadora', isEqualTo: calculatorId)
        .orderBy('data', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CalculatorResult.fromFirestore(doc.data(), id: doc.id))
        .toList(growable: false);
  }

  @override
  Future<CalculatorResult?> getLatestResult({
    required String uid,
    required String calculatorId,
  }) async {
    final snapshot = await _collection(uid)
        .where('calculadora', isEqualTo: calculatorId)
        .orderBy('data', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final first = snapshot.docs.first;
    return CalculatorResult.fromFirestore(first.data(), id: first.id);
  }

  @override
  Future<void> saveResult({
    required String uid,
    required CalculatorResult result,
  }) async {
    final ref = result.id.isNotEmpty
        ? _collection(uid).doc(result.id)
        : _collection(uid).doc();

    await ref.set(result.toFirestoreMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteResult({
    required String uid,
    required String resultId,
  }) async {
    await _collection(uid).doc(resultId).delete();
  }
}

