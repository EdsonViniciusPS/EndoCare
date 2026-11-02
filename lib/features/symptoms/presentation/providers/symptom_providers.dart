import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/firebase/firebase_providers.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/home/presentation/providers/home_providers.dart';
import 'package:endocare/features/symptoms/data/repositories/firestore_symptom_log_repository.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/symptoms/domain/repositories/symptom_log_repository.dart';

/// Pacote inicial carregado ao abrir o Registro Rápido para uma data.
class QuickLogInitialBundle {
  const QuickLogInitialBundle({
    required this.initialLog,
    required this.isExistingForDate,
    this.prefilledFromDate,
  });

  final SymptomLog initialLog;
  final bool isExistingForDate;
  final DateTime? prefilledFromDate;

  bool get isPrefilledFromPrevious =>
      !isExistingForDate && prefilledFromDate != null;
}

/// Provider do repositório de `symptomLogs` (sobregravável em testes).
final symptomLogRepositoryProvider = Provider<SymptomLogRepository>((ref) {
  return FirestoreSymptomLogRepository(ref.watch(firestoreProvider));
});

/// Observa em tempo real o registro de sintomas de hoje da usuária autenticada.
final todaySymptomLogProvider = StreamProvider<SymptomLog?>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream<SymptomLog?>.value(null);
  }
  final today = SymptomLog.normalizeDate(ref.watch(homeClockProvider)());
  return ref
      .watch(symptomLogRepositoryProvider)
      .watchLogForDate(uid: authUser.uid, date: today);
});

/// Carrega o registro salvo da data `normalizedDate` ou pré-preenche com os
/// valores padrão do dia anterior quando o dia ainda está em branco.
final quickLogInitialBundleProvider = FutureProvider.autoDispose
    .family<QuickLogInitialBundle, DateTime>((ref, normalizedDate) async {
  final authUser = ref.watch(authStateChangesProvider).asData?.value ??
      ref.read(authRepositoryProvider).currentUser;
  final target = SymptomLog.normalizeDate(normalizedDate);

  if (authUser == null) {
    return QuickLogInitialBundle(
      initialLog: SymptomLog.emptyForDate(target),
      isExistingForDate: false,
    );
  }

  final repo = ref.watch(symptomLogRepositoryProvider);
  final existing = await repo.getLogForDate(uid: authUser.uid, date: target);
  if (existing != null) {
    return QuickLogInitialBundle(
      initialLog: existing,
      isExistingForDate: true,
    );
  }

  final previous = await repo.getPreviousLogBefore(
    uid: authUser.uid,
    date: target,
  );
  if (previous != null) {
    return QuickLogInitialBundle(
      initialLog: SymptomLog.prefilledFromPrevious(
        targetDate: target,
        previous: previous,
      ),
      isExistingForDate: false,
      prefilledFromDate: previous.data,
    );
  }

  return QuickLogInitialBundle(
    initialLog: SymptomLog.emptyForDate(target),
    isExistingForDate: false,
  );
});

