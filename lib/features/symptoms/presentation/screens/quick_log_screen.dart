import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/body_map/domain/models/body_region_pain_entry.dart';
import 'package:endocare/features/body_map/presentation/providers/body_map_providers.dart';
import 'package:endocare/features/home/presentation/providers/home_providers.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_catalog.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/symptoms/presentation/providers/symptom_providers.dart';
import 'package:endocare/features/symptoms/presentation/widgets/optional_symptom_details_card.dart';

/// Aba 3 (central) — Registro diário rápido de sintomas em poucos segundos.
///
/// Reaproveita valores padrão do dia anterior quando o dia ainda está vazio,
/// mantém detalhes opcionais recolhidos e exibe botão "Salvar" fixo no rodapé.
class QuickLogScreen extends ConsumerStatefulWidget {
  const QuickLogScreen({super.key});

  @override
  ConsumerState<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends ConsumerState<QuickLogScreen> {
  DateTime? _selectedDate;
  String? _hydratedKey;

  int _pain = 0;
  int _sleep = 7;
  String? _mood;
  final Set<String> _quickSymptoms = {};

  // Detalhes opcionais e mapa corporal
  int? _cramps;
  final Set<String> _regions = {};
  List<BodyRegionPainEntry> _bodyMapEntries = const [];
  bool _hasSexualPain = false;
  String _sexualPainLocation = SymptomCatalog.sexualPainLocations.first;
  int _sexualPainScale = 4;
  final Set<String> _intestinal = {};
  final Set<String> _urinary = {};
  int? _fatigue;
  int? _nausea;
  int? _bloating;
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;
  bool _clearedPrefillManually = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime _effectiveToday() {
    return SymptomLog.normalizeDate(ref.read(homeClockProvider)());
  }

  void _hydrateFromBundle(QuickLogInitialBundle bundle, String hydrationKey) {
    if (_hydratedKey == hydrationKey) return;
    _hydratedKey = hydrationKey;
    _clearedPrefillManually = false;

    final log = bundle.initialLog;
    _pain = log.dor;
    _sleep = log.sono;
    _mood = log.humor;
    _quickSymptoms
      ..clear()
      ..addAll(log.tipos);
    _cramps = log.colica;
    _regions
      ..clear()
      ..addAll(log.regioes);
    _bodyMapEntries = List<BodyRegionPainEntry>.from(log.mapaCorporal);
    _hasSexualPain = log.dorRelacao != null;
    if (log.dorRelacao != null) {
      _sexualPainLocation = log.dorRelacao!.local.isNotEmpty
          ? log.dorRelacao!.local
          : SymptomCatalog.sexualPainLocations.first;
      _sexualPainScale = log.dorRelacao!.escala;
    } else {
      _sexualPainLocation = SymptomCatalog.sexualPainLocations.first;
      _sexualPainScale = 4;
    }
    _intestinal
      ..clear()
      ..addAll(log.intestinal);
    _urinary
      ..clear()
      ..addAll(log.urinario);
    _fatigue = log.fadiga;
    _nausea = log.nausea;
    _bloating = log.inchaco;
    _notesController.text = log.notas ?? '';
  }

  void _resetToCleanDefaults() {
    setState(() {
      _clearedPrefillManually = true;
      _pain = 0;
      _sleep = 7;
      _mood = null;
      _quickSymptoms.clear();
      _cramps = null;
      _regions.clear();
      _bodyMapEntries = const [];
      _hasSexualPain = false;
      _sexualPainLocation = SymptomCatalog.sexualPainLocations.first;
      _sexualPainScale = 4;
      _intestinal.clear();
      _urinary.clear();
      _fatigue = null;
      _nausea = null;
      _bloating = null;
      _notesController.clear();
    });
  }

  void _changeDate(DateTime nextDate) {
    final normalized = SymptomLog.normalizeDate(nextDate);
    final today = _effectiveToday();
    if (normalized.isAfter(today)) return;
    setState(() {
      _selectedDate = normalized;
      _hydratedKey = null;
    });
  }

  Future<void> _pickDate(DateTime currentSelected) async {
    final today = _effectiveToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentSelected,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      helpText: 'Escolher dia do registro',
    );
    if (picked != null && mounted) {
      _changeDate(picked);
    }
  }

  int get _optionalFilledCount {
    var count = 0;
    if (_cramps != null) count++;
    if (_regions.isNotEmpty) count++;
    if (_hasSexualPain) count++;
    if (_intestinal.isNotEmpty) count++;
    if (_urinary.isNotEmpty) count++;
    if (_fatigue != null) count++;
    if (_nausea != null) count++;
    if (_bloating != null) count++;
    if (_notesController.text.trim().isNotEmpty) count++;
    return count;
  }

