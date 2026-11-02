import 'package:intl/intl.dart';
import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';

/// Categoria de lembrete agendado (medicamento diário ou consulta/exame/procedimento).
enum ReminderKind {
  medication('medicamento', 'Medicamento'),
  appointment('consulta', 'Agendamento');

  const ReminderKind(this.code, this.label);

  final String code;
  final String label;
}

/// Representação canônica de um lembrete agendado (local + metadados push).
class ScheduledReminder {
  const ScheduledReminder({
    required this.notificationId,
    required this.sourceId,
    required this.kind,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.repeatsDaily,
    required this.slotKey,
  });

  final int notificationId;
  final String sourceId;
  final ReminderKind kind;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final bool repeatsDaily;
  final String slotKey;

  /// Gera ID inteiro positivo determinístico (31 bits) para o SO / `flutter_local_notifications`.
  static int deterministicId(
    ReminderKind kind,
    String sourceId,
    String slotKey,
  ) {
    final key = '${kind.code}:$sourceId:$slotKey';
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}

/// Motor determinístico de cálculo e disparo de lembretes nos horários configurados.
abstract final class ReminderScheduleEngine {
  /// Constrói a fila ordenada dos próximos lembretes ativos a partir de `now`.
  static List<ScheduledReminder> buildUpcoming({
    required Iterable<Treatment> treatments,
    required Iterable<MedicalAppointment> appointments,
    required DateTime now,
  }) {
    final items = <ScheduledReminder>[];

    for (final treatment in treatments) {
      if (!treatment.ativo || !treatment.lembretesAtivos) continue;
      if (treatment.fim != null &&
          SymptomLog.normalizeDate(now)
              .isAfter(SymptomLog.normalizeDate(treatment.fim!))) {
        continue;
      }

      final baseDay = SymptomLog.normalizeDate(
        now.isBefore(treatment.inicio) ? treatment.inicio : now,
      );

      for (final slot in treatment.horarios) {
        final parsed = Treatment.tryParseTimeSlot(slot);
        if (parsed == null) continue;

        var candidate = DateTime(
          baseDay.year,
          baseDay.month,
          baseDay.day,
          parsed.hour,
          parsed.minute,
        );
        if (candidate.isBefore(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        if (treatment.fim != null &&
            SymptomLog.normalizeDate(candidate)
                .isAfter(SymptomLog.normalizeDate(treatment.fim!))) {
          continue;
        }

        final doseSuffix =
            (treatment.dose != null && treatment.dose!.trim().isNotEmpty)
                ? ' (${treatment.dose!.trim()})'
                : '';

        items.add(
          ScheduledReminder(
            notificationId: ScheduledReminder.deterministicId(
              ReminderKind.medication,
              treatment.id,
              slot,
            ),
            sourceId: treatment.id,
            kind: ReminderKind.medication,
            title: 'Hora do seu cuidado: ${treatment.medicamento}',
            body: 'Horário das $slot$doseSuffix.',
            scheduledAt: candidate,
            repeatsDaily: true,
            slotKey: slot,
          ),
        );
      }
    }

    for (final appt in appointments) {
      final triggerAt = appt.reminderTriggerAt;
      if (triggerAt == null || triggerAt.isBefore(now)) continue;

      String formattedApptTime;
      try {
        formattedApptTime =
            DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(appt.data);
      } catch (_) {
        final h = appt.data.hour.toString().padLeft(2, '0');
        final m = appt.data.minute.toString().padLeft(2, '0');
        formattedApptTime = '${appt.data.day}/${appt.data.month} às $h:$m';
      }
      final placeSuffix =
          (appt.local != null && appt.local!.trim().isNotEmpty)
              ? ' • ${appt.local!.trim()}'
              : '';

      items.add(
        ScheduledReminder(
          notificationId: ScheduledReminder.deterministicId(
            ReminderKind.appointment,
            appt.id,
            'lead_${appt.lembreteAntecedenciaMinutos}',
          ),
          sourceId: appt.id,
          kind: ReminderKind.appointment,
          title: '${appt.tipo.label}: ${appt.titulo}',
          body: 'Agendado para $formattedApptTime$placeSuffix.',
          scheduledAt: triggerAt,
          repeatsDaily: false,
          slotKey: 'lead_${appt.lembreteAntecedenciaMinutos}',
        ),
      );
    }

    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }

  /// Retorna os lembretes cujo horário exato configurado ocorre no minuto `targetMinute`
  /// ou dentro da janela `(windowStartExclusive, windowEndInclusive]`.
  static List<ScheduledReminder> evaluateDueInWindow({
    required Iterable<Treatment> treatments,
    required Iterable<MedicalAppointment> appointments,
    required DateTime windowStartExclusive,
    required DateTime windowEndInclusive,
  }) {
    if (windowEndInclusive.isBefore(windowStartExclusive)) return const [];

    final due = <ScheduledReminder>[];
    final startDay = SymptomLog.normalizeDate(windowStartExclusive);
    final endDay = SymptomLog.normalizeDate(windowEndInclusive);
    final totalDays = endDay.difference(startDay).inDays;

    for (final treatment in treatments) {
      if (!treatment.ativo || !treatment.lembretesAtivos) continue;
      for (var d = 0; d <= totalDays; d++) {
        final day = startDay.add(Duration(days: d));
        if (day.isBefore(SymptomLog.normalizeDate(treatment.inicio))) continue;
        if (treatment.fim != null &&
            day.isAfter(SymptomLog.normalizeDate(treatment.fim!))) {
          continue;
        }
        for (final slot in treatment.horarios) {
          final parsed = Treatment.tryParseTimeSlot(slot);
          if (parsed == null) continue;
          final slotMoment = DateTime(
            day.year,
            day.month,
            day.day,
            parsed.hour,
            parsed.minute,
          );
          if (slotMoment.isAfter(windowStartExclusive) &&
              !slotMoment.isAfter(windowEndInclusive)) {
            final doseSuffix =
                (treatment.dose != null && treatment.dose!.trim().isNotEmpty)
                    ? ' (${treatment.dose!.trim()})'
                    : '';
            due.add(
              ScheduledReminder(
                notificationId: ScheduledReminder.deterministicId(
                  ReminderKind.medication,
                  treatment.id,
                  slot,
                ),
                sourceId: treatment.id,
                kind: ReminderKind.medication,
                title: 'Hora do seu cuidado: ${treatment.medicamento}',
                body: 'Horário das $slot$doseSuffix.',
                scheduledAt: slotMoment,
                repeatsDaily: true,
                slotKey: slot,
              ),
            );
          }
        }
      }
    }

    for (final appt in appointments) {
      final triggerAt = appt.reminderTriggerAt;
      if (triggerAt == null) continue;
      if (triggerAt.isAfter(windowStartExclusive) &&
          !triggerAt.isAfter(windowEndInclusive)) {
        final h = appt.data.hour.toString().padLeft(2, '0');
        final m = appt.data.minute.toString().padLeft(2, '0');
        final placeSuffix =
            (appt.local != null && appt.local!.trim().isNotEmpty)
                ? ' • ${appt.local!.trim()}'
                : '';
        due.add(
          ScheduledReminder(
            notificationId: ScheduledReminder.deterministicId(
              ReminderKind.appointment,
              appt.id,
              'lead_${appt.lembreteAntecedenciaMinutos}',
            ),
            sourceId: appt.id,
            kind: ReminderKind.appointment,
            title: '${appt.tipo.label}: ${appt.titulo}',
            body:
                'Agendado para ${appt.data.day}/${appt.data.month} às $h:$m$placeSuffix.',
            scheduledAt: triggerAt,
            repeatsDaily: false,
            slotKey: 'lead_${appt.lembreteAntecedenciaMinutos}',
          ),
        );
      }
    }

    due.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return due;
  }
}

