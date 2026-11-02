import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/body_map/domain/models/body_heatmap_summary.dart';
import 'package:endocare/features/home/presentation/providers/home_providers.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/symptoms/presentation/providers/symptom_providers.dart';

/// Stream dos registros históricos de sintomas filtrados pelo período do Heatmap.
final bodyMapHistoryLogsProvider = StreamProvider.autoDispose
    .family<List<SymptomLog>, BodyHeatmapPeriod>((ref, period) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value ??
      ref.read(authRepositoryProvider).currentUser;
  if (authUser == null) {
    return Stream<List<SymptomLog>>.value(const []);
  }

  final now = ref.watch(homeClockProvider)();
  final sinceDate = period.startDateFrom(now);

  return ref.watch(symptomLogRepositoryProvider).watchLogs(
        uid: authUser.uid,
        sinceDate: sinceDate,
      );
});

/// Provider que entrega o `BodyHeatmapSummary` agregado em tempo real para o período.
final bodyHeatmapSummaryProvider = Provider.autoDispose
    .family<AsyncValue<BodyHeatmapSummary>, BodyHeatmapPeriod>((ref, period) {
  final logsAsync = ref.watch(bodyMapHistoryLogsProvider(period));
  return logsAsync.whenData(
    (logs) => BodyHeatmapSummary.aggregate(period: period, logs: logs),
  );
});

