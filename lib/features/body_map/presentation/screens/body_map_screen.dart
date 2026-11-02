import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/body_map/domain/models/body_heatmap_summary.dart';
import 'package:endocare/features/body_map/domain/models/body_region_definition.dart';
import 'package:endocare/features/body_map/domain/models/body_region_pain_entry.dart';
import 'package:endocare/features/body_map/presentation/providers/body_map_providers.dart';
import 'package:endocare/features/body_map/presentation/widgets/body_silhouette_svg.dart';
import 'package:endocare/features/body_map/presentation/widgets/region_pain_editor_sheet.dart';
import 'package:endocare/features/home/presentation/providers/home_providers.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/symptoms/presentation/providers/symptom_providers.dart';

enum _BodyMapViewMode { register, heatmap }

/// Tela completa do Mapa Corporal Interativo (Frente e Costas em SVG)
/// com registro detalhado por região e Heatmap Histórico agregado.
class BodyMapScreen extends ConsumerStatefulWidget {
  const BodyMapScreen({
    super.key,
    this.initialDate,
    this.openInHeatmap = false,
  });

  final DateTime? initialDate;
  final bool openInHeatmap;

  @override
  ConsumerState<BodyMapScreen> createState() => _BodyMapScreenState();
}

class _BodyMapScreenState extends ConsumerState<BodyMapScreen> {
  late _BodyMapViewMode _viewMode;
  BodySide _activeSide = BodySide.front;
  BodyHeatmapPeriod _heatmapPeriod = BodyHeatmapPeriod.days30;
  String? _highlightedHeatmapRegionId;

