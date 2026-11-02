import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/calculators/domain/calculators_registry.dart';
import 'package:endocare/features/calculators/domain/models/calculator_category.dart';
import 'package:endocare/features/calculators/presentation/providers/calculator_providers.dart';
import 'package:endocare/features/calculators/presentation/screens/calculator_history_screen.dart';
import 'package:endocare/features/calculators/presentation/screens/calculator_questionnaire_screen.dart';
import 'package:endocare/features/calculators/presentation/widgets/calculator_card.dart';

/// Tela ou componente que lista as calculadoras clínicas organizadas por categoria.
class CalculatorsListView extends ConsumerWidget {
  const CalculatorsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(calculatorCategoryFilterProvider);
    final latestResults = ref.watch(calculatorLatestResultsMapProvider);

    final calculators = CalculatorsRegistry.all.where((calc) {
      if (selectedCategory == null) return true;
      return calc.category == selectedCategory;
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Barra horizontal de filtros por categoria
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              EndoCareChip(
                label: 'Todas (${CalculatorsRegistry.all.length})',
                selected: selectedCategory == null,
                onSelected: (_) {
                  ref.read(calculatorCategoryFilterProvider.notifier).select(null);
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              ...CalculatorCategory.values.map((cat) {
                final count = CalculatorsRegistry.all
                    .where((c) => c.category == cat)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: EndoCareChip(
                    label: '${cat.label} ($count)',
                    selected: selectedCategory == cat,
                    activeColor: cat.color,
                    onSelected: (_) {
                      ref
                          .read(calculatorCategoryFilterProvider.notifier)
                          .select(selectedCategory == cat ? null : cat);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Lista de calculadoras
        ...calculators.map((def) {
          final latest = latestResults[def.id];

          return Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: CalculatorCard(
              definition: def,
              latestResult: latest,
              onStart: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (ctx) => CalculatorQuestionnaireScreen(
                      calculatorId: def.id,
                    ),
                  ),
                );
              },
              onViewHistory: latest != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (ctx) => CalculatorHistoryScreen(
                            calculatorId: def.id,
                            calculatorTitle: def.title,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          );
        }),
      ],
    );
  }
}

