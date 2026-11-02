import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/core/widgets/endocare_chip.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';

/// Resultado retornado pelo formulário modal de tratamento/medicamento.
class TreatmentFormOutcome {
  const TreatmentFormOutcome.saved(this.treatment) : deleted = false;
  const TreatmentFormOutcome.deleted()
      : treatment = null,
        deleted = true;

  final Treatment? treatment;
  final bool deleted;
}

/// Folha modal completa para criar, editar ou remover medicamentos e tratamentos.
class TreatmentFormSheet extends StatefulWidget {
  const TreatmentFormSheet({
    super.key,
    required this.referenceDate,
    this.existing,
  });

  final DateTime referenceDate;
  final Treatment? existing;

  static Future<TreatmentFormOutcome?> show({
    required BuildContext context,
    required DateTime referenceDate,
    Treatment? existing,
  }) {
    return showModalBottomSheet<TreatmentFormOutcome>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => TreatmentFormSheet(
        referenceDate: referenceDate,
        existing: existing,
      ),
    );
  }

  @override
  State<TreatmentFormSheet> createState() => _TreatmentFormSheetState();
}

class _TreatmentFormSheetState extends State<TreatmentFormSheet> {
  static const List<String> _presetSlots = [
    '08:00',
    '12:00',
    '14:00',
    '20:00',
    '22:00',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _notesController;

  late TreatmentCategory _category;
  late Set<String> _timeSlots;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _isActive;
  late bool _remindersEnabled;

  @override
  void initState() {
    super.initState();
    final initial = widget.existing;
    _nameController = TextEditingController(text: initial?.medicamento ?? '');
    _doseController = TextEditingController(text: initial?.dose ?? '');
    _notesController = TextEditingController(text: initial?.notas ?? '');
    _category = initial?.categoria ?? TreatmentCategory.hormonal;
    _timeSlots = <String>{
      ...(initial?.horarios ?? const ['08:00']),
    };
    _startDate = SymptomLog.normalizeDate(
      initial?.inicio ?? widget.referenceDate,
    );
    _endDate = initial?.fim;
    _isActive = initial?.ativo ?? true;
    _remindersEnabled = initial?.lembretesAtivos ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Escolher horário do lembrete',
    );
    if (picked != null && mounted) {
      setState(() {
        _timeSlots.add(Treatment.formatTimeSlot(picked.hour, picked.minute));
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(widget.referenceDate.year - 10),
      lastDate: DateTime(widget.referenceDate.year + 2),
      helpText: 'Data de início do tratamento',
    );
    if (picked != null && mounted) {
      setState(() => _startDate = SymptomLog.normalizeDate(picked));
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final resolvedEnd = !_isActive
        ? (_endDate ?? SymptomLog.normalizeDate(widget.referenceDate))
        : _endDate;

    final treatment = Treatment(
      id: widget.existing?.id ?? '',
      medicamento: _nameController.text.trim(),
      categoria: _category,
      dose: _doseController.text.trim().isNotEmpty
          ? _doseController.text.trim()
          : null,
      horarios: Treatment.normalizeTimeSlots(_timeSlots),
      inicio: _startDate,
      fim: resolvedEnd,
      ativo: _isActive,
      lembretesAtivos: _isActive && _remindersEnabled,
      notas: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    Navigator.of(context).pop(TreatmentFormOutcome.saved(treatment));
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final allSlotOptions = <String>{
      ..._presetSlots,
      ..._timeSlots,
    }.toList()
      ..sort();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.existing != null
                      ? 'Editar tratamento'
                      : 'Novo medicamento ou cuidado',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Medicamento ou tratamento',
                    hintText: 'Ex.: Dienogeste, Ibuprofeno, Fisioterapia...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Informe o nome do medicamento ou cuidado.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Categoria', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: TreatmentCategory.values.map((cat) {
                    return EndoCareChip(
                      label: cat.label,
                      selected: _category == cat,
                      onSelected: (_) => setState(() => _category = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _doseController,
                  decoration: const InputDecoration(
                    labelText: 'Dose / posologia (opcional)',
                    hintText: 'Ex.: 2 mg • 1 comprimido ao dia',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Horários dos lembretes', style: textTheme.titleSmall),
                    TextButton.icon(
                      onPressed: _pickCustomTime,
                      icon: const Icon(Icons.more_time_rounded, size: 18),
                      label: const Text('Outro horário'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: allSlotOptions.map((slot) {
                    final selected = _timeSlots.contains(slot);
                    return EndoCareChip(
                      label: slot,
                      icon: Icons.access_time_rounded,
                      selected: selected,
                      activeColor: AppColors.primary,
                      onSelected: (next) {
                        setState(() {
                          if (next) {
                            _timeSlots.add(slot);
                          } else {
                            _timeSlots.remove(slot);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.sm),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primaryContainer,
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    'Disparar lembretes nos horários acima',
                    style: textTheme.bodyMedium,
                  ),
                  value: _remindersEnabled && _isActive,
                  onChanged: _isActive
                      ? (val) => setState(() => _remindersEnabled = val)
                      : null,
                ),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.successContainer,
                  activeThumbColor: AppColors.success,
                  title: Text(
                    'Em uso atualmente',
                    style: textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    _isActive
                        ? 'Início em ${_formatDate(_startDate)}'
                        : 'Movido para o histórico de tratamentos',
                    style: textTheme.bodySmall,
                  ),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.event_rounded, size: 18),
                    label: Text('Alterar data de início (${_formatDate(_startDate)})'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    hintText: 'Ex.: Tomar após o jantar, orientação médica...',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                EndoCareButton(
                  label: 'Salvar tratamento',
                  icon: Icons.check_rounded,
                  isExpanded: true,
                  onPressed: _submit,
                ),
                if (widget.existing != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  EndoCareButton(
                    label: 'Excluir tratamento',
                    icon: Icons.delete_outline_rounded,
                    variant: EndoCareButtonVariant.text,
                    isExpanded: true,
                    onPressed: () {
                      Navigator.of(context)
                          .pop(const TreatmentFormOutcome.deleted());
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );
  }
}

