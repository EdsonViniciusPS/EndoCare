import 'package:flutter/material.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_spacing.dart';

/// Variantes oficiais dos 3 logos JPEG existentes em `assets/logos/`.
enum EndoCareLogoVariant { horizontal, wordmark, negativeBw }

/// Renderizador padronizado dos logos JPEG oficiais do EndoCare.
///
/// Como os arquivos JPEG possuem fundo branco (`#FFFFFF`), este widget os
/// aplica sobre um container branco com cantos arredondados (ou aplica filtro
/// de inversão para `logo_negative_bw.jpg` sobre fundos escuros), conforme a
/// seção 2.2 da especificação.
class EndoCareLogo extends StatelessWidget {
  const EndoCareLogo({
    super.key,
    this.variant = EndoCareLogoVariant.horizontal,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xxs,
    ),
    this.invertForDarkSurface = false,
  });

  final EndoCareLogoVariant variant;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool invertForDarkSurface;

  String get _assetPath => switch (variant) {
        EndoCareLogoVariant.horizontal => AppAssets.logoHorizontal,
        EndoCareLogoVariant.wordmark => AppAssets.wordmark,
        EndoCareLogoVariant.negativeBw => AppAssets.logoNegativeBw,
      };

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      _assetPath,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'EndoCare',
    );

    if (invertForDarkSurface && variant == EndoCareLogoVariant.negativeBw) {
      // Matriz de inversão de canais RGB para exibir o logo P&B em fundo escuro.
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255, // R
          0, -1, 0, 0, 255, // G
          0, 0, -1, 0, 255, // B
          0, 0, 0, 1, 0, // A
        ]),
        child: image,
      );
      return ClipRRect(
        borderRadius: AppSpacing.borderRadiusSm,
        child: image,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Padding(
        padding: padding,
        child: image,
      ),
    );
  }
}

