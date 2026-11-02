import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/calculators/domain/models/calculator_question.dart';

/// Exibe exatamente uma pergunta por tela, com barra de progresso e controles
/// intuitivos de navegação, atendendo à seção 07 do EndoCare.md.
class QuestionStepView extends StatelessWidget {
  const QuestionStepView({
    super.key,
    required this.question,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.currentAnswer,
    required this.onAnswerChanged,
    required this.onNext,
    required this.onPrevious,
    this.isLastStep = false,
  });

  final CalculatorQuestion question;
  final int currentStepIndex;
  final int totalSteps;
  final dynamic currentAnswer;
  final ValueChanged<dynamic> onAnswerChanged;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final bool isLastStep;

  bool get _hasAnswer => currentAnswer != null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = (currentStepIndex + 1) / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Barra de progresso do questionário
        Row(
          children: [
            Text(
              'Pergunta ${currentStepIndex + 1} de $totalSteps',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.outline.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // 2. Enunciado da pergunta
        Text(
          question.text,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        if (question.hint != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            question.hint!,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),

        // 3. Área de resposta conforme o tipo de entrada
        Expanded(
          child: SingleChildScrollView(
            child: _buildInputContent(context),
          ),
        ),

        // 4. Controles de navegação (Anterior / Avançar)
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            if (onPrevious != null) ...[
              Expanded(
                flex: 1,
                child: EndoCareButton(
                  label: 'Anterior',
                  icon: Icons.chevron_left_rounded,
                  variant: EndoCareButtonVariant.outlined,
                  onPressed: onPrevious,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              flex: 2,
              child: EndoCareButton(
                label: isLastStep ? 'Concluir avaliação' : 'Avançar',
                icon: isLastStep
                    ? Icons.check_circle_outline_rounded
                    : Icons.chevron_right_rounded,
                variant: EndoCareButtonVariant.primary,
                onPressed: _hasAnswer ? onNext : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputContent(BuildContext context) {
    switch (question.type) {
      case QuestionInputType.options:
        return _buildOptionsList(context);
      case QuestionInputType.slider:
        return _buildSliderInput(context);
      case QuestionInputType.number:
        return _buildNumberInput(context);
    }
  }

  Widget _buildOptionsList(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: question.options.map((option) {
        final isSelected = currentAnswer == option.score;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: () => onAnswerChanged(option.score),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withValues(alpha: 0.4)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.outline,
                        width: isSelected ? 6 : 2,
                      ),
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? AppColors.primaryDark : null,
                          ),
                        ),
                        if (option.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            option.subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderInput(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = (currentAnswer as num?)?.toDouble() ?? question.minSliderValue;
    final color = AppColors.forPainLevel(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Text(
              value.round().toString(),
              style: textTheme.displaySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: AppColors.surfaceMuted,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.16),
            valueIndicatorColor: color,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: value,
            min: question.minSliderValue,
            max: question.maxSliderValue,
            divisions: question.sliderDivisions,
            label: value.round().toString(),
            onChanged: (next) => onAnswerChanged(next.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              question.sliderMinLabel ?? '${question.minSliderValue.round()}',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            Text(
              question.sliderMaxLabel ?? '${question.maxSliderValue.round()}',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberInput(BuildContext context) {
    final value = (currentAnswer as num?)?.toInt() ?? 28;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            icon: const Icon(Icons.remove_rounded),
            onPressed: () {
              if (value > 1) onAnswerChanged(value - 1);
            },
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$value',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton.filledTonal(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => onAnswerChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