  DateTime? _targetDate;
  String? _hydratedKey;
  final Map<String, BodyRegionPainEntry> _entriesById = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.openInHeatmap
        ? _BodyMapViewMode.heatmap
        : _BodyMapViewMode.register;
    if (widget.initialDate != null) {
      _targetDate = SymptomLog.normalizeDate(widget.initialDate!);
    }
  }

  void _hydrateFromBundle(QuickLogInitialBundle bundle, String key) {
    if (_hydratedKey == key) return;
    _hydratedKey = key;
    _entriesById.clear();
    // Se já há registro no próprio dia, hidrata suas regiões; se ainda não há,
    // reaproveita o mapa anterior como ponto de partida editável.
    for (final entry in bundle.initialLog.mapaCorporal) {
      _entriesById[entry.regionId] = entry;
    }
  }

  Future<void> _onTapRegisterRegion(
    BodyRegionDefinition region,
    int fallbackIntensity,
  ) async {
    final outcome = await RegionPainEditorSheet.show(
      context: context,
      region: region,
      existingEntry: _entriesById[region.id],
      defaultIntensity: fallbackIntensity > 0 ? fallbackIntensity : 5,
    );
    if (outcome == null || !mounted) return;

    setState(() {
      if (outcome.removed) {
        _entriesById.remove(region.id);
      } else if (outcome.entry != null) {
        _entriesById[region.id] = outcome.entry!;
      }
    });
  }

  Future<void> _saveBodyMap(
    DateTime activeDate,
    QuickLogInitialBundle? bundle,
  ) async {
    final authUser = ref.read(authStateChangesProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    if (authUser == null) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(symptomLogRepositoryProvider);
      final existing =
          await repo.getLogForDate(uid: authUser.uid, date: activeDate);
      final baseLog = existing ??
          bundle?.initialLog ??
          SymptomLog.emptyForDate(activeDate);

      final entries = _entriesById.values.toList(growable: false);
      final maxRegionPain = entries.isEmpty
          ? 0
          : entries.map((e) => e.intensidade).reduce(math.max);

      // Mantém `regioes` sincronizado com as regiões selecionadas no mapa,
      // preservando eventuais tags manuais que não sejam nomes antigos do mapa.
      final catalogLabels =
          BodyMapCatalog.allRegions.map((r) => r.label).toSet();
      final manualRegions = baseLog.regioes
          .where((label) => !catalogLabels.contains(label))
          .toList();
      final syncedRegions = <String>{
        ...manualRegions,
        ...entries.map((e) => e.regionLabel),
      }.toList(growable: false);

      final updatedLog = baseLog.copyWith(
        id: SymptomLog.dateKeyFor(activeDate),
        data: activeDate,
        dor: math.max(baseLog.dor, maxRegionPain),
        regioes: syncedRegions,
        mapaCorporal: entries,
      );

      await repo.saveLog(uid: authUser.uid, log: updatedLog);

      _hydratedKey = null;
      ref.invalidate(quickLogInitialBundleProvider(activeDate));
      ref.invalidate(bodyMapHistoryLogsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mapa corporal salvo com sucesso.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar o mapa agora. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = SymptomLog.normalizeDate(ref.watch(homeClockProvider)());
    final activeDate = _targetDate ?? today;
    final bundleAsync = ref.watch(quickLogInitialBundleProvider(activeDate));
    final bundle = bundleAsync.asData?.value;

    if (bundle != null) {
      final key =
          '${SymptomLog.dateKeyFor(activeDate)}_${bundle.isExistingForDate}';
      _hydrateFromBundle(bundle, key);
    }

    final textTheme = Theme.of(context).textTheme;
    String dateLabel;
    try {
      dateLabel = DateFormat("d 'de' MMMM", 'pt_BR').format(activeDate);
    } catch (_) {
      dateLabel = '${activeDate.day}/${activeDate.month}/${activeDate.year}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Mapa corporal da dor'),
      ),
      body: Column(
        children: [
          // Seletor superior: Registrar no mapa vs Heatmap histórico
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeTabButton(
                        label: 'Registrar no mapa',
                        icon: Icons.touch_app_outlined,
                        selected: _viewMode == _BodyMapViewMode.register,
                        onTap: () => setState(
                          () => _viewMode = _BodyMapViewMode.register,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _ModeTabButton(
                        label: 'Heatmap histórico',
                        icon: Icons.insights_rounded,
                        selected: _viewMode == _BodyMapViewMode.heatmap,
                        onTap: () => setState(
                          () => _viewMode = _BodyMapViewMode.heatmap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _viewMode == _BodyMapViewMode.register
                ? _buildRegisterView(
                    context: context,
                    textTheme: textTheme,
                    dateLabel: dateLabel,
                    bundle: bundle,
                  )
                : _buildHeatmapView(
                    context: context,
                    textTheme: textTheme,
                  ),
          ),

          if (_viewMode == _BodyMapViewMode.register)
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.outline.withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: EndoCareButton(
                        label: 'Salvar mapa corporal (${_entriesById.length})',
                        icon: Icons.check_rounded,
                        isLoading: _isSaving,
                        isExpanded: true,
                        onPressed: () => _saveBodyMap(activeDate, bundle),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegisterView({
    required BuildContext context,
    required TextTheme textTheme,
    required String dateLabel,
    required QuickLogInitialBundle? bundle,
  }) {
    final frontCount =
        _entriesById.values.where((e) => e.side == BodySide.front).length;
    final backCount =
        _entriesById.values.where((e) => e.side == BodySide.back).length;
    final entriesList = _entriesById.values.toList(growable: false);

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Toque na região exata onde sente dor em $dateLabel.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              _SideToggleBar(
                activeSide: _activeSide,
                frontCount: frontCount,
                backCount: backCount,
                onChanged: (side) => setState(() => _activeSide = side),
              ),
              const SizedBox(height: AppSpacing.md),

              EndoCareCard(
                elevated: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                child: BodySilhouetteCanvas(
                  side: _activeSide,
                  selectedEntriesById: _entriesById,
                  onRegionTap: (region) => _onTapRegisterRegion(
                    region,
                    bundle?.initialLog.dor ?? 5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Regiões marcadas (${entriesList.length})',
                    style: textTheme.titleMedium,
                  ),
                  if (entriesList.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_entriesById.clear),
                      child: const Text('Limpar todas'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              if (entriesList.isEmpty)
                EndoCareCard(
                  backgroundColor: AppColors.surfaceSoft,
                  child: Text(
                    'Nenhuma região selecionada ainda. Toque em qualquer ponto da silhueta (Frente ou Costas) para informar intensidade, tipo, duração e frequência.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall,
                  ),
                )
              else
                ...entriesList.map((entry) {
                  final color = AppColors.forPainLevel(entry.intensidade);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: EndoCareCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      onTap: () {
                        final def = BodyMapCatalog.findById(entry.regionId);
                        if (def != null) {
                          setState(() => _activeSide = def.side);
                          _onTapRegisterRegion(
                            def,
                            entry.intensidade,
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius: AppSpacing.borderRadiusSm,
                              border: Border.all(
                                color: color.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '${entry.intensidade}/10',
                              style: textTheme.labelMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.regionLabel} • ${entry.side.label}',
                                  style: textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${entry.tipoDor} • ${entry.duracao} • ${entry.frequencia}',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remover região',
                            onPressed: () {
                              setState(
                                () => _entriesById.remove(entry.regionId),
                              );
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapView({
    required BuildContext context,
    required TextTheme textTheme,
  }) {
    final heatmapAsync = ref.watch(bodyHeatmapSummaryProvider(_heatmapPeriod));

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filtro de período (7 dias, 30 dias, 90 dias, Tudo)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: BodyHeatmapPeriod.values.map((period) {
                  return EndoCareChip(
                    label: period.label,
                    selected: _heatmapPeriod == period,
                    onSelected: (_) {
                      setState(() {
                        _heatmapPeriod = period;
                        _highlightedHeatmapRegionId = null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              heatmapAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (_, _) => EndoCareCard(
                  child: Text(
                    'Não foi possível carregar o histórico corporal no momento.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                ),
                data: (summary) {
                  if (summary.isEmpty) {
                    return EndoCareCard(
                      elevated: true,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          const StorysetIllustration(
                            asset: AppAssets.femaleBodyShapesAmico,
                            height: 165,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Sem regiões mapeadas neste período',
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Conforme você registrar os locais da dor, seu mapa térmico histórico aparecerá aqui para apoiar suas consultas.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SideToggleBar(
                        activeSide: _activeSide,
                        frontCount: summary.countForSide(BodySide.front),
                        backCount: summary.countForSide(BodySide.back),
                        onChanged: (side) => setState(() => _activeSide = side),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      EndoCareCard(
                        elevated: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            BodySilhouetteCanvas(
                              side: _activeSide,
                              isHeatmapMode: true,
                              heatmapStatsById: summary.statsByRegionId,
                              highlightedRegionId: _highlightedHeatmapRegionId,
                              onRegionTap: (region) {
                                if (summary.statsByRegionId
                                    .containsKey(region.id)) {
                                  setState(() {
                                    _highlightedHeatmapRegionId = region.id;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _HeatmapLegendBar(),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Baseado em ${summary.totalMappedDays} ${summary.totalMappedDays == 1 ? 'dia com mapa registrado' : 'dias com mapa registrado'}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Histórico agregado por região',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...summary.rankedRegions.map((stats) {
                        final isHighlighted =
                            _highlightedHeatmapRegionId == stats.region.id;
                        final avgColor =
                            AppColors.forPainLevel(stats.averageIntensity);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: EndoCareCard(
                            borderColor: isHighlighted
                                ? AppColors.primary
                                : AppColors.outline,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            onTap: () {
                              setState(() {
                                _activeSide = stats.region.side;
                                _highlightedHeatmapRegionId = stats.region.id;
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: avgColor.withValues(alpha: 0.16),
                                    borderRadius: AppSpacing.borderRadiusSm,
                                  ),
                                  child: Text(
                                    '${stats.occurrences}x',
                                    style: textTheme.titleSmall?.copyWith(
                                      color: avgColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${stats.region.label} • ${stats.region.side.label}',
                                        style: textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Média ${stats.averageIntensity.toStringAsFixed(1)}/10 (pico ${stats.maxIntensity}/10)',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: avgColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${stats.predominantPainType} • ${stats.predominantDuration} • ${stats.predominantFrequency}',
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? AppColors.primaryContainer : AppColors.surfaceSoft,
      borderRadius: AppSpacing.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideToggleBar extends StatelessWidget {
  const _SideToggleBar({
    required this.activeSide,
    required this.frontCount,
    required this.backCount,
    required this.onChanged,
  });

  final BodySide activeSide;
  final int frontCount;
  final int backCount;
  final ValueChanged<BodySide> onChanged;

  @override
  Widget build(BuildContext context) {
    final frontLabel = frontCount > 0 ? 'Frente ($frontCount)' : 'Frente';
    final backLabel = backCount > 0 ? 'Costas ($backCount)' : 'Costas';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EndoCareChip(
          label: frontLabel,
          icon: Icons.accessibility_new_rounded,
          selected: activeSide == BodySide.front,
          onSelected: (_) => onChanged(BodySide.front),
        ),
        const SizedBox(width: AppSpacing.sm),
        EndoCareChip(
          label: backLabel,
          icon: Icons.cached_rounded,
          selected: activeSide == BodySide.back,
          onSelected: (_) => onChanged(BodySide.back),
        ),
      ],
    );
  }
}

class _HeatmapLegendBar extends StatelessWidget {
  const _HeatmapLegendBar();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Menor', style: textTheme.labelSmall),
        const SizedBox(width: AppSpacing.xs),
        Container(
          width: 110,
          height: 8,
          decoration: const BoxDecoration(
            borderRadius: AppSpacing.borderRadiusPill,
            gradient: LinearGradient(
              colors: [
                AppColors.painModerate,
                AppColors.painStrong,
                AppColors.painSevere,
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('Maior concentração', style: textTheme.labelSmall),
      ],
    );
  }
}
