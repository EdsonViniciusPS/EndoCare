import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_card.dart';
import 'package:endocare/core/widgets/endocare_chip.dart';
import 'package:endocare/core/widgets/endocare_slider.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_catalog.dart';

/// Card recolhível de detalhes opcionais do registro diário:
/// cólicas e regiões, dor em relação sexual (local e escala), sintomas
/// intestinais e urinários, escalas de fadiga/náusea/inchaço e notas.
class OptionalSymptomDetailsCard extends StatefulWidget {
  const OptionalSymptomDetailsCard({
    super.key,
    required this.filledCount,
    required this.crampsScore,
    required this.onCrampsChanged,
    required this.selectedRegions,
    required this.onToggleRegion,
    required this.hasSexualPain,
    required this.onSexualPainToggled,
    required this.sexualPainLocation,
    required this.onSexualPainLocationSelected,
    required this.sexualPainScale,
    required this.onSexualPainScaleChanged,
    required this.selectedIntestinal,
    required this.onToggleIntestinal,
    required this.selectedUrinary,
    required this.onToggleUrinary,
    required this.fatigueScore,
    required this.onFatigueChanged,
    required this.nauseaScore,
    required this.onNauseaChanged,
    required this.bloatingScore,
    required this.onBloatingChanged,
    required this.notesController,
  });

  final int filledCount;

  final int? crampsScore;
  final ValueChanged<int?> onCrampsChanged;
  final Set<String> selectedRegions;
  final ValueChanged<String> onToggleRegion;

  final bool hasSexualPain;
  final ValueChanged<bool> onSexualPainToggled;
  final String sexualPainLocation;
  final ValueChanged<String> onSexualPainLocationSelected;
  final int sexualPainScale;
  final ValueChanged<int> onSexualPainScaleChanged;

  final Set<String> selectedIntestinal;
  final ValueChanged<String> onToggleIntestinal;
  final Set<String> selectedUrinary;
  final ValueChanged<String> onToggleUrinary;

  final int? fatigueScore;
  final ValueChanged<int?> onFatigueChanged;
  final int? nauseaScore;
  final ValueChanged<int?> onNauseaChanged;
  final int? bloatingScore;
  final ValueChanged<int?> onBloatingChanged;

  final TextEditingController notesController;

  @override
  State<OptionalSymptomDetailsCard> createState() =>
      _OptionalSymptomDetailsCardState();
}

class _OptionalSymptomDetailsCardState
    extends State<OptionalSymptomDetailsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return EndoCareCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppSpacing.borderRadiusLg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Detalhes opcionais',
                                style: textTheme.titleMedium,
                              ),
                            ),
                            if (widget.filledCount > 0) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs + 2,
                                  vertical: 2,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: AppSpacing.borderRadiusPill,
                                ),
                                child: Text(
                                  '${widget.filledCount}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cólicas, relação sexual, intestino, urinário, fadiga, náusea e inchaço',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Cólicas e dores pélvicas + regiões
                  _OptionalScoreSection(
                    title: 'Cólicas e dor pélvica',
                    value: widget.crampsScore,
                    onChanged: widget.onCrampsChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Onde dói mais hoje?',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: SymptomCatalog.quickRegions.map((region) {
                      return EndoCareChip(
                        label: region,
                        selected: widget.selectedRegions.contains(region),
                        onSelected: (_) => widget.onToggleRegion(region),
                      );
                    }).toList(),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),

                  // 2. Dor durante relações sexuais (local e escala)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppColors.primary,
                    title: Text(
                      'Dor durante ou após relação sexual',
                      style: textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      'Registre local e intensidade se houve desconforto',
                      style: textTheme.bodySmall,
                    ),
                    value: widget.hasSexualPain,
                    onChanged: widget.onSexualPainToggled,
                  ),
                  if (widget.hasSexualPain) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Local da dor',
                      style: textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children:
                          SymptomCatalog.sexualPainLocations.map((location) {
                        return EndoCareChip(
                          label: location,
                          selected: widget.sexualPainLocation == location,
                          onSelected: (_) =>
                              widget.onSexualPainLocationSelected(location),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EndoCareSlider(
                      label: 'Intensidade na relação (0–10)',
                      value: widget.sexualPainScale.toDouble(),
                      onChanged: (val) =>
                          widget.onSexualPainScaleChanged(val.round()),
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),

                  // 3. Sintomas intestinais e urinários
                  Text(
                    'Sintomas intestinais',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: SymptomCatalog.intestinalSymptoms.map((item) {
                      return EndoCareChip(
                        label: item,
                        selected: widget.selectedIntestinal.contains(item),
                        activeColor: AppColors.tertiary,
                        onSelected: (_) => widget.onToggleIntestinal(item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sintomas urinários',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: SymptomCatalog.urinarySymptoms.map((item) {
                      return EndoCareChip(
                        label: item,
                        selected: widget.selectedUrinary.contains(item),
                        activeColor: AppColors.info,
                        onSelected: (_) => widget.onToggleUrinary(item),
                      );
                    }).toList(),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),

                  // 4. Fadiga, náusea e inchaço (0–10)
                  _OptionalScoreSection(
                    title: 'Fadiga',
                    value: widget.fatigueScore,
                    onChanged: widget.onFatigueChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OptionalScoreSection(
                    title: 'Náusea',
                    value: widget.nauseaScore,
                    onChanged: widget.onNauseaChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OptionalScoreSection(
                    title: 'Inchaço abdominal',
                    value: widget.bloatingScore,
                    onChanged: widget.onBloatingChanged,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Divider(),
                  ),

                  // 5. Observações livres
                  Text(
                    'Observações do dia',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: widget.notesController,
                    maxLines: 3,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Algo mais que você gostaria de lembrar para você ou seu médico?',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionalScoreSection extends StatelessWidget {
  const _OptionalScoreSection({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (value == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: textTheme.titleSmall),
          ),
          TextButton.icon(
            onPressed: () => onChanged(3),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Informar escala'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => onChanged(null),
              child: const Text('Limpar'),
            ),
          ],
        ),
        EndoCareSlider(
          label: title,
          value: value!.toDouble(),
          minCaption: '0 • Ausente',
          maxCaption: '10 • Muito forte',
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}

