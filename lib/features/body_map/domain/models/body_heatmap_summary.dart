import 'package:endocare/features/body_map/domain/models/body_region_definition.dart';
import 'package:endocare/features/body_map/domain/models/body_region_pain_entry.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Períodos selecionáveis para o Heatmap Histórico do Mapa Corporal.
enum BodyHeatmapPeriod {
  days7(7, '7 dias'),
  days30(30, '30 dias'),
  days90(90, '90 dias'),
  all(null, 'Tudo');

  const BodyHeatmapPeriod(this.days, this.label);

  final int? days;
  final String label;

  DateTime? startDateFrom(DateTime referenceDate) {
    if (days == null) return null;
    final normalized = SymptomLog.normalizeDate(referenceDate);
    return normalized.subtract(Duration(days: days! - 1));
  }
}

/// Estatística histórica agregada de uma região anatômica.
class RegionHeatmapStats {
  const RegionHeatmapStats({
    required this.region,
    required this.occurrences,
    required this.totalDaysWithBodyMap,
    required this.averageIntensity,
    required this.maxIntensity,
    required this.predominantPainType,
    required this.predominantDuration,
    required this.predominantFrequency,
  });

  final BodyRegionDefinition region;
  final int occurrences;
  final int totalDaysWithBodyMap;
  final double averageIntensity;
  final int maxIntensity;
  final String predominantPainType;
  final String predominantDuration;
  final String predominantFrequency;

  /// Proporção de presença da região entre os dias mapeados (0.0 a 1.0).
  double get occurrenceRatio {
    if (totalDaysWithBodyMap <= 0) return 0;
    return (occurrences / totalDaysWithBodyMap).clamp(0.0, 1.0);
  }

  /// Índice térmico combinado (0.15 a 1.0) ponderando frequência e intensidade média.
  double get heatScore {
    final intensityNorm = (averageIntensity / 10.0).clamp(0.0, 1.0);
    final combined = (occurrenceRatio * 0.55) + (intensityNorm * 0.45);
    return combined.clamp(0.15, 1.0);
  }
}

/// Resultado consolidado do Heatmap Histórico ao longo do período escolhido.
class BodyHeatmapSummary {
  const BodyHeatmapSummary({
    required this.period,
    required this.totalMappedDays,
    required this.statsByRegionId,
    required this.rankedRegions,
  });

  final BodyHeatmapPeriod period;
  final int totalMappedDays;
  final Map<String, RegionHeatmapStats> statsByRegionId;
  final List<RegionHeatmapStats> rankedRegions;

  bool get isEmpty => rankedRegions.isEmpty;

  int countForSide(BodySide side) {
    return rankedRegions.where((s) => s.region.side == side).length;
  }

  /// Agrega uma lista de `SymptomLog` do período em estatísticas por região.
  factory BodyHeatmapSummary.aggregate({
    required BodyHeatmapPeriod period,
    required List<SymptomLog> logs,
  }) {
    final entriesByRegion = <String, List<BodyRegionPainEntry>>{};
    var mappedDays = 0;

    for (final log in logs) {
      if (log.mapaCorporal.isEmpty) continue;
      mappedDays++;
      for (final entry in log.mapaCorporal) {
        if (BodyMapCatalog.findById(entry.regionId) == null) continue;
        entriesByRegion
            .putIfAbsent(entry.regionId, () => <BodyRegionPainEntry>[])
            .add(entry);
      }
    }

    final statsById = <String, RegionHeatmapStats>{};
    for (final mapEntry in entriesByRegion.entries) {
      final region = BodyMapCatalog.findById(mapEntry.key);
      if (region == null) continue;
      final list = mapEntry.value;

      var sumIntensity = 0;
      var peak = 0;
      final typeCounts = <String, int>{};
      final durationCounts = <String, int>{};
      final frequencyCounts = <String, int>{};

      for (final item in list) {
        sumIntensity += item.intensidade;
        if (item.intensidade > peak) peak = item.intensidade;
        typeCounts[item.tipoDor] = (typeCounts[item.tipoDor] ?? 0) + 1;
        durationCounts[item.duracao] = (durationCounts[item.duracao] ?? 0) + 1;
        frequencyCounts[item.frequencia] =
            (frequencyCounts[item.frequencia] ?? 0) + 1;
      }

      statsById[region.id] = RegionHeatmapStats(
        region: region,
        occurrences: list.length,
        totalDaysWithBodyMap: mappedDays,
        averageIntensity: sumIntensity / list.length,
        maxIntensity: peak,
        predominantPainType: _mostFrequentKey(
          typeCounts,
          fallback: BodyMapCatalog.painTypes.first,
        ),
        predominantDuration: _mostFrequentKey(
          durationCounts,
          fallback: BodyMapCatalog.durations[1],
        ),
        predominantFrequency: _mostFrequentKey(
          frequencyCounts,
          fallback: BodyMapCatalog.frequencies[1],
        ),
      );
    }

    final ranked = statsById.values.toList()
      ..sort((a, b) {
        final byOccurrences = b.occurrences.compareTo(a.occurrences);
        if (byOccurrences != 0) return byOccurrences;
        return b.averageIntensity.compareTo(a.averageIntensity);
      });

    return BodyHeatmapSummary(
      period: period,
      totalMappedDays: mappedDays,
      statsByRegionId: statsById,
      rankedRegions: ranked,
    );
  }

  static String _mostFrequentKey(
    Map<String, int> counts, {
    required String fallback,
  }) {
    if (counts.isEmpty) return fallback;
    var bestKey = fallback;
    var bestCount = -1;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        bestKey = entry.key;
      }
    }
    return bestKey;
  }
}

