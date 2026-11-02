import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/core/widgets/endocare_chip.dart';
import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';

/// Resultado do formulário modal de consulta, exame ou procedimento.
class AppointmentFormOutcome {
  const AppointmentFormOutcome.saved(this.appointment) : deleted = false;
  const AppointmentFormOutcome.deleted()
      : appointment = null,
        deleted = true;

  final MedicalAppointment? appointment;
  final bool deleted;
}

/// Folha modal para agendar ou registrar consultas, exames e procedimentos/cirurgias.
class AppointmentFormSheet extends StatefulWidget {
  const AppointmentFormSheet({
    super.key,
    required this.referenceDate,
    this.existing,
    this.initialType = AppointmentType.consultation,
  });

  final DateTime referenceDate;
  final MedicalAppointment? existing;
  final AppointmentType initialType;

  static Future<AppointmentFormOutcome?> show({
    required BuildContext context,
    required DateTime referenceDate,
    MedicalAppointment? existing,
    AppointmentType initialType = AppointmentType.consultation,
  }) {
    return showModalBottomSheet<AppointmentFormOutcome>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => AppointmentFormSheet(
        referenceDate: referenceDate,
        existing: existing,
        initialType: initialType,
      ),
    );
  }

  @override
  State<AppointmentFormSheet> createState() => _AppointmentFormSheetState();
}

class _AppointmentFormSheetState extends State<AppointmentFormSheet> {
  static const List<String> _presetTimes = [
    '08:00',
    '10:00',
    '14:00',
    '16:00',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _professionalController;
  late final TextEditingController _notesController;

  late AppointmentType _type;
  late DateTime _selectedDay;
  late String _timeSlot;
  late AppointmentStatus _status;
  late AppointmentReminderLead _reminderLead;

  @override
  void initState() {
    super.initState();
    final initial = widget.existing;
    _type = initial?.tipo ?? widget.initialType;
    _titleController = TextEditingController(text: initial?.titulo ?? '');
    _locationController = TextEditingController(text: initial?.local ?? '');
    _professionalController =
        TextEditingController(text: initial?.profissional ?? '');
    _notesController = TextEditingController(text: initial?.notas ?? '');

    final baseDate = initial?.data ??
        widget.referenceDate.add(const Duration(days: 3));
    _selectedDay = SymptomLog.normalizeDate(baseDate);
    _timeSlot = initial != null
        ? Treatment.formatTimeSlot(initial.data.hour, initial.data.minute)
        : '14:00';
    _status = initial?.status ?? AppointmentStatus.scheduled;
    _reminderLead =
        initial?.reminderLead ?? AppointmentReminderLead.oneHourBefore;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _professionalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> _titleSuggestionsFor(AppointmentType type) {
    return switch (type) {
      AppointmentType.consultation => const [
          'Ginecologista especialista',
          'Fisioterapia pélvica',
          'Nutrição / Psicologia',
        ],
      AppointmentType.exam => const [
          'Ultrassom com preparo intestinal',
          'Ressonância magnética pélvica',
          'Exames laboratoriais',
        ],
      AppointmentType.procedure => const [
          'Videolaparoscopia',
          'Inserção de DIU hormonal',
          'Biópsia / Procedimento ambulatorial',
        ],
    };
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(widget.referenceDate.year - 10),
      lastDate: DateTime(widget.referenceDate.year + 3),
      helpText: 'Escolher data',
    );
    if (picked != null && mounted) {
      setState(() => _selectedDay = SymptomLog.normalizeDate(picked));
    }
  }

  Future<void> _pickCustomTime() async {
    final parsed = Treatment.tryParseTimeSlot(_timeSlot);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: parsed?.hour ?? 14,
        minute: parsed?.minute ?? 0,
      ),
      helpText: 'Escolher horário',
    );
    if (picked != null && mounted) {
      setState(() {
        _timeSlot = Treatment.formatTimeSlot(picked.hour, picked.minute);
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final parsedTime =
        Treatment.tryParseTimeSlot(_timeSlot) ?? (hour: 14, minute: 0);
    final fullDateTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      parsedTime.hour,
      parsedTime.minute,
    );

    final appointment = MedicalAppointment(
      id: widget.existing?.id ?? '',
      tipo: _type,
      titulo: _titleController.text.trim(),
      data: fullDateTime,
      local: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      profissional: _professionalController.text.trim().isNotEmpty
          ? _professionalController.text.trim()
          : null,
      notas: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      status: _status,
      lembreteAntecedenciaMinutos: _reminderLead.minutes,
    );

    Navigator.of(context).pop(AppointmentFormOutcome.saved(appointment));
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
    final suggestions = _titleSuggestionsFor(_type);
    final timeOptions = <String>{
      ..._presetTimes,
      _timeSlot,
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
                      ? 'Editar ${_type.label.toLowerCase()}'
                      : 'Agendar consulta, exame ou procedimento',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Tipo', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: AppointmentType.values.map((t) {
                    return EndoCareChip(
                      label: t.label,
                      selected: _type == t,
                      activeColor: AppColors.tertiary,
                      onSelected: (_) => setState(() => _type = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: suggestions.map((s) {
                    return EndoCareChip(
                      label: s,
                      selected: _titleController.text.trim() == s,
                      onSelected: (_) =>
                          setState(() => _titleController.text = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.sm),

                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título ou especialidade',
                    hintText: 'Ex.: Ginecologista especialista em endometriose',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Informe o título da consulta, exame ou procedimento.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Data e horário
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 17),
                        label: Text('Data: ${_formatDate(_selectedDay)}'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: _pickCustomTime,
                      icon: const Icon(Icons.more_time_rounded, size: 18),
                      label: const Text('Outro horário'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: timeOptions.map((slot) {
                    return EndoCareChip(
                      label: slot,
                      icon: Icons.schedule_rounded,
                      selected: _timeSlot == slot,
                      onSelected: (_) => setState(() => _timeSlot = slot),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Local ou clínica (opcional)',
                    hintText: 'Ex.: Clínica Mulher / Teleconsulta',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _professionalController,
                  decoration: const InputDecoration(
                    labelText: 'Profissional (opcional)',
                    hintText: 'Ex.: Dra. Camila Rocha',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Lembrete', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: AppointmentReminderLead.values.map((lead) {
                    return EndoCareChip(
                      label: lead.label,
                      selected: _reminderLead == lead,
                      activeColor: AppColors.info,
                      onSelected: (_) => setState(() => _reminderLead = lead),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Status', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: AppointmentStatus.values.map((st) {
                    return EndoCareChip(
                      label: st.label,
                      selected: _status == st,
                      onSelected: (_) => setState(() => _status = st),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Preparo ou observações (opcional)',
                    hintText: 'Ex.: Levar exames anteriores, jejum de 6h...',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                EndoCareButton(
                  label: 'Salvar agendamento',
                  icon: Icons.check_rounded,
                  isExpanded: true,
                  onPressed: _submit,
                ),
                if (widget.existing != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  EndoCareButton(
                    label: 'Excluir agendamento',
                    icon: Icons.delete_outline_rounded,
                    variant: EndoCareButtonVariant.text,
                    isExpanded: true,
                    onPressed: () {
                      Navigator.of(context)
                          .pop(const AppointmentFormOutcome.deleted());
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

