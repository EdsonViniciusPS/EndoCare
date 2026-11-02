import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/impact/domain/models/impact_log.dart';

/// Card para registrar ou ajustar o nível de impacto (0–10 ou null) em uma
/// área específica da vida (trabalho, estudos, sono, exercícios, relacionamentos, rotina).
class ImpactAreaSliderCard extends StatelessWidget {
  const ImpactAreaSliderCard({
    super.key,
    required this.area,
    required this.value,
    required this.onChanged,
  });

  final ImpactArea area;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSet = value != null;
    final currentVal = value ?? 0;
    final color = isSet ? AppColors.forPainLevel(currentVal) : AppColors.outline;

    return EndoCareCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(area.icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.label,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isSet
                          ? '$currentVal/10 • ${ImpactLog.levelLabel(currentVal)}'
                          : 'Não se aplica / sem registro hoje',
                      style: textTheme.bodySmall?.copyWith(
                        color: isSet ? color : AppColors.textMuted,
                        fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSet)
                IconButton(
                  tooltip: 'Remover avaliação de ${area.label}',
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => onChanged(null),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Slider de 0 a 10
          Row(
            children: [
              Text(
                '0',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: isSet ? color : AppColors.outline,
                    inactiveTrackColor: AppColors.surfaceMuted,
                    thumbColor: isSet ? color : AppColors.outline,
                    overlayColor: color.withValues(alpha: 0.16),
                    valueIndicatorColor: color,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Slider(
                    value: currentVal.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: isSet ? '$currentVal' : '0',
                    onChanged: (double next) {
                      onChanged(next.round());
                    },
                  ),
                ),
              ),
              Text(
                '10',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          // Atalhos rápidos em chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickChip(
                  label: 'Nenhum (0)',
                  isSelected: isSet && currentVal == 0,
                  onTap: () => onChanged(0),
                ),
                const SizedBox(width: AppSpacing.xs),
                _QuickChip(
                  label: 'Leve (2)',
                  isSelected: isSet && currentVal == 2,
                  onTap: () => onChanged(2),
                ),
                const SizedBox(width: AppSpacing.xs),
                _QuickChip(
                  label: 'Moderado (5)',
                  isSelected: isSet && currentVal == 5,
                  onTap: () => onChanged(5),
                ),
                const SizedBox(width: AppSpacing.xs),
                _QuickChip(
                  label: 'Alto (8)',
                  isSelected: isSet && currentVal == 8,
                  onTap: () => onChanged(8),
                ),
                const SizedBox(width: AppSpacing.xs),
                _QuickChip(
                  label: 'Muito alto (10)',
                  isSelected: isSet && currentVal == 10,
                  onTap: () => onChanged(10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EndoCareChip(
      label: label,
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}
