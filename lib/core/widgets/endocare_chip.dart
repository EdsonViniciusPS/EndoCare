import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';

/// Chip selecionável rápido pensado para registro de sintomas com um único toque.
class EndoCareChip extends StatelessWidget {
  const EndoCareChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.activeColor = AppColors.primary,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = selected
        ? activeColor.withValues(alpha: 0.14)
        : AppColors.surface;
    final borderColor = selected ? activeColor : AppColors.outline;
    final foregroundColor = selected ? activeColor : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected == null ? null : () => onSelected!(!selected),
          borderRadius: AppSpacing.borderRadiusPill,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppSpacing.borderRadiusPill,
              border: Border.all(
                color: borderColor,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foregroundColor),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

