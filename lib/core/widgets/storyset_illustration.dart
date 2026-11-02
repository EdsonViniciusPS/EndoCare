import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_colors.dart';

/// Renderizador padronizado das ilustrações Storyset SVG locais.
class StorysetIllustration extends StatelessWidget {
  const StorysetIllustration({
    super.key,
    required this.asset,
    this.height = 180,
    this.width,
    this.fit = BoxFit.contain,
  });

  final StorysetAsset asset;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset.path,
      height: height,
      width: width,
      fit: fit,
      semanticsLabel: asset.semanticLabel,
      placeholderBuilder: (context) => SizedBox(
        height: height,
        width: width,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

