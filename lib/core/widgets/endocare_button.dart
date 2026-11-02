import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';

/// Variantes visuais dos botões padrão do EndoCare.
enum EndoCareButtonVariant { primary, secondary, tonal, outlined, text }

/// Botão base acessível e acolhedor com área de toque confortável (52px).
class EndoCareButton extends StatelessWidget {
  const EndoCareButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = EndoCareButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final EndoCareButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: _foregroundColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(trailingIcon, size: 19),
              ],
            ],
          );

    final Widget button = switch (variant) {
      EndoCareButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      EndoCareButtonVariant.secondary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
          child: child,
        ),
      EndoCareButtonVariant.tonal => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.primary,
          ),
          child: child,
        ),
      EndoCareButtonVariant.outlined => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      EndoCareButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
    };

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Color get _foregroundColor => switch (variant) {
        EndoCareButtonVariant.primary ||
        EndoCareButtonVariant.secondary =>
          Colors.white,
        EndoCareButtonVariant.tonal ||
        EndoCareButtonVariant.outlined ||
        EndoCareButtonVariant.text =>
          AppColors.primary,
      };
}