  Future<void> _openBodyMap(
    DateTime activeDate, {
    bool openInHeatmap = false,
  }) async {
    final dateQuery = 'data=${SymptomLog.dateKeyFor(activeDate)}';
    final modeQuery = openInHeatmap ? '&modo=heatmap' : '';
    await context.push('${AppRoutes.bodyMap}?$dateQuery$modeQuery');
    if (!mounted) return;

    final authUser = ref.read(authStateChangesProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    if (authUser == null) return;

    final latest = await ref
        .read(symptomLogRepositoryProvider)
        .getLogForDate(uid: authUser.uid, date: activeDate);
    if (latest != null && mounted) {
      setState(() {
        _bodyMapEntries = List<BodyRegionPainEntry>.from(latest.mapaCorporal);
        for (final entry in latest.mapaCorporal) {
          _regions.add(entry.regionLabel);
        }
        if (latest.dor > _pain) {
          _pain = latest.dor;
        }
      });
    }
  }

  Future<void> _save(DateTime targetDate) async {
    FocusScope.of(context).unfocus();
    final authUser = ref.read(authStateChangesProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;

    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre na sua conta para salvar seus registros.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final log = SymptomLog(
      id: SymptomLog.dateKeyFor(targetDate),
      data: targetDate,
      dor: _pain,
      sono: _sleep,
      humor: _mood,
      tipos: _quickSymptoms.toList(growable: false),
      regioes: _regions.toList(growable: false),
      mapaCorporal: List<BodyRegionPainEntry>.unmodifiable(_bodyMapEntries),
      colica: _cramps,
      dorRelacao: _hasSexualPain
          ? SexualPainEntry(
              local: _sexualPainLocation,
              escala: _sexualPainScale,
            )
          : null,
      intestinal: _intestinal.toList(growable: false),
      urinario: _urinary.toList(growable: false),
      fadiga: _fatigue,
      nausea: _nausea,
      inchaco: _bloating,
      notas: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    try {
      await ref
          .read(symptomLogRepositoryProvider)
          .saveLog(uid: authUser.uid, log: log);

      // Recarrega o bundle desta data como registro já salvo.
      _hydratedKey = null;
      ref.invalidate(quickLogInitialBundleProvider(targetDate));
      ref.invalidate(bodyMapHistoryLogsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro salvo com sucesso.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar agora. Verifique sua conexão e tente novamente.',
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
    final activeDate = _selectedDate ?? today;
    final bundleAsync = ref.watch(quickLogInitialBundleProvider(activeDate));

    final bundle = bundleAsync.asData?.value;
    if (bundle != null) {
      final hydrationKey =
          '${SymptomLog.dateKeyFor(activeDate)}_${bundle.isExistingForDate}';
      _hydrateFromBundle(bundle, hydrationKey);
    }

    final textTheme = Theme.of(context).textTheme;
    final isToday = activeDate == today;
    final isYesterday =
        activeDate == today.subtract(const Duration(days: 1));

    String formattedShortDate;
    try {
      formattedShortDate = DateFormat("d 'de' MMM", 'pt_BR').format(activeDate);
    } catch (_) {
      formattedShortDate = '${activeDate.day}/${activeDate.month}';
    }
    final dateTitle = isToday
        ? 'Hoje • $formattedShortDate'
        : (isYesterday ? 'Ontem • $formattedShortDate' : formattedShortDate);

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Seletor rápido de data
                    EndoCareCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Dia anterior',
                            onPressed: () => _changeDate(
                              activeDate.subtract(const Duration(days: 1)),
                            ),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(activeDate),
                              borderRadius: AppSpacing.borderRadiusSm,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.event_note_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      dateTitle,
                                      style: textTheme.titleSmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Próximo dia',
                            onPressed: isToday
                                ? null
                                : () => _changeDate(
                                      activeDate.add(const Duration(days: 1)),
                                    ),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),

                    // Indicador de carregamento ou banner de reaproveitamento / salvo
                    if (bundleAsync.isLoading && bundle == null) ...[
                      const SizedBox(height: AppSpacing.md),
                      const LinearProgressIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryContainer,
                      ),
                    ] else if (bundle != null &&
                        bundle.isPrefilledFromPrevious &&
                        !_clearedPrefillManually) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _InfoStatusBanner(
                        icon: Icons.history_rounded,
                        backgroundColor: AppColors.secondaryContainer,
                        foregroundColor: AppColors.primary,
                        message:
                            'Valores preenchidos com base no seu registro anterior para agilizar.',
                        actionLabel: 'Zerar',
                        onAction: _resetToCleanDefaults,
                      ),
                    ] else if (bundle != null && bundle.isExistingForDate) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const _InfoStatusBanner(
                        icon: Icons.check_circle_outline_rounded,
                        backgroundColor: AppColors.successContainer,
                        foregroundColor: AppColors.success,
                        message:
                            'Registro já salvo neste dia. Altere o que quiser e toque em Salvar.',
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // 2. Intensidade da dor (0–10) com ilustração Storyset contextual
                    EndoCareCard(
                      elevated: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Como está sua dor?',
                                      style: textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Deslize de 0 (sem dor) até 10 (muito intensa).',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              StorysetIllustration(
                                asset: AppAssets.forPainIntensity(_pain),
                                height: 64,
                                width: 64,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          EndoCareSlider(
                            label: 'Intensidade geral',
                            value: _pain.toDouble(),
                            onChanged: (val) {
                              setState(() => _pain = val.round());
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 2b. Mapa corporal interativo (frente e costas + heatmap)
                    EndoCareCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const StorysetIllustration(
                                asset: AppAssets.femaleBodyShapesAmico,
                                height: 56,
                                width: 56,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mapa corporal (frente e costas)',
                                      style: textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _bodyMapEntries.isEmpty
                                          ? 'Toque para marcar a região exata da dor e consultar seu heatmap.'
                                          : '${_bodyMapEntries.length} ${_bodyMapEntries.length == 1 ? 'região marcada' : 'regiões marcadas'}: ${_bodyMapEntries.map((e) => '${e.regionLabel} (${e.intensidade}/10)').join(', ')}',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              EndoCareButton(
                                label: 'Abrir mapa corporal',
                                icon: Icons.accessibility_new_rounded,
                                variant: EndoCareButtonVariant.secondary,
                                onPressed: () => _openBodyMap(activeDate),
                              ),
                              EndoCareButton(
                                label: 'Ver heatmap',
                                icon: Icons.insights_rounded,
                                variant: EndoCareButtonVariant.text,
                                onPressed: () => _openBodyMap(
                                  activeDate,
                                  openInHeatmap: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 3. Chips rápidos de sintomas
                    EndoCareCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sintomas presentes',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Toque para marcar o que você sentiu.',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children:
                                SymptomCatalog.quickSymptoms.map((symptom) {
                              final selected = _quickSymptoms.contains(symptom);
                              return EndoCareChip(
                                label: symptom,
                                selected: selected,
                                onSelected: (next) {
                                  setState(() {
                                    if (next) {
                                      _quickSymptoms.add(symptom);
                                    } else {
                                      _quickSymptoms.remove(symptom);
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

                    // 4. Humor e qualidade do sono
                    EndoCareCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Humor hoje',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: SymptomCatalog.moods.map((option) {
                              final isSelected = _mood == option.label;
                              return EndoCareChip(
                                label: option.label,
                                icon: option.icon,
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _mood = isSelected ? null : option.label;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Qualidade do sono',
                                style: textTheme.titleMedium,
                              ),
                              Text(
                                '${SymptomCatalog.sleepQualityLabel(_sleep)} ($_sleep/10)',
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children:
                                SymptomCatalog.sleepPresets.map((preset) {
                              return EndoCareChip(
                                label: preset.label,
                                selected: _sleep == preset.score,
                                activeColor: AppColors.info,
                                onSelected: (_) {
                                  setState(() => _sleep = preset.score);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          EndoCareSlider(
                            value: _sleep.toDouble(),
                            usePainScaleColors: false,
                            minCaption: '0 • Muito ruim',
                            maxCaption: '10 • Reparador',
                            onChanged: (val) {
                              setState(() => _sleep = val.round());
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 5. Seção opcional recolhida por padrão
                    OptionalSymptomDetailsCard(
                      filledCount: _optionalFilledCount,
                      crampsScore: _cramps,
                      onCrampsChanged: (val) => setState(() => _cramps = val),
                      selectedRegions: _regions,
                      onToggleRegion: (region) {
                        setState(() {
                          if (_regions.contains(region)) {
                            _regions.remove(region);
                          } else {
                            _regions.add(region);
                          }
                        });
                      },
                      hasSexualPain: _hasSexualPain,
                      onSexualPainToggled: (enabled) {
                        setState(() => _hasSexualPain = enabled);
                      },
                      sexualPainLocation: _sexualPainLocation,
                      onSexualPainLocationSelected: (loc) {
                        setState(() => _sexualPainLocation = loc);
                      },
                      sexualPainScale: _sexualPainScale,
                      onSexualPainScaleChanged: (val) {
                        setState(() => _sexualPainScale = val);
                      },
                      selectedIntestinal: _intestinal,
                      onToggleIntestinal: (item) {
                        setState(() {
                          if (_intestinal.contains(item)) {
                            _intestinal.remove(item);
                          } else {
                            _intestinal.add(item);
                          }
                        });
                      },
                      selectedUrinary: _urinary,
                      onToggleUrinary: (item) {
                        setState(() {
                          if (_urinary.contains(item)) {
                            _urinary.remove(item);
                          } else {
                            _urinary.add(item);
                          }
                        });
                      },
                      fatigueScore: _fatigue,
                      onFatigueChanged: (val) => setState(() => _fatigue = val),
                      nauseaScore: _nausea,
                      onNauseaChanged: (val) => setState(() => _nausea = val),
                      bloatingScore: _bloating,
                      onBloatingChanged: (val) =>
                          setState(() => _bloating = val),
                      notesController: _notesController,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Barra inferior fixa com botão "Salvar" sempre visível
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.outline.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: EndoCareButton(
                  label: bundle?.isExistingForDate == true
                      ? 'Atualizar registro'
                      : 'Salvar registro',
                  icon: Icons.check_rounded,
                  isLoading: _isSaving,
                  isExpanded: true,
                  onPressed: () => _save(activeDate),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoStatusBanner extends StatelessWidget {
  const _InfoStatusBanner({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: foregroundColor,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                minimumSize: const Size(44, 32),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
