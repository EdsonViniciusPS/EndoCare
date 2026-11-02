import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';

/// Slider base do EndoCare para escalas rápidas (como dor 0–10, fadiga e sono).
class EndoCareSlider extends StatelessWidget {
  const EndoCareSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.min = 0,
    this.max = 10,
    this.divisions = 10,
    this.usePainScaleColors = true,
    this.minCaption = '0 • Sem dor',
    this.maxCaption = '10 • Muito intensa',
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final String? label;
  final double min;
  final double max;
  final int? divisions;
  final bool usePainScaleColors;
  final String? minCaption;
  final String? maxCaption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeColor = usePainScaleColors
        ? AppColors.forPainLevel(value)
        : AppColors.primary;
    final roundedValue = value.round();
    final statusBadgeText = usePainScaleColors
        ? '$roundedValue • ${AppColors.painLabel(roundedValue)}'
        : '$roundedValue';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label != null)
              Expanded(
                child: Text(
                  label!,
                  style: textTheme.titleSmall,
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs + 2,
              ),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.14),
                borderRadius: AppSpacing.borderRadiusPill,
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                statusBadgeText,
                style: textTheme.labelMedium?.copyWith(
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.14),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: '$roundedValue',
            onChanged: onChanged,
          ),
        ),
        if (minCaption != null || maxCaption != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  minCaption ?? '',
                  style: textTheme.bodySmall,
                ),
                Text(
                  maxCaption ?? '',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

