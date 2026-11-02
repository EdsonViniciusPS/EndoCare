import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/calculators/domain/models/calculator_definition.dart';
import 'package:endocare/features/calculators/domain/models/calculator_interpretation.dart';
import 'package:endocare/features/calculators/domain/models/calculator_result.dart';
import 'package:endocare/features/calculators/presentation/screens/calculator_history_screen.dart';
import 'package:endocare/features/calculators/presentation/widgets/crisis_support_banner.dart';

/// Tela de exibição dos resultados da calculadora clínica.
///
/// Apresenta: pontuação, interpretação simples em linguagem leiga,
/// recomendações práticas, alerta de crise (se aplicável) e aviso legal de não diagnóstico.
class CalculatorResultScreen extends ConsumerWidget {
  const CalculatorResultScreen({
    super.key,
    required this.definition,
    required this.result,
    required this.interpretation,
  });

  final CalculatorDefinition definition;
  final CalculatorResult result;
  final CalculatorInterpretation interpretation;

  Color _severityColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('mínim') || lower.contains('sem') || lower.contains('subclín')) {
      return AppColors.success;
    }
    if (lower.contains('leve')) {
      return AppColors.painMild;
    }
    if (lower.contains('moderad')) {
      return AppColors.painModerate;
    }
    if (lower.contains('sever') || lower.contains('intens') || lower.contains('alto')) {
      return AppColors.painSevere;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final color = _severityColor(interpretation.severityLabel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da avaliação'),
        actions: [
          IconButton(
            tooltip: 'Histórico',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (ctx) => CalculatorHistoryScreen(
                    calculatorId: definition.id,
                    calculatorTitle: definition.title,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Alerta crítico de acolhimento (Item 9 do PHQ-9 ou crise emocional)
                  if (interpretation.isCrisisAlert) ...[
                    CrisisSupportBanner(
                      customMessage: interpretation.crisisHelpText,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // 2. Card de pontuação e severidade
                  EndoCareCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    elevated: true,
                    child: Column(
                      children: [
                        Text(
                          definition.title,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            result.formattedScore,
                            style: textTheme.displayMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'de ${interpretation.maxScore} pontos possíveis',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: Text(
                            interpretation.severityLabel,
                            style: textTheme.titleSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Interpretação em linguagem simples
                  EndoCareCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'O que este resultado indica?',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          interpretation.summary,
                          style: textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 4. Recomendações acolhedoras
                  if (interpretation.recommendations.isNotEmpty) ...[
                    EndoCareCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: AppColors.secondary,
                                size: 22,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Orientações para o seu cuidado',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...interpretation.recommendations.map(
                            (rec) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      rec,
                                      style: textTheme.bodySmall?.copyWith(
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // 5. Aviso explícito de não diagnóstico (Obrigatório seção 3 e 07)
                  EndoCareCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aviso de saúde e não diagnóstico',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                interpretation.disclaimer,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 6. Botões de ação
                  EndoCareButton(
                    label: 'Ver histórico desta calculadora',
                    icon: Icons.history_rounded,
                    variant: EndoCareButtonVariant.tonal,
                    isExpanded: true,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (ctx) => CalculatorHistoryScreen(
                            calculatorId: definition.id,
                            calculatorTitle: definition.title,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  EndoCareButton(
                    label: 'Concluir e voltar',
                    icon: Icons.arrow_back_rounded,
                    variant: EndoCareButtonVariant.outlined,
                    isExpanded: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
