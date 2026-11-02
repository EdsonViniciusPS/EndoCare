import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/symptoms/domain/repositories/symptom_log_repository.dart';

/// Implementação Cloud Firestore para `users/{uid}/symptomLogs/{yyyy-MM-dd}`.
class FirestoreSymptomLogRepository implements SymptomLogRepository {
  FirestoreSymptomLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('symptomLogs');
  }

  @override
  Stream<SymptomLog?> watchLogForDate({
    required String uid,
    required DateTime date,
  }) {
    final key = SymptomLog.dateKeyFor(date);
    return _logsCollection(uid).doc(key).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return SymptomLog.fromFirestore(data, id: snapshot.id);
    });
  }

  @override
  Stream<List<SymptomLog>> watchLogs({
    required String uid,
    DateTime? sinceDate,
  }) {
    Query<Map<String, dynamic>> query = _logsCollection(uid);
    if (sinceDate != null) {
      final normalizedSince = SymptomLog.normalizeDate(sinceDate);
      query = query.where(
        'data',
        isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedSince),
      );
    }
    query = query.orderBy('data', descending: true).limit(365);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SymptomLog.fromFirestore(doc.data(), id: doc.id))
          .toList(growable: false);
    });
  }

  @override
  Future<SymptomLog?> getLogForDate({
    required String uid,
    required DateTime date,
  }) async {
    final key = SymptomLog.dateKeyFor(date);
    final snapshot = await _logsCollection(uid).doc(key).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return SymptomLog.fromFirestore(data, id: snapshot.id);
  }

  @override
  Future<SymptomLog?> getPreviousLogBefore({
    required String uid,
    required DateTime date,
  }) async {
    final normalizedTarget = SymptomLog.normalizeDate(date);
    final yesterday = normalizedTarget.subtract(const Duration(days: 1));

    // 1. Tenta primeiro o acesso direto O(1) ao documento de ontem.
    final yesterdayLog = await getLogForDate(uid: uid, date: yesterday);
    if (yesterdayLog != null) return yesterdayLog;

    // 2. Fallback: último registro anterior disponível (índice automático em `data`).
    final querySnapshot = await _logsCollection(uid)
        .where('data', isLessThan: Timestamp.fromDate(normalizedTarget))
        .orderBy('data', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    final doc = querySnapshot.docs.first;
    return SymptomLog.fromFirestore(doc.data(), id: doc.id);
  }

  @override
  Future<void> saveLog({
    required String uid,
    required SymptomLog log,
  }) async {
    final key = SymptomLog.dateKeyFor(log.data);
    await _logsCollection(uid).doc(key).set(
          log.toFirestoreMap(),
          SetOptions(merge: true),
        );
  }
}
