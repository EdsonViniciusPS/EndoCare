import 'package:endocare/features/body_map/domain/models/body_region_definition.dart';

/// Registro anatômico detalhado de dor em uma região do Mapa Corporal.
class BodyRegionPainEntry {
  const BodyRegionPainEntry({
    required this.regionId,
    required this.regionLabel,
    required this.side,
    required this.intensidade,
    required this.tipoDor,
    required this.duracao,
    required this.frequencia,
  });

  final String regionId;
  final String regionLabel;
  final BodySide side;
  final int intensidade;
  final String tipoDor;
  final String duracao;
  final String frequencia;

  BodyRegionPainEntry copyWith({
    int? intensidade,
    String? tipoDor,
    String? duracao,
    String? frequencia,
  }) {
    return BodyRegionPainEntry(
      regionId: regionId,
      regionLabel: regionLabel,
      side: side,
      intensidade: (intensidade ?? this.intensidade).clamp(1, 10),
      tipoDor: tipoDor ?? this.tipoDor,
      duracao: duracao ?? this.duracao,
      frequencia: frequencia ?? this.frequencia,
    );
  }

  factory BodyRegionPainEntry.defaultForRegion(
    BodyRegionDefinition region, {
    int initialIntensity = 5,
  }) {
    return BodyRegionPainEntry(
      regionId: region.id,
      regionLabel: region.label,
      side: region.side,
      intensidade: initialIntensity.clamp(1, 10),
      tipoDor: BodyMapCatalog.painTypes.first,
      duracao: BodyMapCatalog.durations[1],
      frequencia: BodyMapCatalog.frequencies[1],
    );
  }

  factory BodyRegionPainEntry.fromMap(Map<String, dynamic> map) {
    final id = (map['regionId'] as String?)?.trim() ?? '';
    final definition = BodyMapCatalog.findById(id);

    return BodyRegionPainEntry(
      regionId: id,
      regionLabel: (map['regionLabel'] as String?)?.trim().isNotEmpty == true
          ? (map['regionLabel'] as String).trim()
          : (definition?.label ?? id),
      side: definition?.side ?? BodySide.fromCode(map['side'] as String?),
      intensidade: ((map['intensidade'] as num?)?.round() ?? 5).clamp(1, 10),
      tipoDor: (map['tipoDor'] as String?)?.trim().isNotEmpty == true
          ? (map['tipoDor'] as String).trim()
          : BodyMapCatalog.painTypes.first,
      duracao: (map['duracao'] as String?)?.trim().isNotEmpty == true
          ? (map['duracao'] as String).trim()
          : BodyMapCatalog.durations[1],
      frequencia: (map['frequencia'] as String?)?.trim().isNotEmpty == true
          ? (map['frequencia'] as String).trim()
          : BodyMapCatalog.frequencies[1],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'regionId': regionId,
      'regionLabel': regionLabel,
      'side': side.code,
      'intensidade': intensidade.clamp(1, 10),
      'tipoDor': tipoDor,
      'duracao': duracao,
      'frequencia': frequencia,
    };
  }
}

