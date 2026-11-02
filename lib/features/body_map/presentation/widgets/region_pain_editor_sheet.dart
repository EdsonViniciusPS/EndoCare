import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/core/widgets/endocare_chip.dart';
import 'package:endocare/core/widgets/endocare_slider.dart';
import 'package:endocare/features/body_map/domain/models/body_region_definition.dart';
import 'package:endocare/features/body_map/domain/models/body_region_pain_entry.dart';

/// Resultado retornado pela folha de edição de uma região do Mapa Corporal.
class RegionEditorOutcome {
  const RegionEditorOutcome.saved(this.entry) : removed = false;
  const RegionEditorOutcome.removed()
      : entry = null,
        removed = true;

  final BodyRegionPainEntry? entry;
  final bool removed;
}

/// Folha modal acolhedora e rápida para configurar intensidade (1–10),
/// tipo de dor, duração e frequência de uma região anatômica.
class RegionPainEditorSheet extends StatefulWidget {
  const RegionPainEditorSheet({
    super.key,
    required this.region,
    this.existingEntry,
    this.defaultIntensity = 5,
  });

  final BodyRegionDefinition region;
  final BodyRegionPainEntry? existingEntry;
  final int defaultIntensity;

  static Future<RegionEditorOutcome?> show({
    required BuildContext context,
    required BodyRegionDefinition region,
    BodyRegionPainEntry? existingEntry,
    int defaultIntensity = 5,
  }) {
    return showModalBottomSheet<RegionEditorOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => RegionPainEditorSheet(
        region: region,
        existingEntry: existingEntry,
        defaultIntensity: defaultIntensity,
      ),
    );
  }

  @override
  State<RegionPainEditorSheet> createState() => _RegionPainEditorSheetState();
}

class _RegionPainEditorSheetState extends State<RegionPainEditorSheet> {
  late int _intensity;
  late String _painType;
  late String _duration;
  late String _frequency;

  @override
  void initState() {
    super.initState();
    final initial = widget.existingEntry ??
        BodyRegionPainEntry.defaultForRegion(
          widget.region,
          initialIntensity: widget.defaultIntensity,
        );
    _intensity = initial.intensidade;
    _painType = initial.tipoDor;
    _duration = initial.duracao;
    _frequency = initial.frequencia;
  }

  void _confirm() {
    final entry = BodyRegionPainEntry(
      regionId: widget.region.id,
      regionLabel: widget.region.label,
      side: widget.region.side,
      intensidade: _intensity,
      tipoDor: _painType,
      duracao: _duration,
      frequencia: _frequency,
    );
    Navigator.of(context).pop(RegionEditorOutcome.saved(entry));
  }

  void _remove() {
    Navigator.of(context).pop(const RegionEditorOutcome.removed());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.52,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.outlineStrong,
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                  child: Text(
                    widget.region.side.label,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.region.label,
                    style: textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 1. Intensidade (1 a 10)
            EndoCareSlider(
              label: 'Intensidade nesta região',
              value: _intensity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              minCaption: '1 • Leve',
              maxCaption: '10 • Muito intensa',
              onChanged: (next) => setState(() => _intensity = next.round()),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Tipo de dor
            Text('Tipo de dor', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: BodyMapCatalog.painTypes.map((type) {
                return EndoCareChip(
                  label: type,
                  selected: _painType == type,
                  onSelected: (_) => setState(() => _painType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Duração
            Text('Duração', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: BodyMapCatalog.durations.map((item) {
                return EndoCareChip(
                  label: item,
                  selected: _duration == item,
                  activeColor: AppColors.tertiary,
                  onSelected: (_) => setState(() => _duration = item),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Frequência
            Text('Frequência', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: BodyMapCatalog.frequencies.map((item) {
                return EndoCareChip(
                  label: item,
                  selected: _frequency == item,
                  activeColor: AppColors.info,
                  onSelected: (_) => setState(() => _frequency = item),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            EndoCareButton(
              label: widget.existingEntry != null
                  ? 'Atualizar região'
                  : 'Confirmar região',
              icon: Icons.check_rounded,
              isExpanded: true,
              onPressed: _confirm,
            ),
              if (widget.existingEntry != null) ...[
                const SizedBox(height: AppSpacing.xs),
                EndoCareButton(
                  label: 'Remover região',
                  icon: Icons.delete_outline_rounded,
                  variant: EndoCareButtonVariant.text,
                  isExpanded: true,
                  onPressed: _remove,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

