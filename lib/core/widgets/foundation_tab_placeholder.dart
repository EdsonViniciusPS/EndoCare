import 'package:flutter/material.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/core/widgets/endocare_card.dart';
import 'package:endocare/core/widgets/endocare_chip.dart';
import 'package:endocare/core/widgets/endocare_logo.dart';
import 'package:endocare/core/widgets/endocare_slider.dart';
import 'package:endocare/core/widgets/storyset_illustration.dart';

/// Estrutura acolhedora de estado inicial para as abas da Etapa 0 (Fundação).
class FoundationTabPlaceholder extends StatelessWidget {
  const FoundationTabPlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustration,
    this.showComponentPreviewButton = false,
  });

  final String title;
  final String subtitle;
  final StorysetAsset illustration;
  final bool showComponentPreviewButton;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: EndoCareCard(
            elevated: true,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StorysetIllustration(
                  asset: illustration,
                  height: 175,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                if (showComponentPreviewButton) ...[
                  const SizedBox(height: AppSpacing.xl),
                  EndoCareButton(
                    label: 'Ver componentes base',
                    icon: Icons.auto_awesome_rounded,
                    variant: EndoCareButtonVariant.tonal,
                    onPressed: () => _showDesignSystemSheet(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDesignSystemSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => const _DesignSystemPreviewSheet(),
    );
  }
}

class _DesignSystemPreviewSheet extends StatefulWidget {
  const _DesignSystemPreviewSheet();

  @override
  State<_DesignSystemPreviewSheet> createState() =>
      _DesignSystemPreviewSheetState();
}

class _DesignSystemPreviewSheetState extends State<_DesignSystemPreviewSheet> {
  double _painValue = 3;
  final Set<String> _selectedChips = {'Cólica leve', 'Fadiga'};

  static const List<String> _sampleSymptoms = [
    'Cólica leve',
    'Dor pélvica',
    'Fadiga',
    'Inchaço',
    'Náusea',
    'Sono tranquilo',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
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
            const SizedBox(height: AppSpacing.lg),
            const Center(
              child: EndoCareLogo(
                variant: EndoCareLogoVariant.horizontal,
                height: 52,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Componentes base — Etapa 0',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Tema acolhedor, botões, cards, chips e slider de intensidade prontos para os próximos módulos.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            EndoCareCard(
              child: EndoCareSlider(
                label: 'Intensidade da dor (0–10)',
                value: _painValue,
                onChanged: (next) => setState(() => _painValue = next),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EndoCareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chips de seleção rápida', style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: _sampleSymptoms.map((symptom) {
                      final isSelected = _selectedChips.contains(symptom);
                      return EndoCareChip(
                        label: symptom,
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedChips.add(symptom);
                            } else {
                              _selectedChips.remove(symptom);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EndoCareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Botões padrão', style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  EndoCareButton(
                    label: 'Ação principal',
                    icon: Icons.check_rounded,
                    isExpanded: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  EndoCareButton(
                    label: 'Ação secundária',
                    variant: EndoCareButtonVariant.outlined,
                    isExpanded: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
