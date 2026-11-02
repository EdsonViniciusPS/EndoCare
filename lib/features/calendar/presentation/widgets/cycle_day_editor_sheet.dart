import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/core/widgets/endocare_chip.dart';
import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Resultado da folha de edição de um dia do calendário menstrual.
class CycleDayEditorOutcome {
  const CycleDayEditorOutcome.saved(this.entry) : cleared = false;
  const CycleDayEditorOutcome.cleared()
      : entry = null,
        cleared = true;

  final CycleEntry? entry;
  final bool cleared;
}

/// Folha modal acolhedora para registrar fluxo menstrual, ovulação observada,
/// crise de sintomas, medicamentos do dia, consulta/exame e observações.
class CycleDayEditorSheet extends StatefulWidget {
  const CycleDayEditorSheet({
    super.key,
    required this.date,
    this.existingEntry,
  });

  final DateTime date;
  final CycleEntry? existingEntry;

  static Future<CycleDayEditorOutcome?> show({
    required BuildContext context,
    required DateTime date,
    CycleEntry? existingEntry,
  }) {
    return showModalBottomSheet<CycleDayEditorOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => CycleDayEditorSheet(
        date: date,
        existingEntry: existingEntry,
      ),
    );
  }

  @override
  State<CycleDayEditorSheet> createState() => _CycleDayEditorSheetState();
}

class _CycleDayEditorSheetState extends State<CycleDayEditorSheet> {
  MenstrualFlowLevel? _flow;
  bool _crisis = false;
  bool _observedOvulation = false;
  final Set<String> _medications = {};
  String? _selectedAppointment;
  final TextEditingController _customMedController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEntry;
    if (existing != null) {
      _flow = existing.fluxo;
      _crisis = existing.crise;
      _observedOvulation = existing.ovulacaoObservada;
      _medications.addAll(existing.medicamentos);
      _selectedAppointment = existing.consultaOuExame;
      _notesController.text = existing.observacoes ?? '';
    }
  }

  @override
  void dispose() {
    _customMedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addCustomMedication() {
    final text = _customMedController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _medications.add(text);
      _customMedController.clear();
    });
  }

  void _save() {
    if (_customMedController.text.trim().isNotEmpty) {
      _medications.add(_customMedController.text.trim());
    }
    final normalized = SymptomLog.normalizeDate(widget.date);
    final entry = CycleEntry(
      id: SymptomLog.dateKeyFor(normalized),
      data: normalized,
      fluxo: _flow,
      ovulacaoObservada: _observedOvulation,
      crise: _crisis,
      medicamentos: _medications.toList(growable: false),
      consultaOuExame: _selectedAppointment?.trim().isNotEmpty == true
          ? _selectedAppointment!.trim()
          : null,
      observacoes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );
    Navigator.of(context).pop(CycleDayEditorOutcome.saved(entry));
  }

  void _clear() {
    Navigator.of(context).pop(const CycleDayEditorOutcome.cleared());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    String formattedDate;
    try {
      formattedDate = DateFormat("d 'de' MMMM", 'pt_BR').format(widget.date);
    } catch (_) {
      formattedDate =
          '${widget.date.day}/${widget.date.month}/${widget.date.year}';
    }

    final allMedicationChips = <String>{
      ...CycleCatalog.commonMedications,
      ..._medications,
    }.toList(growable: false);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.84,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl + MediaQuery.of(context).viewInsets.bottom,
          ),
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
                'Ciclo e cuidados • $formattedDate',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Marque menstruação, sinais do ciclo, crises, medicamentos ou consultas deste dia.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 1. Menstruação e fluxo
              Text('Menstruação e fluxo', style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  EndoCareChip(
                    label: 'Sem fluxo',
                    selected: _flow == null,
                    onSelected: (_) => setState(() => _flow = null),
                  ),
                  ...MenstrualFlowLevel.values.map((level) {
                    return EndoCareChip(
                      label: level.label,
                      icon: Icons.water_drop_outlined,
                      selected: _flow == level,
                      activeColor: AppColors.cycleMenstruation,
                      onSelected: (_) {
                        setState(() {
                          _flow = _flow == level ? null : level;
                        });
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Crises e ovulação observada
              Text('Eventos do ciclo e crises', style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  EndoCareChip(
                    label: 'Crise de sintomas',
                    icon: Icons.bolt_rounded,
                    selected: _crisis,
                    activeColor: AppColors.painSevere,
                    onSelected: (next) => setState(() => _crisis = next),
                  ),
                  EndoCareChip(
                    label: 'Sinais de ovulação',
                    icon: Icons.auto_awesome_rounded,
                    selected: _observedOvulation,
                    activeColor: AppColors.cycleOvulation,
                    onSelected: (next) =>
                        setState(() => _observedOvulation = next),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Medicamentos utilizados no dia
              Text('Medicamentos ou medidas de alívio',
                  style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: allMedicationChips.map((med) {
                  final selected = _medications.contains(med);
                  return EndoCareChip(
                    label: med,
                    icon: Icons.medication_outlined,
                    selected: selected,
                    activeColor: AppColors.success,
                    onSelected: (next) {
                      setState(() {
                        if (next) {
                          _medications.add(med);
                        } else {
                          _medications.remove(med);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customMedController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addCustomMedication(),
                      decoration: const InputDecoration(
                        hintText: 'Adicionar outro medicamento...',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Adicionar medicamento',
                    onPressed: _addCustomMedication,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Consultas e exames no dia
              Text('Consulta ou exame neste dia', style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: CycleCatalog.commonAppointments.map((appt) {
                  final selected = _selectedAppointment == appt;
                  return EndoCareChip(
                    label: appt,
                    icon: Icons.event_available_rounded,
                    selected: selected,
                    activeColor: AppColors.tertiary,
                    onSelected: (_) {
                      setState(() {
                        _selectedAppointment = selected ? null : appt;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Observações
              Text('Observações do dia', style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _notesController,
                maxLines: 2,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Anotações opcionais sobre o ciclo ou sintomas...',
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              EndoCareButton(
                label: 'Salvar no calendário',
                icon: Icons.check_rounded,
                isExpanded: true,
                onPressed: _save,
              ),
              if (widget.existingEntry != null &&
                  !widget.existingEntry!.isEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                EndoCareButton(
                  label: 'Limpar registro do ciclo',
                  icon: Icons.delete_outline_rounded,
                  variant: EndoCareButtonVariant.text,
                  isExpanded: true,
                  onPressed: _clear,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

