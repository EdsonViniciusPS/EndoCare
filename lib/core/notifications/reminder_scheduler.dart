import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:endocare/core/firebase/fcm_token_service.dart';
import 'package:endocare/core/notifications/scheduled_reminder.dart';
import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';

/// Contrato unificado de agendamento de lembretes locais (`flutter_local_notifications`)
/// e registro de canal push (`FCM`), sobregravável em testes automatizados.
abstract class ReminderScheduler {
  /// Stream de lembretes que dispararam no horário configurado.
  Stream<ScheduledReminder> get onReminderFired;

  /// Lista atual dos lembretes agendados na sessão.
  List<ScheduledReminder> get activeSchedules;

  /// Inicializa canais locais e timezone.
  Future<void> initialize();

  /// Solicita permissões de notificação local e sincroniza token FCM (se suportado).
  Future<String?> requestPermissionsAndSyncPush();

  /// Reconcilia todos os agendamentos locais ativos de medicamentos e consultas.
  Future<void> syncAllSchedules({
    required List<Treatment> treatments,
    required List<MedicalAppointment> appointments,
    required DateTime now,
  });

  /// Avalia e dispara imediatamente qualquer lembrete cujo horário configurado
  /// tenha sido atingido na janela `(previousCheck, currentTime]`.
  Future<List<ScheduledReminder>> evaluateAndFireDue({
    required List<Treatment> treatments,
    required List<MedicalAppointment> appointments,
    required DateTime previousCheck,
    required DateTime currentTime,
  });

  void dispose();
}

/// Implementação de produção integrando `FlutterLocalNotificationsPlugin` + `FcmTokenService`.
class LocalAndPushReminderScheduler implements ReminderScheduler {
  LocalAndPushReminderScheduler({
    FlutterLocalNotificationsPlugin? localNotifications,
    this.fcmTokenService,
  }) : _plugin = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final FcmTokenService? fcmTokenService;

  final StreamController<ScheduledReminder> _firedController =
      StreamController<ScheduledReminder>.broadcast();
  final Set<String> _firedOccurrenceKeys = {};
  List<ScheduledReminder> _activeSchedules = const [];
  bool _initialized = false;

  static const AndroidNotificationDetails _androidChannel =
      AndroidNotificationDetails(
    'endocare_care_reminders',
    'Lembretes de Tratamentos e Consultas',
    channelDescription:
        'Notificações nos horários configurados de medicamentos, consultas e exames.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const DarwinNotificationDetails _darwinDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const NotificationDetails _defaultDetails = NotificationDetails(
    android: _androidChannel,
    iOS: _darwinDetails,
    macOS: _darwinDetails,
  );

  @override
  Stream<ScheduledReminder> get onReminderFired => _firedController.stream;

  @override
  List<ScheduledReminder> get activeSchedules =>
      List<ScheduledReminder>.unmodifiable(_activeSchedules);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      tz_data.initializeTimeZones();
    } catch (_) {
      // Timezone já inicializado.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Abrir EndoCare'),
      windows: WindowsInitializationSettings(
        appName: 'EndoCare',
        appUserModelId: 'Com.EndoCare.App.1',
        guid: '6d8b9e42-4c6f-4b9c-9d7c-2f8a1e5c4d10',
      ),
    );

    try {
      await _plugin.initialize(settings: settings);
    } catch (_) {
      // Ignora em ambientes sem canal nativo (ex.: testes headless).
    }
  }

  @override
  Future<String?> requestPermissionsAndSyncPush() async {
    await initialize();

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (_) {
      // Permissão tratada de forma resiliente.
    }

    return fcmTokenService?.registerAndGetTokenSafely();
  }

  @override
  Future<void> syncAllSchedules({
    required List<Treatment> treatments,
    required List<MedicalAppointment> appointments,
    required DateTime now,
  }) async {
    await initialize();

    final previousIds =
        _activeSchedules.map((r) => r.notificationId).toSet();
    final upcoming = ReminderScheduleEngine.buildUpcoming(
      treatments: treatments,
      appointments: appointments,
      now: now,
    );
    final nextIds = upcoming.map((r) => r.notificationId).toSet();

    // Cancela lembretes que foram removidos ou desativados.
    for (final staleId in previousIds.difference(nextIds)) {
      try {
        await _plugin.cancel(id: staleId);
      } catch (_) {}
    }

    // Agenda/atualiza cada lembrete ativo no SO.
    for (final reminder in upcoming) {
      try {
        final tzDate = tz.TZDateTime.from(reminder.scheduledAt, tz.local);
        await _plugin.zonedSchedule(
          id: reminder.notificationId,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: tzDate,
          notificationDetails: _defaultDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents:
              reminder.repeatsDaily ? DateTimeComponents.time : null,
          payload: '${reminder.kind.code}:${reminder.sourceId}',
        );
      } catch (_) {
        // Silencioso em plataformas onde zonedSchedule não estiver disponível.
      }
    }

    _activeSchedules = upcoming;
  }

  @override
  Future<List<ScheduledReminder>> evaluateAndFireDue({
    required List<Treatment> treatments,
    required List<MedicalAppointment> appointments,
    required DateTime previousCheck,
    required DateTime currentTime,
  }) async {
    await initialize();
    final dueList = ReminderScheduleEngine.evaluateDueInWindow(
      treatments: treatments,
      appointments: appointments,
      windowStartExclusive: previousCheck,
      windowEndInclusive: currentTime,
    );

    final newlyFired = <ScheduledReminder>[];
    for (final item in dueList) {
      final occurrenceKey =
          '${item.notificationId}@${item.scheduledAt.toIso8601String()}';
      if (!_firedOccurrenceKeys.add(occurrenceKey)) continue;

      try {
        await _plugin.show(
          id: item.notificationId,
          title: item.title,
          body: item.body,
          notificationDetails: _defaultDetails,
          payload: '${item.kind.code}:${item.sourceId}',
        );
      } catch (_) {}

      _firedController.add(item);
      newlyFired.add(item);
    }
    return newlyFired;
  }

  @override
  void dispose() {
    _firedController.close();
  }
}

