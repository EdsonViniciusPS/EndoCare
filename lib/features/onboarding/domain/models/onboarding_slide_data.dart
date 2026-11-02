import 'package:flutter/material.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_colors.dart';

/// Dados visuais e textuais de cada tela do Onboarding do EndoCare.
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.illustration,
    required this.accentColor,
    required this.haloColor,
  });

  final String badge;
  final String title;
  final String description;
  final StorysetAsset illustration;
  final Color accentColor;
  final Color haloColor;

  /// As 3 telas oficiais de Onboarding com artes e paletas distintas
  /// distribuídas via `AppAssets.byIndex(StorysetThemeGroup.onboardingAndWellness, i)`:
  /// 0 -> Rosa (`Peace of mind-bro.svg`)
  /// 1 -> Coral (`personal growth-bro.svg`)
  /// 2 -> Azul/Pêssego (`Healthy habit-rafiki.svg`)
  static List<OnboardingSlideData> get slides => [
        OnboardingSlideData(
          badge: 'Cuidado sem pressa',
          title: 'Um espaço acolhedor para ouvir o seu corpo',
          description:
              'Registre dor, sintomas, humor e sono em poucos segundos — sem formulários enormes, mesmo nos dias mais difíceis.',
          illustration: AppAssets.byIndex(
            StorysetThemeGroup.onboardingAndWellness,
            0,
          ),
          accentColor: AppColors.primary,
          haloColor: AppColors.primaryContainer,
        ),
        OnboardingSlideData(
          badge: 'Seu ritmo é único',
          title: 'Entenda seus padrões com clareza',
          description:
              'Acompanhe ciclo menstrual, crises, medicamentos e consultas lado a lado, sem presumir que todo sintoma venha do ciclo.',
          illustration: AppAssets.byIndex(
            StorysetThemeGroup.onboardingAndWellness,
            1,
          ),
          accentColor: AppColors.tertiary,
          haloColor: AppColors.tertiaryContainer,
        ),
        OnboardingSlideData(
          badge: 'Consultas mais tranquilas',
          title: 'Leve informações claras para quem cuida de você',
          description:
              'Organize sua evolução, gere relatórios objetivos para o médico e acesse conteúdos educativos revisados com carinho.',
          illustration: AppAssets.byIndex(
            StorysetThemeGroup.onboardingAndWellness,
            2,
          ),
          accentColor: AppColors.info,
          haloColor: AppColors.infoContainer,
        ),
      ];
}

