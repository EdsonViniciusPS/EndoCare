import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/calculators/domain/models/calculator_result.dart';
import 'package:endocare/features/calculators/presentation/providers/calculator_providers.dart';

/// Tela com o histórico de avaliações anteriores de calculadoras clínicas.
class CalculatorHistoryScreen extends ConsumerWidget {
  const CalculatorHistoryScreen({
    super.key,
    required this.calculatorId,
    required this.calculatorTitle,
  });

  final String calculatorId;
  final String calculatorTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final allResults = ref.watch(calculatorResultsStreamProvider).asData?.value ??
        const <CalculatorResult>[];

    final filtered = allResults
        .where((r) => r.calculadora == calculatorId)
        .toList(growable: false);

    final authUser = ref.watch(authStateChangesProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico: $calculatorTitle'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: filtered.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: AppSpacing.screenPadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const StorysetIllustration(
                            asset: AppAssets.personalGrowthBro,
                            height: 150,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Nenhuma avaliação anterior',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Assim que você responder a esta calculadora, seus resultados históricos aparecerão aqui para acompanhamento da evolução.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final dateStr =
                          DateFormat("dd 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR')
                              .format(item.data);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: EndoCareCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      'Pontuação: ${item.formattedScore}',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (item.grau != null) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '• ${item.grau}',
                                      style: textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (authUser != null)
                                    IconButton(
                                      tooltip: 'Excluir esta avaliação',
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: AppColors.textMuted,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                              'Excluir avaliação?',
                                            ),
                                            content: const Text(
                                              'Esta avaliação será apagada do seu histórico.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.error,
                                                ),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await ref
                                              .read(
                                                calculatorRepositoryProvider,
                                              )
                                              .deleteResult(
                                                uid: authUser.uid,
                                                resultId: item.id,
                                              );
                                        }
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                dateStr,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                item.interpretacao,
                                style: textTheme.bodySmall?.copyWith(
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

