import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/features/body_map/domain/models/body_heatmap_summary.dart';
import 'package:endocare/features/body_map/domain/models/body_region_definition.dart';
import 'package:endocare/features/body_map/domain/models/body_region_pain_entry.dart';

/// Canvas interativo com silhueta feminina em SVG (Frente e Costas) e zonas
/// anatômicas tocáveis, usado tanto no modo de Registro quanto no Heatmap Histórico.
class BodySilhouetteCanvas extends StatelessWidget {
  const BodySilhouetteCanvas({
    super.key,
    required this.side,
    this.isHeatmapMode = false,
    this.selectedEntriesById = const {},
    this.heatmapStatsById = const {},
    this.highlightedRegionId,
    this.onRegionTap,
  });

  final BodySide side;
  final bool isHeatmapMode;
  final Map<String, BodyRegionPainEntry> selectedEntriesById;
  final Map<String, RegionHeatmapStats> heatmapStatsById;
  final String? highlightedRegionId;
  final ValueChanged<BodyRegionDefinition>? onRegionTap;

  @override
  Widget build(BuildContext context) {
    final regions = BodyMapCatalog.regionsForSide(side);
    final svgMarkup = side == BodySide.front ? _frontSvg : _backSvg;
    final leftMarker = side == BodySide.front ? 'Dir.' : 'Esq.';
    final rightMarker = side == BodySide.front ? 'Esq.' : 'Dir.';
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 265),
        child: AspectRatio(
          aspectRatio:
              BodyMapCatalog.viewBoxWidth / BodyMapCatalog.viewBoxHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scaleX =
                  constraints.maxWidth / BodyMapCatalog.viewBoxWidth;
              final scaleY =
                  constraints.maxHeight / BodyMapCatalog.viewBoxHeight;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Orientação anatômica lateral discreta
                  Positioned(
                    top: 108 * scaleY,
                    left: 4,
                    child: Text(
                      leftMarker,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 108 * scaleY,
                    right: 4,
                    child: Text(
                      rightMarker,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),

                  // Silhueta vetorial feminina (Frente ou Costas)
                  Positioned.fill(
                    child: SvgPicture.string(
                      svgMarkup,
                      fit: BoxFit.contain,
                      semanticsLabel:
                          'Silhueta corporal feminina - ${side.label}',
                    ),
                  ),

                  // Zonas anatômicas tocáveis alinhadas ao viewBox 240x500
                  for (final region in regions)
                    _buildRegionOverlay(
                      context: context,
                      region: region,
                      scaleX: scaleX,
                      scaleY: scaleY,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRegionOverlay({
    required BuildContext context,
    required BodyRegionDefinition region,
    required double scaleX,
    required double scaleY,
  }) {
    final left = (region.centerX - region.width / 2) * scaleX;
    final top = (region.centerY - region.height / 2) * scaleY;
    final width = region.width * scaleX;
    final height = region.height * scaleY;

    final entry = selectedEntriesById[region.id];
    final heatStats = heatmapStatsById[region.id];
    final isHighlighted = highlightedRegionId == region.id;

    if (isHeatmapMode) {
      final hasHeat = heatStats != null;
      final heatScore = heatStats?.heatScore ?? 0;
      final heatColor = hasHeat
          ? _heatmapColorForScore(heatScore)
          : AppColors.outline.withValues(alpha: 0.2);

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Semantics(
          button: true,
          label: hasHeat
              ? '${region.label}: ${heatStats.occurrences} dias, média ${heatStats.averageIntensity.toStringAsFixed(1)}'
              : '${region.label}: sem registros no período',
          child: GestureDetector(
            key: ValueKey('heatmap_region_${region.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: onRegionTap == null ? null : () => onRegionTap!(region),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height * 0.45),
                gradient: hasHeat
                    ? RadialGradient(
                        colors: [
                          heatColor.withValues(
                            alpha: (0.42 + heatScore * 0.42).clamp(0.4, 0.88),
                          ),
                          heatColor.withValues(alpha: 0.14),
                        ],
                      )
                    : null,
                border: Border.all(
                  color: isHighlighted
                      ? AppColors.primaryDark
                      : (hasHeat
                          ? heatColor.withValues(alpha: 0.75)
                          : AppColors.outline.withValues(alpha: 0.35)),
                  width: isHighlighted ? 2 : 1,
                ),
              ),
              child: hasHeat
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                        child: Text(
                          '${heatStats.occurrences}x',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: heatColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    // Modo Registro interativo
    final isSelected = entry != null;
    final activeColor = isSelected
        ? AppColors.forPainLevel(entry.intensidade)
        : AppColors.primary;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: isSelected
            ? '${region.label}, intensidade ${entry.intensidade} de 10'
            : 'Selecionar região ${region.label}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('body_region_${region.id}'),
            onTap: onRegionTap == null ? null : () => onRegionTap!(region),
            borderRadius: BorderRadius.circular(height * 0.45),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.32)
                    : AppColors.primaryContainer.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(height * 0.45),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : AppColors.primaryLight.withValues(alpha: 0.55),
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Center(
                child: isSelected
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                        child: Text(
                          '${entry.intensidade}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      )
                    : Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _heatmapColorForScore(double score) {
    if (score < 0.38) return AppColors.painModerate;
    if (score < 0.68) return AppColors.painStrong;
    return AppColors.painSevere;
  }

  // ---------------------------------------------------------------------------
  // Silhuetas vetoriais SVG (viewBox="0 0 240 500") — Frente e Costas
  // ---------------------------------------------------------------------------
  static const String _bodyContourPath = '''
    M 108 75
    L 108 96
    C 94 103, 66 108, 56 126
    C 45 148, 39 208, 34 266
    C 33 277, 45 280, 48 269
    C 55 218, 63 172, 74 148
    C 76 172, 82 192, 81 206
    C 79 224, 65 244, 66 274
    C 67 312, 75 362, 81 402
    C 84 432, 86 462, 88 482
    C 89 491, 105 491, 106 481
    C 108 446, 111 414, 113 386
    C 115 352, 116 318, 120 298
    C 124 318, 125 352, 127 386
    C 129 414, 132 446, 134 481
    C 135 491, 151 491, 152 482
    C 154 462, 156 432, 159 402
    C 165 362, 173 312, 174 274
    C 175 244, 161 224, 159 206
    C 158 192, 164 172, 166 148
    C 177 172, 185 218, 192 269
    C 195 280, 207 277, 206 266
    C 201 208, 195 148, 184 126
    C 174 108, 146 103, 132 96
    L 132 75
    Z
  ''';

  static const String _frontSvg = '''
<svg viewBox="0 0 240 500" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="120" cy="48" rx="23" ry="28" fill="#FDF7F9" stroke="#B57F91" stroke-width="2.2"/>
  <path d="$_bodyContourPath" fill="#FDF7F9" stroke="#B57F91" stroke-width="2.2" stroke-linejoin="round"/>
  <!-- Linhas anatômicas sutis da visão frontal -->
  <path d="M 92 114 Q 108 121 116 116 M 148 114 Q 132 121 124 116" fill="none" stroke="#DCC4CC" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M 86 154 Q 102 166 116 156 M 154 154 Q 138 166 124 156" fill="none" stroke="#E5D1D8" stroke-width="1.4" stroke-linecap="round"/>
  <circle cx="120" cy="221" r="2.2" fill="#C9A8B4"/>
  <path d="M 82 252 Q 120 296 158 252" fill="none" stroke="#E3CDD5" stroke-width="1.4" stroke-dasharray="3 3"/>
  <path d="M 88 394 Q 96 399 104 394 M 136 394 Q 144 399 152 394" fill="none" stroke="#E5D1D8" stroke-width="1.3" stroke-linecap="round"/>
</svg>
''';

  static const String _backSvg = '''
<svg viewBox="0 0 240 500" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="120" cy="48" rx="23" ry="28" fill="#FDF7F9" stroke="#B57F91" stroke-width="2.2"/>
  <path d="$_bodyContourPath" fill="#FDF7F9" stroke="#B57F91" stroke-width="2.2" stroke-linejoin="round"/>
  <!-- Linhas anatômicas sutis da visão posterior (coluna, escápulas, sacro) -->
  <line x1="120" y1="98" x2="120" y2="262" stroke="#DEC7CF" stroke-width="1.5" stroke-dasharray="4 4"/>
  <path d="M 92 124 Q 104 142 98 156 M 148 124 Q 136 142 142 156" fill="none" stroke="#E2CCD4" stroke-width="1.4" stroke-linecap="round"/>
  <polygon points="120,248 134,264 120,280 106,264" fill="none" stroke="#E2CCD4" stroke-width="1.3"/>
  <path d="M 74 288 Q 97 306 118 292 M 166 288 Q 143 306 122 292" fill="none" stroke="#DEC7CF" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';
}

