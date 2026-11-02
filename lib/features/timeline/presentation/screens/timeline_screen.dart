import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/timeline/domain/models/timeline_event.dart';
import 'package:endocare/features/timeline/presentation/providers/timeline_providers.dart';
import 'package:endocare/features/timeline/presentation/widgets/timeline_event_card.dart';

/// Tela da Linha do tempo unificada da doença (seções 4.2, 5.1 e 7 do EndoCare.md).
///
/// Unifica em ordem cronológica:
/// - Crises de sintomas (dor ≥ 7 e marcadas no calendário)
/// - Consultas e exames
/// - Cirurgias e procedimentos
/// - Tratamentos iniciados, encerrados e efeitos percebidos
/// - Mudanças de sintomas (tendências e novos sintomas sem presumir causalidade)
/// - Ciclo (início de menstruação)
/// - Diário de impacto na rotina
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final allEvents = ref.watch(allTimelineEventsProvider);
    final filteredEvents = ref.watch(filteredTimelineEventsProvider);
    final selectedCategories = ref.watch(timelineCategoryFilterProvider);
    final newestFirst = ref.watch(timelineSortNewestFirstProvider);
    final counts = ref.watch(timelineCategoryCountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Linha do tempo'),
        actions: [
          IconButton(
            tooltip: newestFirst
                ? 'Mais recentes primeiro (toque para inverter)'
                : 'Mais antigas primeiro (toque para inverter)',
            icon: Icon(
              newestFirst
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
            ),
            onPressed: () {
              ref.read(timelineSortNewestFirstProvider.notifier).toggle();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Barra de filtros horizontais por categoria
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  EndoCareChip(
                    label: 'Todos (${allEvents.length})',
                    selected: selectedCategories.isEmpty,
                    onSelected: (_) {
                      ref.read(timelineCategoryFilterProvider.notifier).reset();
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ...TimelineCategory.values.map((category) {
                    final isSelected = selectedCategories.contains(category);
                    final count = counts[category] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: EndoCareChip(
                        label: '${category.label} ($count)',
                        selected: isSelected,
                        activeColor: category.color,
                        onSelected: (_) {
                          ref
                              .read(timelineCategoryFilterProvider.notifier)
                              .toggle(category);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 2. Feed cronológico ou estado vazio
          Expanded(
            child: filteredEvents.isEmpty
                ? _EmptyTimelineView(
                    hasAnyEvents: allEvents.isNotEmpty,
                    onResetFilters: () {
                      ref.read(timelineCategoryFilterProvider.notifier).reset();
                    },
                  )
                : Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.xxl,
                        ),
                        itemCount: filteredEvents.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                                left: 40,
                              ),
                              child: Text(
                                '${filteredEvents.length} eventos • ${newestFirst ? 'Mais recentes primeiro' : 'Mais antigos primeiro'}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          final eventIndex = index - 1;
                          final event = filteredEvents[eventIndex];
                          return TimelineEventCard(
                            key: ValueKey(event.id),
                            event: event,
                            isFirst: eventIndex == 0,
                            isLast: eventIndex == filteredEvents.length - 1,
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimelineView extends StatelessWidget {
  const _EmptyTimelineView({
    required this.hasAnyEvents,
    required this.onResetFilters,
  });

  final bool hasAnyEvents;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StorysetIllustration(
                asset: AppAssets.personalGrowthBro,
                height: 160,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                hasAnyEvents
                    ? 'Nenhum evento encontrado'
                    : 'Sua linha do tempo da doença',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                hasAnyEvents
                    ? 'Não há registros para os filtros selecionados neste momento.'
                    : 'Conforme você registrar sintomas, ciclos, tratamentos, consultas e impacto na rotina, a evolução cronológica aparecerá aqui de forma unificada.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (hasAnyEvents)
                EndoCareButton(
                  label: 'Mostrar todos os eventos',
                  icon: Icons.filter_alt_off_rounded,
                  variant: EndoCareButtonVariant.outlined,
                  onPressed: onResetFilters,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
