import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/calendar/domain/models/calendar_day_digest.dart';
import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';
import 'package:endocare/features/calendar/domain/repositories/cycle_repository.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Implementação Cloud Firestore de `CycleRepository`.
class FirestoreCycleRepository implements CycleRepository {
  const FirestoreCycleRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entriesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('cycleEntries');
  }

  CollectionReference<Map<String, dynamic>> _appointmentsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('appointments');
  }

  @override
  Stream<List<CycleEntry>> watchEntries({
    required String uid,
    DateTime? sinceDate,
  }) {
    Query<Map<String, dynamic>> query =
        _entriesRef(uid).orderBy('data', descending: true);
    if (sinceDate != null) {
      query = query.where(
        'data',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          SymptomLog.normalizeDate(sinceDate),
        ),
      );
    } else {
      query = query.limit(400);
    }

    return query.snapshots().map(
          (snap) => snap.docs
              .map(CycleEntry.fromFirestoreDoc)
              .toList(growable: false),
        );
  }

  @override
  Future<CycleEntry?> getEntryForDate({
    required String uid,
    required DateTime date,
  }) async {
    final doc = await _entriesRef(uid).doc(SymptomLog.dateKeyFor(date)).get();
    if (!doc.exists || doc.data() == null) return null;
    return CycleEntry.fromFirestoreDoc(doc);
  }

  @override
  Future<void> saveEntry({
    required String uid,
    required CycleEntry entry,
  }) async {
    final docRef = _entriesRef(uid).doc(SymptomLog.dateKeyFor(entry.data));
    if (entry.isEmpty) {
      await docRef.delete();
      return;
    }
    await docRef.set(entry.toFirestoreMap());
  }

  @override
  Future<void> deleteEntry({
    required String uid,
    required DateTime date,
  }) async {
    await _entriesRef(uid).doc(SymptomLog.dateKeyFor(date)).delete();
  }

  @override
  Stream<List<CalendarExternalAppointment>> watchAppointments({
    required String uid,
  }) {
    return _appointmentsRef(uid)
        .orderBy('data', descending: false)
        .limit(200)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final map = doc.data();
        final rawDate = map['data'];
        final date = rawDate is Timestamp
            ? SymptomLog.normalizeDate(rawDate.toDate())
            : SymptomLog.normalizeDate(DateTime.now());
        final rawTipo = (map['tipo'] as String?)?.trim() ?? 'consulta';
        final rawTitulo = (map['titulo'] as String?)?.trim();
        final rawLocal = (map['local'] as String?)?.trim();

        final labelTipo = switch (rawTipo) {
          'exame' => 'Exame',
          'procedimento' => 'Procedimento',
          _ => 'Consulta',
        };
        final title = (rawTitulo != null && rawTitulo.isNotEmpty)
            ? rawTitulo
            : (rawLocal != null && rawLocal.isNotEmpty
                ? '$labelTipo • $rawLocal'
                : labelTipo);

        return CalendarExternalAppointment(
          id: doc.id,
          date: date,
          title: title,
          location: rawLocal,
        );
      }).toList(growable: false);
    });
  }
}

