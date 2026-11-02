import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';

/// Card base do EndoCare com cantos arredondados, borda suave e sombra discreta.
class EndoCareCard extends StatelessWidget {
  const EndoCareCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.outline,
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: borderColor),
        boxShadow: elevated ? AppSpacing.softShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.borderRadiusLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

