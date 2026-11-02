import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/firebase/firebase_providers.dart';
import 'package:endocare/core/notifications/reminder_scheduler.dart';
import 'package:endocare/core/notifications/scheduled_reminder.dart';
import 'package:endocare/core/time/clock_provider.dart';
import 'package:endocare/features/appointments/data/repositories/firestore_appointment_repository.dart';
import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/home/domain/models/home_summary_data.dart';
import 'package:endocare/features/treatments/data/repositories/firestore_treatment_repository.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';
import 'package:endocare/features/treatments/domain/models/treatment_effect.dart';
import 'package:endocare/features/treatments/domain/repositories/treatment_repository.dart';

/// Provider do repositório de medicamentos e efeitos percebidos.
final treatmentRepositoryProvider = Provider<TreatmentRepository>((ref) {
  return FirestoreTreatmentRepository(ref.watch(firestoreProvider));
});

/// Provider do repositório de consultas, exames e procedimentos.
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return FirestoreAppointmentRepository(ref.watch(firestoreProvider));
});

/// Provider do serviço unificado de lembretes locais + registro push FCM.
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final fcmService = ref.watch(fcmTokenServiceProvider);
  final scheduler = LocalAndPushReminderScheduler(fcmTokenService: fcmService);
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

/// Stream em tempo real dos tratamentos da usuária autenticada.
final treatmentsStreamProvider = StreamProvider<List<Treatment>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream<List<Treatment>>.value(const []);
  }
  return ref
      .watch(treatmentRepositoryProvider)
      .watchTreatments(uid: authUser.uid);
});

/// Stream em tempo real dos efeitos percebidos de tratamentos.
final treatmentEffectsStreamProvider =
    StreamProvider<List<TreatmentEffect>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream<List<TreatmentEffect>>.value(const []);
  }
  return ref
      .watch(treatmentRepositoryProvider)
      .watchEffects(uid: authUser.uid);
});

/// Stream em tempo real das consultas, exames e procedimentos da usuária.
final appointmentsStreamProvider =
    StreamProvider<List<MedicalAppointment>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream<List<MedicalAppointment>>.value(const []);
  }
  return ref
      .watch(appointmentRepositoryProvider)
      .watchAppointments(uid: authUser.uid);
});

/// Stream de lembretes que dispararam no horário configurado.
final firedRemindersStreamProvider = StreamProvider<ScheduledReminder>((ref) {
  return ref.watch(reminderSchedulerProvider).onReminderFired;
});

/// Fila ordenada dos próximos lembretes agendados a partir do relógio atual,
/// mantendo o agendador local (`ReminderScheduler`) sincronizado automaticamente.
final upcomingScheduledRemindersProvider =
    Provider<List<ScheduledReminder>>((ref) {
  final now = ref.watch(homeClockProvider)();
  final treatments = ref.watch(treatmentsStreamProvider).asData?.value ??
      const <Treatment>[];
  final appointments = ref.watch(appointmentsStreamProvider).asData?.value ??
      const <MedicalAppointment>[];

  final scheduler = ref.watch(reminderSchedulerProvider);
  // Reconcilia de forma assíncrona os lembretes locais do SO sempre que
  // medicamentos ativos, horários ou consultas mudarem.
  Future<void>.microtask(
    () => scheduler.syncAllSchedules(
      treatments: treatments,
      appointments: appointments,
      now: now,
    ),
  );

  return ReminderScheduleEngine.buildUpcoming(
    treatments: treatments,
    appointments: appointments,
    now: now,
  );
});

/// Converte os próximos lembretes agendados em cartões de prévia para a tela Início.
final homeUpcomingReminderPreviewsProvider =
    Provider<List<HomeReminderPreview>>((ref) {
  final upcoming = ref.watch(upcomingScheduledRemindersProvider);
  if (upcoming.isEmpty) return const [];

  return upcoming.take(4).map((reminder) {
    String whenLabel;
    try {
      whenLabel =
          DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(reminder.scheduledAt);
    } catch (_) {
      final h = reminder.scheduledAt.hour.toString().padLeft(2, '0');
      final m = reminder.scheduledAt.minute.toString().padLeft(2, '0');
      whenLabel =
          '${reminder.scheduledAt.day}/${reminder.scheduledAt.month} às $h:$m';
    }

    return HomeReminderPreview(
      title: reminder.title,
      subtitle: '$whenLabel • ${reminder.body}',
    );
  }).toList(growable: false);
});

