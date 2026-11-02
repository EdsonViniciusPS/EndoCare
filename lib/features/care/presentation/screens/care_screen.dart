import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/notifications/scheduled_reminder.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/time/clock_provider.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/appointments/presentation/widgets/appointment_form_sheet.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/calculators/presentation/screens/calculators_list_screen.dart';
import 'package:endocare/features/care/presentation/providers/care_providers.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';
import 'package:endocare/features/treatments/domain/models/treatment_effect.dart';
import 'package:endocare/features/treatments/presentation/widgets/treatment_effect_sheet.dart';
import 'package:endocare/features/treatments/presentation/widgets/treatment_form_sheet.dart';

enum _CareSection { treatments, appointments, calculators }

/// Aba 4 — Cuidar: gestão de medicamentos, horários, efeitos percebidos,
/// histórico de tratamentos, consultas, exames, procedimentos e lembretes (locais + FCM).
class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen>
    with WidgetsBindingObserver {
  _CareSection _section = _CareSection.treatments;
  ScheduledReminder? _lastFiredBanner;
  DateTime? _lastCheckedMoment;
  bool _syncingPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _checkDueRemindersNow();
    }
  }

  Future<void> _checkDueRemindersNow() async {
    final now = ref.read(homeClockProvider)();
    final prev = _lastCheckedMoment ?? now.subtract(const Duration(minutes: 1));
    _lastCheckedMoment = now;

    final treatments =
        ref.read(treatmentsStreamProvider).asData?.value ?? const <Treatment>[];
    final appointments =
        ref.read(appointmentsStreamProvider).asData?.value ??
        const <MedicalAppointment>[];

    await ref
        .read(reminderSchedulerProvider)
        .evaluateAndFireDue(
          treatments: treatments,
          appointments: appointments,
          previousCheck: prev,
          currentTime: now,
        );
  }

  String? _currentUid() {
    return ref.read(authStateChangesProvider).asData?.value?.uid ??
        ref.read(authRepositoryProvider).currentUser?.uid;
  }

  Future<void> _enableNotificationsAndPush() async {
    final uid = _currentUid();
    setState(() => _syncingPermissions = true);
    try {
      final fcmToken = await ref
          .read(reminderSchedulerProvider)
          .requestPermissionsAndSyncPush();
      if (uid != null && fcmToken != null && fcmToken.isNotEmpty) {
        await ref
            .read(userProfileRepositoryProvider)
            .addFcmToken(uid, fcmToken);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lembretes locais e canal push sincronizados.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncingPermissions = false);
      }
    }
  }

  Future<void> _openTreatmentForm({Treatment? existing}) async {
    final uid = _currentUid();
    if (uid == null) return;
    final now = ref.read(homeClockProvider)();

    final outcome = await TreatmentFormSheet.show(
      context: context,
      referenceDate: now,
      existing: existing,
    );
    if (outcome == null || !mounted) return;

    final repo = ref.read(treatmentRepositoryProvider);
    if (outcome.deleted && existing != null) {
      await repo.deleteTreatment(uid: uid, treatmentId: existing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tratamento removido.')));
    } else if (outcome.treatment != null) {
      await repo.saveTreatment(uid: uid, treatment: outcome.treatment!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tratamento salvo e lembretes atualizados.'),
        ),
      );
    }
  }

  Future<void> _archiveOrReactivateTreatment(
    Treatment treatment, {
    required bool nextActive,
  }) async {
    final uid = _currentUid();
    if (uid == null) return;
    final now = ref.read(homeClockProvider)();
    final updated = treatment.copyWith(
      ativo: nextActive,
      lembretesAtivos: nextActive ? treatment.lembretesAtivos : false,
      fim: nextActive ? null : now,
      clearFim: nextActive,
    );
    await ref
        .read(treatmentRepositoryProvider)
        .saveTreatment(uid: uid, treatment: updated);
  }

  Future<void> _openEffectSheet(Treatment treatment) async {
    final uid = _currentUid();
    if (uid == null) return;
    final now = ref.read(homeClockProvider)();

    final effect = await TreatmentEffectSheet.show(
      context: context,
      treatment: treatment,
      referenceDate: now,
    );
    if (effect == null || !mounted) return;

    await ref
        .read(treatmentRepositoryProvider)
        .saveEffect(uid: uid, effect: effect);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Efeito percebido registrado.')),
    );
  }

  Future<void> _deleteEffect(String effectId) async {
    final uid = _currentUid();
    if (uid == null) return;
    await ref
        .read(treatmentRepositoryProvider)
        .deleteEffect(uid: uid, effectId: effectId);
  }

  Future<void> _openAppointmentForm({
    MedicalAppointment? existing,
    AppointmentType initialType = AppointmentType.consultation,
  }) async {
    final uid = _currentUid();
    if (uid == null) return;
    final now = ref.read(homeClockProvider)();

    final outcome = await AppointmentFormSheet.show(
      context: context,
      referenceDate: now,
      existing: existing,
      initialType: initialType,
    );
    if (outcome == null || !mounted) return;

    final repo = ref.read(appointmentRepositoryProvider);
    if (outcome.deleted && existing != null) {
      await repo.deleteAppointment(uid: uid, appointmentId: existing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Agendamento removido.')));
    } else if (outcome.appointment != null) {
      await repo.saveAppointment(uid: uid, appointment: outcome.appointment!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento salvo com sucesso.')),
      );
    }
  }

  Future<void> _markAppointmentCompleted(MedicalAppointment item) async {
    final uid = _currentUid();
    if (uid == null) return;
    await ref
        .read(appointmentRepositoryProvider)
        .saveAppointment(
          uid: uid,
          appointment: item.copyWith(status: AppointmentStatus.completed),
        );
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime date) {
    try {
      return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(date);
    } catch (_) {
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return '${date.day}/${date.month}/${date.year} às $h:$m';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ScheduledReminder>>(firedRemindersStreamProvider, (
      _,
      next,
    ) {
      final reminder = next.asData?.value;
      if (reminder != null && mounted) {
        setState(() => _lastFiredBanner = reminder);
      }
    });

    final textTheme = Theme.of(context).textTheme;
    final treatments =
        ref.watch(treatmentsStreamProvider).asData?.value ??
        const <Treatment>[];
    final effects =
        ref.watch(treatmentEffectsStreamProvider).asData?.value ??
        const <TreatmentEffect>[];
    final appointments =
        ref.watch(appointmentsStreamProvider).asData?.value ??
        const <MedicalAppointment>[];
    final upcomingReminders = ref.watch(upcomingScheduledRemindersProvider);

    final activeTreatments = treatments
        .where((t) => t.ativo)
        .toList(growable: false);
    final historyTreatments = treatments
        .where((t) => !t.ativo)
        .toList(growable: false);

    final scheduledAppointments =
        appointments
            .where((a) => a.status == AppointmentStatus.scheduled)
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));
    final pastAppointments =
        appointments
            .where((a) => a.status != AppointmentStatus.scheduled)
            .toList()
          ..sort((a, b) => b.data.compareTo(a.data));

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
              // Banner de disparo ao vivo quando um lembrete atinge o horário configurado
              if (_lastFiredBanner != null) ...[
                _FiredReminderAlertCard(
                  reminder: _lastFiredBanner!,
                  onDismiss: () => setState(() => _lastFiredBanner = null),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Barra superior de status de lembretes locais + push FCM
              EndoCareCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                backgroundColor: AppColors.secondaryContainer,
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        upcomingReminders.isEmpty
                            ? 'Nenhum lembrete futuro ativo no momento.'
                            : '${upcomingReminders.length} ${upcomingReminders.length == 1 ? 'lembrete programado' : 'lembretes programados'} (local + push).',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _syncingPermissions
                          ? null
                          : _enableNotificationsAndPush,
                      child: const Text('Sincronizar alertas'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Alternador de seção: Medicamentos vs Consultas vs Calculadoras
              Row(
                children: [
                  Expanded(
                    child: _CareTabButton(
                      label: 'Medicamentos',
                      icon: Icons.medication_outlined,
                      selected: _section == _CareSection.treatments,
                      onTap: () =>
                          setState(() => _section = _CareSection.treatments),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _CareTabButton(
                      label: 'Consultas e exames',
                      icon: Icons.event_available_rounded,
                      selected: _section == _CareSection.appointments,
                      onTap: () =>
                          setState(() => _section = _CareSection.appointments),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _CareTabButton(
                      label: 'Calculadoras',
                      icon: Icons.calculate_outlined,
                      selected: _section == _CareSection.calculators,
                      onTap: () =>
                          setState(() => _section = _CareSection.calculators),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_section == _CareSection.treatments)
                _buildTreatmentsSection(
                  textTheme: textTheme,
                  activeTreatments: activeTreatments,
                  historyTreatments: historyTreatments,
                  effects: effects,
                )
              else if (_section == _CareSection.appointments)
                _buildAppointmentsSection(
                  textTheme: textTheme,
                  scheduledAppointments: scheduledAppointments,
                  pastAppointments: pastAppointments,
                )
              else
                const CalculatorsListView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentsSection({
    required TextTheme textTheme,
    required List<Treatment> activeTreatments,
    required List<Treatment> historyTreatments,
    required List<TreatmentEffect> effects,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card principal de cadastro de medicamentos
        EndoCareCard(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const StorysetIllustration(
                    asset: AppAssets.medicalPrescriptionAmico,
                    height: 68,
                    width: 68,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tratamentos e lembretes',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cadastre seus medicamentos contínuos ou de alívio, configure horários e anote efeitos percebidos.',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              EndoCareButton(
                label: 'Novo medicamento',
                icon: Icons.add_rounded,
                isExpanded: true,
                onPressed: () => _openTreatmentForm(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 1. Tratamentos ativos
        Text(
          'Em uso atualmente (${activeTreatments.length})',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (activeTreatments.isEmpty)
          EndoCareCard(
            backgroundColor: AppColors.surfaceSoft,
            child: Text(
              'Nenhum medicamento ativo cadastrado. Toque em "Novo medicamento" para configurar seus horários.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          )
        else
          ...activeTreatments.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: EndoCareCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.medicamento,
                                style: textTheme.titleMedium,
                              ),
                              Text(
                                [
                                  item.categoria.label,
                                  if (item.dose != null &&
                                      item.dose!.trim().isNotEmpty)
                                    item.dose!.trim(),
                                ].join(' • '),
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          item.lembretesAtivos
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_outlined,
                          size: 19,
                          color: item.lembretesAtivos
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ],
                    ),
                    if (item.horarios.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: 4,
                        children: item.horarios
                            .map(
                              (slot) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: AppSpacing.borderRadiusPill,
                                ),
                                child: Text(
                                  'Horário $slot',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        EndoCareButton(
                          label: 'Registrar efeito',
                          icon: Icons.rate_review_outlined,
                          variant: EndoCareButtonVariant.secondary,
                          onPressed: () => _openEffectSheet(item),
                        ),
                        EndoCareButton(
                          label: 'Editar',
                          icon: Icons.edit_outlined,
                          variant: EndoCareButtonVariant.text,
                          onPressed: () => _openTreatmentForm(existing: item),
                        ),
                        EndoCareButton(
                          label: 'Concluir',
                          icon: Icons.archive_outlined,
                          variant: EndoCareButtonVariant.text,
                          onPressed: () => _archiveOrReactivateTreatment(
                            item,
                            nextActive: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.lg),

        // 2. Efeitos percebidos
        Text(
          'Efeitos percebidos (${effects.length})',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (effects.isEmpty)
          EndoCareCard(
            backgroundColor: AppColors.surfaceSoft,
            child: Text(
              'Registre alívios ou efeitos adversos percebidos para levar um histórico fiel ao seu médico.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          )
        else
          ...effects.map((eff) {
            final badgeColor = switch (eff.tipo) {
              TreatmentEffectKind.relief => AppColors.success,
              TreatmentEffectKind.sideEffect => AppColors.warning,
              TreatmentEffectKind.observation => AppColors.info,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EndoCareCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        '${eff.intensidade}/10',
                        style: textTheme.labelMedium?.copyWith(
                          color: badgeColor,
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
                            '${eff.efeito} • ${eff.treatmentName}',
                            style: textTheme.titleSmall,
                          ),
                          Text(
                            '${eff.tipo.label} em ${_formatDate(eff.data)}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remover efeito',
                      onPressed: () => _deleteEffect(eff.id),
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

        const SizedBox(height: AppSpacing.lg),

        // 3. Histórico de tratamentos encerrados
        Text(
          'Histórico de tratamentos (${historyTreatments.length})',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (historyTreatments.isEmpty)
          EndoCareCard(
            backgroundColor: AppColors.surfaceSoft,
            child: Text(
              'Tratamentos concluídos ou substituídos ficam guardados aqui.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          )
        else
          ...historyTreatments.map(
            (past) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EndoCareCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(past.medicamento, style: textTheme.titleSmall),
                          Text(
                            '${_formatDate(past.inicio)} até ${past.fim != null ? _formatDate(past.fim!) : 'encerrado'}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _archiveOrReactivateTreatment(past, nextActive: true),
                      child: const Text('Reativar'),
                    ),
                    IconButton(
                      tooltip: 'Editar histórico',
                      onPressed: () => _openTreatmentForm(existing: past),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentsSection({
    required TextTheme textTheme,
    required List<MedicalAppointment> scheduledAppointments,
    required List<MedicalAppointment> pastAppointments,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EndoCareCard(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const StorysetIllustration(
                    asset: AppAssets.calendarBro,
                    height: 68,
                    width: 68,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultas, exames e procedimentos',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Agende seus compromissos com lembretes antecipados e mantenha o histórico cirúrgico e clínico organizado.',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  EndoCareButton(
                    label: 'Agendar consulta / exame',
                    icon: Icons.event_available_rounded,
                    onPressed: () => _openAppointmentForm(
                      initialType: AppointmentType.consultation,
                    ),
                  ),
                  EndoCareButton(
                    label: 'Registrar procedimento',
                    icon: Icons.medical_services_outlined,
                    variant: EndoCareButtonVariant.secondary,
                    onPressed: () => _openAppointmentForm(
                      initialType: AppointmentType.procedure,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          'Próximos agendamentos (${scheduledAppointments.length})',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (scheduledAppointments.isEmpty)
          EndoCareCard(
            backgroundColor: AppColors.surfaceSoft,
            child: Text(
              'Nenhuma consulta, exame ou procedimento agendado no momento.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          )
        else
          ...scheduledAppointments.map(
            (appt) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: EndoCareCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.tertiaryContainer,
                            borderRadius: AppSpacing.borderRadiusPill,
                          ),
                          child: Text(
                            appt.tipo.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Lembrete: ${appt.reminderLead.label}',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(appt.titulo, style: textTheme.titleMedium),
                    Text(
                      [
                        _formatDateTime(appt.data),
                        if (appt.local != null && appt.local!.trim().isNotEmpty)
                          appt.local!.trim(),
                        if (appt.profissional != null &&
                            appt.profissional!.trim().isNotEmpty)
                          appt.profissional!.trim(),
                      ].join(' • '),
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        EndoCareButton(
                          label: 'Marcar realizado',
                          icon: Icons.check_circle_outline_rounded,
                          variant: EndoCareButtonVariant.secondary,
                          onPressed: () => _markAppointmentCompleted(appt),
                        ),
                        EndoCareButton(
                          label: 'Editar',
                          icon: Icons.edit_outlined,
                          variant: EndoCareButtonVariant.text,
                          onPressed: () => _openAppointmentForm(existing: appt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.lg),

        Text(
          'Histórico clínico e procedimentos (${pastAppointments.length})',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (pastAppointments.isEmpty)
          EndoCareCard(
            backgroundColor: AppColors.surfaceSoft,
            child: Text(
              'Consultas, exames e cirurgias realizados aparecem aqui em ordem cronológica.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          )
        else
          ...pastAppointments.map(
            (past) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EndoCareCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${past.tipo.label}: ${past.titulo}',
                            style: textTheme.titleSmall,
                          ),
                          Text(
                            '${past.status.label} em ${_formatDateTime(past.data)}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar registro',
                      onPressed: () => _openAppointmentForm(existing: past),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CareTabButton extends StatelessWidget {
  const _CareTabButton({
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
      color: selected ? AppColors.primaryContainer : AppColors.surface,
      borderRadius: AppSpacing.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm + 2,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
            ),
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
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
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

class _FiredReminderAlertCard extends StatelessWidget {
  const _FiredReminderAlertCard({
    required this.reminder,
    required this.onDismiss,
  });

  final ScheduledReminder reminder;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return EndoCareCard(
      elevated: true,
      backgroundColor: AppColors.primaryContainer,
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(
            Icons.alarm_on_rounded,
            color: AppColors.primaryDark,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  reminder.body,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar alerta',
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
