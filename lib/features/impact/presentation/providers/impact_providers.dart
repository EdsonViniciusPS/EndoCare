import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/firebase/firebase_providers.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/impact/data/repositories/firestore_impact_log_repository.dart';
import 'package:endocare/features/impact/domain/models/impact_log.dart';
import 'package:endocare/features/impact/domain/repositories/impact_log_repository.dart';

/// Provider do repositório do Diário de impacto (sobregravável em testes).
final impactLogRepositoryProvider = Provider<ImpactLogRepository>((ref) {
  return FirestoreImpactLogRepository(ref.watch(firestoreProvider));
});

/// Stream em tempo real dos registros de impacto da usuária autenticada.
final impactLogsStreamProvider = StreamProvider<List<ImpactLog>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream<List<ImpactLog>>.value(const []);
  }
  return ref.watch(impactLogRepositoryProvider).watchLogs(uid: authUser.uid);
});

