import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/impact/domain/models/impact_log.dart';
import 'package:endocare/features/impact/domain/repositories/impact_log_repository.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Implementação Cloud Firestore de `users/{uid}/impactLogs/{yyyy-MM-dd}`.
class FirestoreImpactLogRepository implements ImpactLogRepository {
  const FirestoreImpactLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('impactLogs');
  }

  @override
  Stream<List<ImpactLog>> watchLogs({required String uid}) {
    return _logsRef(uid)
        .orderBy('data', descending: true)
        .limit(365)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ImpactLog.fromFirestore(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Future<ImpactLog?> getLogForDate({
    required String uid,
    required DateTime date,
  }) async {
    final snapshot =
        await _logsRef(uid).doc(SymptomLog.dateKeyFor(date)).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ImpactLog.fromFirestore(data, id: snapshot.id);
  }

  @override
  Future<void> saveLog({
    required String uid,
    required ImpactLog log,
  }) async {
    await _logsRef(uid)
        .doc(SymptomLog.dateKeyFor(log.data))
        .set(log.toFirestoreMap());
  }

  @override
  Future<void> deleteLog({
    required String uid,
    required DateTime date,
  }) async {
    await _logsRef(uid).doc(SymptomLog.dateKeyFor(date)).delete();
  }
}

