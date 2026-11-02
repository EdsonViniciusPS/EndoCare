/// Lado anatômico da silhueta corporal.
enum BodySide {
  front('frente', 'Frente'),
  back('costas', 'Costas');

  const BodySide(this.code, this.label);

  final String code;
  final String label;

  static BodySide fromCode(String? raw) {
    if (raw == back.code) return BodySide.back;
    return BodySide.front;
  }
}

/// Definição geométrica e clínica de uma região tocável na silhueta `240x500`.
class BodyRegionDefinition {
  const BodyRegionDefinition({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.side,
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
  });

  final String id;
  final String label;
  final String shortLabel;
  final BodySide side;

  /// Coordenadas no sistema `viewBox="0 0 240 500"` da silhueta SVG.
  final double centerX;
  final double centerY;
  final double width;
  final double height;
}

/// Catálogo anatômico e opções padronizadas do Mapa Corporal do EndoCare.
abstract final class BodyMapCatalog {
  static const double viewBoxWidth = 240;
  static const double viewBoxHeight = 500;

  /// Tipos de dor selecionáveis por região.
  static const List<String> painTypes = [
    'Cólica',
    'Pontada / Fisgada',
    'Queimação',
    'Pressão / Peso',
    'Latejante',
    'Irradiada',
  ];

  /// Durações selecionáveis por região.
  static const List<String> durations = [
    'Minutos',
    'Algumas horas',
    'Metade do dia',
    'Dia todo',
    'Contínua (vários dias)',
  ];

  /// Frequências selecionáveis por região.
  static const List<String> frequencies = [
    'Pontual',
    'Intermitente (vai e volta)',
    'Frequente',
    'Constante',
  ];

  /// Regiões anatômicas da visão frontal (10 zonas).
  static const List<BodyRegionDefinition> frontRegions = [
    BodyRegionDefinition(
      id: 'peito_diafragma',
      label: 'Tórax / Diafragma',
      shortLabel: 'Diafragma',
      side: BodySide.front,
      centerX: 120,
      centerY: 145,
      width: 78,
      height: 36,
    ),
    BodyRegionDefinition(
      id: 'abdomen_superior',
      label: 'Abdômen superior',
      shortLabel: 'Abd. sup.',
      side: BodySide.front,
      centerX: 120,
      centerY: 186,
      width: 72,
      height: 32,
    ),
    BodyRegionDefinition(
      id: 'abdomen_central',
      label: 'Região umbilical',
      shortLabel: 'Umbigo',
      side: BodySide.front,
      centerX: 120,
      centerY: 220,
      width: 66,
      height: 28,
    ),
    BodyRegionDefinition(
      id: 'pelve_direita',
      label: 'Ovário / Pelve direita',
      shortLabel: 'Pelve dir.',
      side: BodySide.front,
      centerX: 88,
      centerY: 256,
      width: 31,
      height: 34,
    ),
    BodyRegionDefinition(
      id: 'pelve_central',
      label: 'Pelve central / Útero',
      shortLabel: 'Pelve',
      side: BodySide.front,
      centerX: 120,
      centerY: 258,
      width: 30,
      height: 34,
    ),
    BodyRegionDefinition(
      id: 'pelve_esquerda',
      label: 'Ovário / Pelve esquerda',
      shortLabel: 'Pelve esq.',
      side: BodySide.front,
      centerX: 152,
      centerY: 256,
      width: 31,
      height: 34,
    ),
    BodyRegionDefinition(
      id: 'assoalho_pelvico',
      label: 'Assoalho pélvico / Períneo',
      shortLabel: 'Períneo',
      side: BodySide.front,
      centerX: 120,
      centerY: 292,
      width: 44,
      height: 26,
    ),
    BodyRegionDefinition(
      id: 'coxa_frontal_direita',
      label: 'Virilha e coxa direita',
      shortLabel: 'Coxa dir.',
      side: BodySide.front,
      centerX: 93,
      centerY: 345,
      width: 38,
      height: 62,
    ),
    BodyRegionDefinition(
      id: 'coxa_frontal_esquerda',
      label: 'Virilha e coxa esquerda',
      shortLabel: 'Coxa esq.',
      side: BodySide.front,
      centerX: 147,
      centerY: 345,
      width: 38,
      height: 62,
    ),
    BodyRegionDefinition(
      id: 'pernas_frontal',
      label: 'Pernas (irradiação anterior)',
      shortLabel: 'Pernas',
      side: BodySide.front,
      centerX: 120,
      centerY: 425,
      width: 84,
      height: 64,
    ),
  ];

  /// Regiões anatômicas da visão posterior / costas (8 zonas).
  static const List<BodyRegionDefinition> backRegions = [
    BodyRegionDefinition(
      id: 'ombros_escapulas',
      label: 'Ombros / Escápulas',
      shortLabel: 'Ombros',
      side: BodySide.back,
      centerX: 120,
      centerY: 124,
      width: 96,
      height: 34,
    ),
    BodyRegionDefinition(
      id: 'costas_toracica',
      label: 'Meio das costas (torácica)',
      shortLabel: 'Torácica',
      side: BodySide.back,
      centerX: 120,
      centerY: 170,
      width: 74,
      height: 40,
    ),
    BodyRegionDefinition(
      id: 'flanco_esquerdo',
      label: 'Flanco esquerdo',
      shortLabel: 'Flanco esq.',
      side: BodySide.back,
      centerX: 88,
      centerY: 218,
      width: 31,
      height: 38,
    ),
    BodyRegionDefinition(
      id: 'lombar_central',
      label: 'Lombar central',
      shortLabel: 'Lombar',
      side: BodySide.back,
      centerX: 120,
      centerY: 220,
      width: 30,
      height: 40,
    ),
    BodyRegionDefinition(
      id: 'flanco_direito',
      label: 'Flanco direito',
      shortLabel: 'Flanco dir.',
      side: BodySide.back,
      centerX: 152,
      centerY: 218,
      width: 31,
      height: 38,
    ),
    BodyRegionDefinition(
      id: 'sacro_coccix',
      label: 'Sacro / Cóccix',
      shortLabel: 'Sacro',
      side: BodySide.back,
      centerX: 120,
      centerY: 266,
      width: 54,
      height: 34,
    ),
    BodyRegionDefinition(
      id: 'ciatico_esquerdo',
      label: 'Glúteo e ciático esquerdo',
      shortLabel: 'Ciático esq.',
      side: BodySide.back,
      centerX: 93,
      centerY: 334,
      width: 42,
      height: 76,
    ),
    BodyRegionDefinition(
      id: 'ciatico_direito',
      label: 'Glúteo e ciático direito',
      shortLabel: 'Ciático dir.',
      side: BodySide.back,
      centerX: 147,
      centerY: 334,
      width: 42,
      height: 76,
    ),
  ];

  static List<BodyRegionDefinition> regionsForSide(BodySide side) {
    return side == BodySide.front ? frontRegions : backRegions;
  }

  static final List<BodyRegionDefinition> allRegions = [
    ...frontRegions,
    ...backRegions,
  ];

  static BodyRegionDefinition? findById(String id) {
    for (final region in allRegions) {
      if (region.id == id) return region;
    }
    return null;
  }
}
