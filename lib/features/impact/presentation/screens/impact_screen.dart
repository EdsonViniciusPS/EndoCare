import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/home/presentation/providers/home_providers.dart';
import 'package:endocare/features/impact/domain/models/impact_log.dart';
import 'package:endocare/features/impact/presentation/providers/impact_providers.dart';
import 'package:endocare/features/impact/presentation/widgets/impact_area_slider_card.dart';
import 'package:endocare/features/impact/presentation/widgets/impact_summary_card.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Tela do Diário de impacto na qualidade de vida (seções 4.3, 5.1 e 7 do EndoCare.md).
///
/// Permite avaliar de 0 a 10 como a dor impactou 6 áreas da vida:
/// trabalho, estudos, sono, exercícios, relacionamentos e rotina.
class ImpactScreen extends ConsumerStatefulWidget {
  const ImpactScreen({
    super.key,
    this.initialDate,
  });

  final DateTime? initialDate;

  @override
  ConsumerState<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends ConsumerState<ImpactScreen> {
  late DateTime _selectedDate;
  final TextEditingController _notesController = TextEditingController();
  Map<ImpactArea, int> _levels = {};
  bool _isSaving = false;
  String? _loadedForDateKey;

  @override
  void initState() {
    super.initState();
    _selectedDate = SymptomLog.normalizeDate(
      widget.initialDate ?? DateTime.now(),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _syncFromSaved(ImpactLog? log) {
    final currentKey = SymptomLog.dateKeyFor(_selectedDate);
    if (_loadedForDateKey == currentKey) return;
    _loadedForDateKey = currentKey;

    if (log != null) {
      _levels = Map<ImpactArea, int>.from(log.niveis);
      _notesController.text = log.notas ?? '';
    } else {
      _levels = {};
      _notesController.clear();
    }
  }

  Future<void> _pickDate() async {
    final now = ref.read(homeClockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = SymptomLog.normalizeDate(picked);
        _loadedForDateKey = null; // força sincronização com os dados do dia
      });
    }
  }

  void _stepDay(int deltaDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: deltaDays));
      _loadedForDateKey = null;
    });
  }

  Future<void> _saveLog() async {
    final authUser = ref.read(authStateChangesProvider).asData?.value;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login para salvar seus registros.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final log = ImpactLog(
        id: SymptomLog.dateKeyFor(_selectedDate),
        data: _selectedDate,
        niveis: Map.unmodifiable(_levels),
        notas: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref
          .read(impactLogRepositoryProvider)
          .saveLog(uid: authUser.uid, log: log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro de impacto salvo com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar registro: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteCurrentLog() async {
    final authUser = ref.read(authStateChangesProvider).asData?.value;
    if (authUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir registro deste dia?'),
        content: const Text(
          'Deseja apagar a avaliação de impacto para esta data? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(impactLogRepositoryProvider)
          .deleteLog(uid: authUser.uid, date: _selectedDate);

      setState(() {
        _levels.clear();
        _notesController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro de impacto excluído.'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir registro: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = ref.watch(homeClockProvider)();
    final today = SymptomLog.normalizeDate(now);
    final allLogs = ref.watch(impactLogsStreamProvider).asData?.value ??
        const <ImpactLog>[];

    // Localiza registro existente para a data selecionada
    final dateKey = SymptomLog.dateKeyFor(_selectedDate);
    final existingLog = allLogs.where((l) => l.id == dateKey).firstOrNull;

    // Sincroniza estado inicial do formulário ao abrir ou trocar dia
    _syncFromSaved(existingLog);

    final summary = ImpactSummary.aggregate(
      logs: allLogs,
      referenceDate: _selectedDate,
      periodDays: 30,
    );

    final isToday = _selectedDate == today;
    final formattedDate = DateFormat("EEEE, d 'de' MMMM", 'pt_BR')
        .format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário de impacto'),
        actions: [
          IconButton(
            tooltip: 'Linha do tempo',
            icon: const Icon(Icons.timeline_rounded),
            onPressed: () => context.push(AppRoutes.timeline),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Navegação de data
                EndoCareCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: 'Dia anterior',
                        onPressed: () => _stepDay(-1),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          onTap: _pickDate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                              horizontal: AppSpacing.sm,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isToday ? 'Hoje' : formattedDate,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isToday)
                                  Text(
                                    formattedDate,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: 'Próximo dia',
                        onPressed: () => _stepDay(1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month_outlined),
                        tooltip: 'Escolher data',
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Resumo consolidado dos últimos 30 dias
                ImpactSummaryCard(summary: summary),
                const SizedBox(height: AppSpacing.md),

                // 3. Orientação amigável
                EndoCareCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Classifique de 0 a 10 como a dor impactou suas atividades neste dia. Deixe em branco as que não se aplicam.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Cards para as 6 áreas de impacto
                ...ImpactArea.values.map((area) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ImpactAreaSliderCard(
                      area: area,
                      value: _levels[area],
                      onChanged: (nextVal) {
                        setState(() {
                          if (nextVal == null) {
                            _levels.remove(area);
                          } else {
                            _levels[area] = nextVal;
                          }
                        });
                      },
                    ),
                  );
                }),

                // 5. Observações adicionais
                EndoCareCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Notas e observações',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          hintText:
                              'Ex.: precisei adiar reuniões; não consegui caminhar à tarde...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 6. Botão salvar e excluir
                EndoCareButton(
                  label: _isSaving
                      ? 'Salvando...'
                      : (existingLog != null
                          ? 'Atualizar registro'
                          : 'Salvar registro'),
                  icon: Icons.check_circle_outline_rounded,
                  isExpanded: true,
                  onPressed: _isSaving ? null : _saveLog,
                ),

                if (existingLog != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  EndoCareButton(
                    label: 'Excluir registro deste dia',
                    icon: Icons.delete_outline_rounded,
                    variant: EndoCareButtonVariant.outlined,
                    isExpanded: true,
                    onPressed: _isSaving ? null : _deleteCurrentLog,
                  ),
                ],

                const SizedBox(height: AppSpacing.md),
                EndoCareButton(
                  label: 'Ver na linha do tempo',
                  icon: Icons.timeline_rounded,
                  variant: EndoCareButtonVariant.tonal,
                  isExpanded: true,
                  onPressed: () => context.push(AppRoutes.timeline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
