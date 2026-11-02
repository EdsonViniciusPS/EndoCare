import 'dart:async';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:endocare/app.dart';
import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/notifications/reminder_scheduler.dart';
import 'package:endocare/core/notifications/scheduled_reminder.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/appointments/domain/models/medical_appointment.dart';
import 'package:endocare/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:endocare/features/auth/domain/models/app_auth_user.dart';
import 'package:endocare/features/auth/domain/models/auth_failure.dart';
import 'package:endocare/features/auth/domain/models/user_profile.dart';
import 'package:endocare/features/auth/domain/repositories/auth_repository.dart';
import 'package:endocare/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/body_map/domain/models/body_heatmap_summary.dart';
import 'package:endocare/features/body_map/domain/models/body_region_definition.dart';
import 'package:endocare/features/body_map/domain/models/body_region_pain_entry.dart';
import 'package:endocare/features/calendar/domain/models/calendar_day_digest.dart';
import 'package:endocare/features/calendar/domain/models/cycle_entry.dart';
import 'package:endocare/features/calendar/domain/models/cycle_prediction_engine.dart';
import 'package:endocare/features/calendar/domain/repositories/cycle_repository.dart';
import 'package:endocare/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:endocare/features/care/presentation/providers/care_providers.dart';
import 'package:endocare/features/home/domain/models/home_summary_data.dart';
import 'package:endocare/features/home/presentation/providers/home_providers.dart';
import 'package:endocare/features/impact/domain/models/impact_log.dart';
import 'package:endocare/features/impact/domain/repositories/impact_log_repository.dart';
import 'package:endocare/features/impact/presentation/providers/impact_providers.dart';
import 'package:endocare/features/onboarding/data/onboarding_storage.dart';
import 'package:endocare/features/onboarding/domain/models/onboarding_slide_data.dart';
import 'package:endocare/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/symptoms/domain/repositories/symptom_log_repository.dart';
import 'package:endocare/features/symptoms/presentation/providers/symptom_providers.dart';
import 'package:endocare/features/timeline/domain/models/timeline_event.dart';
import 'package:endocare/features/timeline/domain/timeline_builder.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';
import 'package:endocare/features/treatments/domain/models/treatment_effect.dart';
import 'package:endocare/features/treatments/domain/repositories/treatment_repository.dart';

/// Armazenamento em memória do status local de onboarding para testes.
class FakeOnboardingStorage implements OnboardingStorage {
  FakeOnboardingStorage({bool initialCompleted = false})
      : _completed = initialCompleted;

  bool _completed;

  @override
  Future<bool> hasCompletedOnboarding() async => _completed;

  @override
  Future<void> setOnboardingCompleted() async {
    _completed = true;
  }
}

/// Repositório em memória de `users/{uid}/symptomLogs/{yyyy-MM-dd}` para testes.
class FakeSymptomLogRepository implements SymptomLogRepository {
  final Map<String, Map<String, SymptomLog>> _logsByUid = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Map<String, SymptomLog> _userMap(String uid) {
    return _logsByUid.putIfAbsent(uid, () => {});
  }

  SymptomLog? logFor(String uid, DateTime date) {
    return _userMap(uid)[SymptomLog.dateKeyFor(date)];
  }

  void seedLog(String uid, SymptomLog log) {
    _userMap(uid)[SymptomLog.dateKeyFor(log.data)] = log;
    _changes.add(null);
  }

  @override
  Stream<SymptomLog?> watchLogForDate({
    required String uid,
    required DateTime date,
  }) async* {
    final key = SymptomLog.dateKeyFor(date);
    yield _userMap(uid)[key];
    await for (final _ in _changes.stream) {
      yield _userMap(uid)[key];
    }
  }

  @override
  Future<SymptomLog?> getLogForDate({
    required String uid,
    required DateTime date,
  }) async {
    return _userMap(uid)[SymptomLog.dateKeyFor(date)];
  }

  @override
  Future<SymptomLog?> getPreviousLogBefore({
    required String uid,
    required DateTime date,
  }) async {
    final normalized = SymptomLog.normalizeDate(date);
    final candidates = _userMap(uid)
        .values
        .where((entry) => entry.data.isBefore(normalized))
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  @override
  Future<void> saveLog({
    required String uid,
    required SymptomLog log,
  }) async {
    _userMap(uid)[SymptomLog.dateKeyFor(log.data)] = log;
    _changes.add(null);
  }

  List<SymptomLog> _filteredLogs(String uid, DateTime? sinceDate) {
    final normalizedSince =
        sinceDate != null ? SymptomLog.normalizeDate(sinceDate) : null;
    final items = _userMap(uid)
        .values
        .where(
          (entry) =>
              normalizedSince == null || !entry.data.isBefore(normalizedSince),
        )
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    return items;
  }

  @override
  Stream<List<SymptomLog>> watchLogs({
    required String uid,
    DateTime? sinceDate,
  }) async* {
    yield _filteredLogs(uid, sinceDate);
    await for (final _ in _changes.stream) {
      yield _filteredLogs(uid, sinceDate);
    }
  }

  void dispose() {
    _changes.close();
  }
}

/// Repositório em memória de `users/{uid}/cycleEntries/{yyyy-MM-dd}` e `appointments`.
class FakeCycleRepository implements CycleRepository {
  final Map<String, Map<String, CycleEntry>> _entriesByUid = {};
  final Map<String, List<CalendarExternalAppointment>> _appointmentsByUid = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Map<String, CycleEntry> _userEntries(String uid) {
    return _entriesByUid.putIfAbsent(uid, () => {});
  }

  CycleEntry? entryFor(String uid, DateTime date) {
    return _userEntries(uid)[SymptomLog.dateKeyFor(date)];
  }

  void seedEntry(String uid, CycleEntry entry) {
    _userEntries(uid)[SymptomLog.dateKeyFor(entry.data)] = entry;
    _changes.add(null);
  }

  void seedAppointment(String uid, CalendarExternalAppointment appointment) {
    _appointmentsByUid
        .putIfAbsent(uid, () => <CalendarExternalAppointment>[])
        .add(appointment);
    _changes.add(null);
  }

  List<CycleEntry> _filteredEntries(String uid, DateTime? sinceDate) {
    final normalizedSince =
        sinceDate != null ? SymptomLog.normalizeDate(sinceDate) : null;
    final items = _userEntries(uid)
        .values
        .where(
          (entry) =>
              normalizedSince == null || !entry.data.isBefore(normalizedSince),
        )
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    return items;
  }

  @override
  Stream<List<CycleEntry>> watchEntries({
    required String uid,
    DateTime? sinceDate,
  }) async* {
    yield _filteredEntries(uid, sinceDate);
    await for (final _ in _changes.stream) {
      yield _filteredEntries(uid, sinceDate);
    }
  }

  @override
  Future<CycleEntry?> getEntryForDate({
    required String uid,
    required DateTime date,
  }) async {
    return _userEntries(uid)[SymptomLog.dateKeyFor(date)];
  }

  @override
  Future<void> saveEntry({
    required String uid,
    required CycleEntry entry,
  }) async {
    final key = SymptomLog.dateKeyFor(entry.data);
    if (entry.isEmpty) {
      _userEntries(uid).remove(key);
    } else {
      _userEntries(uid)[key] = entry;
    }
    _changes.add(null);
  }

  @override
  Future<void> deleteEntry({
    required String uid,
    required DateTime date,
  }) async {
    _userEntries(uid).remove(SymptomLog.dateKeyFor(date));
    _changes.add(null);
  }

  @override
  Stream<List<CalendarExternalAppointment>> watchAppointments({
    required String uid,
  }) async* {
    yield List<CalendarExternalAppointment>.unmodifiable(
      _appointmentsByUid[uid] ?? const [],
    );
    await for (final _ in _changes.stream) {
      yield List<CalendarExternalAppointment>.unmodifiable(
        _appointmentsByUid[uid] ?? const [],
      );
    }
  }

  void dispose() {
    _changes.close();
  }
}

/// Repositório em memória de `users/{uid}/treatments` e `users/{uid}/treatmentEffects`.
class FakeTreatmentRepository implements TreatmentRepository {
  final Map<String, Map<String, Treatment>> _treatmentsByUid = {};
  final Map<String, Map<String, TreatmentEffect>> _effectsByUid = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _nextTreatmentSeq = 1;
  int _nextEffectSeq = 1;

  Map<String, Treatment> _userTreatments(String uid) {
    return _treatmentsByUid.putIfAbsent(uid, () => {});
  }

  Map<String, TreatmentEffect> _userEffects(String uid) {
    return _effectsByUid.putIfAbsent(uid, () => {});
  }

  List<Treatment> treatmentsFor(String uid) {
    final items = _userTreatments(uid).values.toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));
    return items;
  }

  List<TreatmentEffect> effectsFor(String uid) {
    final items = _userEffects(uid).values.toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    return items;
  }

  @override
  Stream<List<Treatment>> watchTreatments({required String uid}) async* {
    yield treatmentsFor(uid);
    await for (final _ in _changes.stream) {
      yield treatmentsFor(uid);
    }
  }

  @override
  Future<Treatment> saveTreatment({
    required String uid,
    required Treatment treatment,
  }) async {
    final resolvedId =
        treatment.id.isNotEmpty ? treatment.id : 'treat_${_nextTreatmentSeq++}';
    final persisted = treatment.copyWith(id: resolvedId);
    _userTreatments(uid)[resolvedId] = persisted;
    _changes.add(null);
    return persisted;
  }

  @override
  Future<void> deleteTreatment({
    required String uid,
    required String treatmentId,
  }) async {
    _userTreatments(uid).remove(treatmentId);
    _changes.add(null);
  }

  @override
  Stream<List<TreatmentEffect>> watchEffects({required String uid}) async* {
    yield effectsFor(uid);
    await for (final _ in _changes.stream) {
      yield effectsFor(uid);
    }
  }

  @override
  Future<TreatmentEffect> saveEffect({
    required String uid,
    required TreatmentEffect effect,
  }) async {
    final resolvedId =
        effect.id.isNotEmpty ? effect.id : 'eff_${_nextEffectSeq++}';
    final persisted = TreatmentEffect(
      id: resolvedId,
      treatmentId: effect.treatmentId,
      treatmentName: effect.treatmentName,
      data: effect.data,
      efeito: effect.efeito,
      tipo: effect.tipo,
      intensidade: effect.intensidade,
      notas: effect.notas,
    );
    _userEffects(uid)[resolvedId] = persisted;
    _changes.add(null);
    return persisted;
  }

  @override
  Future<void> deleteEffect({
    required String uid,
    required String effectId,
  }) async {
    _userEffects(uid).remove(effectId);
    _changes.add(null);
  }

  void dispose() {
    _changes.close();
  }
}

/// Repositório em memória de `users/{uid}/appointments` para testes.
class FakeAppointmentRepository implements AppointmentRepository {
  final Map<String, Map<String, MedicalAppointment>> _appointmentsByUid = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _nextAppointmentSeq = 1;

  Map<String, MedicalAppointment> _userAppointments(String uid) {
    return _appointmentsByUid.putIfAbsent(uid, () => {});
  }

  List<MedicalAppointment> appointmentsFor(String uid) {
    final items = _userAppointments(uid).values.toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    return items;
  }

  @override
  Stream<List<MedicalAppointment>> watchAppointments({
    required String uid,
  }) async* {
    yield appointmentsFor(uid);
    await for (final _ in _changes.stream) {
      yield appointmentsFor(uid);
    }
  }

  @override
  Future<MedicalAppointment> saveAppointment({
    required String uid,
    required MedicalAppointment appointment,
  }) async {
    final resolvedId = appointment.id.isNotEmpty
        ? appointment.id
        : 'appt_${_nextAppointmentSeq++}';
    final persisted = appointment.copyWith(id: resolvedId);
    _userAppointments(uid)[resolvedId] = persisted;
    _changes.add(null);
    return persisted;
  }

  @override
  Future<void> deleteAppointment({
    required String uid,
    required String appointmentId,
  }) async {
    _userAppointments(uid).remove(appointmentId);
    _changes.add(null);
  }

  void dispose() {
    _changes.close();
  }
}

/// Repositório em memória de `users/{uid}/impactLogs/{yyyy-MM-dd}` para testes.
class FakeImpactLogRepository implements ImpactLogRepository {
  final Map<String, Map<String, ImpactLog>> _logsByUid = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Map<String, ImpactLog> _userMap(String uid) {
    return _logsByUid.putIfAbsent(uid, () => {});
  }

  void seedLog(String uid, ImpactLog log) {
    _userMap(uid)[SymptomLog.dateKeyFor(log.data)] = log;
    _changes.add(null);
  }

  @override
  Stream<List<ImpactLog>> watchLogs({required String uid}) async* {
    yield _sortedLogs(uid);
    await for (final _ in _changes.stream) {
      yield _sortedLogs(uid);
    }
  }

  List<ImpactLog> _sortedLogs(String uid) {
    final list = _userMap(uid).values.toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    return list;
  }

  @override
  Future<ImpactLog?> getLogForDate({
    required String uid,
    required DateTime date,
  }) async {
    return _userMap(uid)[SymptomLog.dateKeyFor(date)];
  }

  @override
  Future<void> saveLog({
    required String uid,
    required ImpactLog log,
  }) async {
    _userMap(uid)[SymptomLog.dateKeyFor(log.data)] = log;
    _changes.add(null);
  }

  @override
  Future<void> deleteLog({
    required String uid,
    required DateTime date,
  }) async {
    _userMap(uid).remove(SymptomLog.dateKeyFor(date));
    _changes.add(null);
  }

  void dispose() {
    _changes.close();
  }
}

/// Agendador determinístico em memória para validar sincronização e disparo de lembretes.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.mockFcmToken = 'fcm_token_cuidar_test'});

  final String? mockFcmToken;
  final StreamController<ScheduledReminder> _firedController =
      StreamController<ScheduledReminder>.broadcast();
  final Set<String> _firedKeys = {};
  final List<ScheduledReminder> firedReminders = [];
  List<ScheduledReminder> _activeSchedules = const [];
  bool initialized = false;
  int syncCalls = 0;

  @override
  Stream<ScheduledReminder> get onReminderFired => _firedController.stream;

  @override
  List<ScheduledReminder> get activeSchedules =>
      List<ScheduledReminder>.unmodifiable(_activeSchedules);

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<String?> requestPermissionsAndSyncPush() async {
    await initialize();
    return mockFcmToken;
  }

  @override
  Future<void> syncAllSchedules({
    required List<Treatment> treatments,
    required List<MedicalAppointment> appointments,
    required DateTime now,
  }) async {
    await initialize();
    syncCalls++;
    _activeSchedules = ReminderScheduleEngine.buildUpcoming(
      treatments: treatments,
      appointments: appointments,
      now: now,
    );
  }

  @override
  Future<List<ScheduledReminder>> evaluateAndFireDue({
    required List<Treatment> treatments,
    required List<MedicalAppointment> appointments,
    required DateTime previousCheck,
    required DateTime currentTime,
  }) async {
    await initialize();
    final due = ReminderScheduleEngine.evaluateDueInWindow(
      treatments: treatments,
      appointments: appointments,
      windowStartExclusive: previousCheck,
      windowEndInclusive: currentTime,
    );
    final newlyFired = <ScheduledReminder>[];
    for (final item in due) {
      final key = '${item.notificationId}@${item.scheduledAt.toIso8601String()}';
      if (!_firedKeys.add(key)) continue;
      firedReminders.add(item);
      _firedController.add(item);
      newlyFired.add(item);
    }
    return newlyFired;
  }

  @override
  void dispose() {
    if (!_firedController.isClosed) {
      _firedController.close();
    }
  }
}

/// Repositório em memória de `users/{uid}` para testes isolados por usuária.
class FakeUserProfileRepository implements UserProfileRepository {
  final Map<String, UserProfile> _profilesByUid = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  UserProfile? profileFor(String uid) => _profilesByUid[uid];

  void seedUser(UserProfile profile) {
    _profilesByUid[profile.uid] = profile;
    _changes.add(null);
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield _profilesByUid[uid];
    await for (final _ in _changes.stream) {
      yield _profilesByUid[uid];
    }
  }

  @override
  Future<void> ensureUserDocument({
    required AppAuthUser user,
    String? nameOverride,
    DateTime? birthDate,
    String? fcmToken,
    bool? onboardingCompleted,
  }) async {
    final existing = _profilesByUid[user.uid];
    final tokens = <String>{
      ...?existing?.fcmTokens,
      if (fcmToken != null && fcmToken.isNotEmpty) fcmToken,
    }.toList();

    final prefs = (existing?.preferencias ?? const UserPreferences()).copyWith(
      onboardingConcluido: onboardingCompleted,
    );

    _profilesByUid[user.uid] = UserProfile(
      uid: user.uid,
      email: user.email,
      nome: nameOverride?.trim().isNotEmpty == true
          ? nameOverride!.trim()
          : (existing?.nome ?? user.displayName ?? 'Usuária'),
      nascimento: birthDate ?? existing?.nascimento,
      preferencias: prefs,
      fcmTokens: tokens,
    );
    _changes.add(null);
  }

  @override
  Future<void> markOnboardingCompleted(String uid) async {
    final existing = _profilesByUid[uid];
    if (existing == null) return;
    _profilesByUid[uid] = existing.copyWith(
      preferencias: existing.preferencias.copyWith(onboardingConcluido: true),
    );
    _changes.add(null);
  }

  @override
  Future<void> addFcmToken(String uid, String token) async {
    final existing = _profilesByUid[uid];
    if (existing == null) return;
    _profilesByUid[uid] = existing.copyWith(
      fcmTokens: {...existing.fcmTokens, token}.toList(),
    );
    _changes.add(null);
  }

  @override
  Future<void> removeFcmToken(String uid, String token) async {
    final existing = _profilesByUid[uid];
    if (existing == null) return;
    _profilesByUid[uid] = existing.copyWith(
      fcmTokens: existing.fcmTokens.where((t) => t != token).toList(),
    );
    _changes.add(null);
  }

  void dispose() {
    _changes.close();
  }
}

/// Repositório em memória de autenticação para validar guard, cadastro,
/// verificação de e-mail, login, recuperação de senha e logout.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._profileRepo, {AppAuthUser? initialUser})
      : _currentUser = initialUser;

  final FakeUserProfileRepository _profileRepo;
  final StreamController<AppAuthUser?> _controller =
      StreamController<AppAuthUser?>.broadcast();
  final Map<String, ({String uid, String password, String name, bool verified})>
      _accountsByEmail = {};

  AppAuthUser? _currentUser;
  bool nextReloadMarksEmailVerified = false;
  final List<String> passwordResetEmailsSent = [];
  int verificationEmailsSent = 0;

  @override
  AppAuthUser? get currentUser => _currentUser;

  @override
  Stream<AppAuthUser?> authStateChanges() async* {
    yield _currentUser;
    await for (final user in _controller.stream) {
      yield user;
    }
  }

  @override
  Future<AppAuthUser> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    DateTime? birthDate,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_accountsByEmail.containsKey(normalizedEmail)) {
      throw const AuthFailure(
        'Este e-mail já está cadastrado. Tente entrar ou recuperar sua senha.',
        code: 'email-already-in-use',
      );
    }

    final uid = 'uid_${_accountsByEmail.length + 1}';
    _accountsByEmail[normalizedEmail] = (
      uid: uid,
      password: password,
      name: name.trim(),
      verified: false,
    );

    final user = AppAuthUser(
      uid: uid,
      email: normalizedEmail,
      emailVerified: false,
      displayName: name.trim(),
    );
    await _profileRepo.ensureUserDocument(
      user: user,
      nameOverride: name.trim(),
      birthDate: birthDate,
    );
    verificationEmailsSent++;
    _emit(user);
    return user;
  }

  @override
  Future<AppAuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final record = _accountsByEmail[normalizedEmail];
    if (record == null || record.password != password) {
      throw const AuthFailure(
        'E-mail ou senha incorretos. Confira seus dados e tente novamente.',
        code: 'invalid-credential',
      );
    }

    final user = AppAuthUser(
      uid: record.uid,
      email: normalizedEmail,
      emailVerified: record.verified,
      displayName: record.name,
    );
    await _profileRepo.ensureUserDocument(user: user);
    _emit(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    passwordResetEmailsSent.add(email.trim());
  }

  @override
  Future<void> sendEmailVerification() async {
    verificationEmailsSent++;
  }

  @override
  Future<AppAuthUser?> reloadCurrentUser() async {
    final current = _currentUser;
    if (current == null) return null;
    if (nextReloadMarksEmailVerified && !current.emailVerified) {
      final record = _accountsByEmail[current.email];
      if (record != null) {
        _accountsByEmail[current.email] = (
          uid: record.uid,
          password: record.password,
          name: record.name,
          verified: true,
        );
      }
      final verifiedUser = current.copyWith(emailVerified: true);
      await _profileRepo.ensureUserDocument(user: verifiedUser);
      _emit(verifiedUser);
      return verifiedUser;
    }
    return current;
  }

  @override
  Future<void> signOut() async {
    _emit(null);
  }

  void _emit(AppAuthUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppAssets — Etapa 0', () {
    test('contém exatamente os 3 logos JPEG e os 32 SVGs Storyset no disco', () {
      expect(AppAssets.allLogos.length, 3);
      for (final logoPath in AppAssets.allLogos) {
        expect(logoPath.endsWith('.jpg'), isTrue);
        expect(
          File(logoPath).existsSync(),
          isTrue,
          reason: 'Logo ausente no disco: $logoPath',
        );
      }

      expect(AppAssets.allStorysets.length, 32);
      final uniquePaths = AppAssets.allStorysets.map((e) => e.path).toSet();
      expect(uniquePaths.length, 32);

      for (final storyset in AppAssets.allStorysets) {
        expect(storyset.path.endsWith('.svg'), isTrue);
        expect(
          File(storyset.path).existsSync(),
          isTrue,
          reason: 'Storyset ausente no disco: ${storyset.path}',
        );
      }
    });

    test('distribui variações sem repetição consecutiva nos grupos principais', () {
      for (final group in [
        StorysetThemeGroup.onboardingAndWellness,
        StorysetThemeGroup.libraryAndEducation,
        StorysetThemeGroup.emptyStatesAndSupport,
      ]) {
        final items = AppAssets.group(group);
        for (var i = 0; i < items.length - 1; i++) {
          expect(items[i].path, isNot(equals(items[i + 1].path)));
        }
      }
    });
  });

  group('Firestore Security Rules — Etapa 1', () {
    test('firestore.rules protege users/{uid}, valida dor 0-10 e restringe articles', () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);

      final content = rulesFile.readAsStringSync();
      expect(content, contains('request.auth.uid == uid'));
      expect(content, contains('match /users/{uid}'));
      expect(content, contains('value >= 0 && value <= 10'));
      expect(content, contains('match /articles/{articleId}'));
      expect(content, contains('allow write: if false;'));
    });
  });

  group('Onboarding e Início — Etapa 2', () {
    test('as 3 telas de Onboarding usam artes e paletas distintas', () {
      final slides = OnboardingSlideData.slides;
      expect(slides.length, 3);

      final paths = slides.map((s) => s.illustration.path).toSet();
      final palettes = slides.map((s) => s.illustration.palette).toSet();
      expect(paths.length, 3);
      expect(palettes.length, 3);
    });

    test('Início alterna a ilustração contextual por dia do ano e intensidade', () {
      final day1 = HomeSummaryData.forToday(
        now: DateTime(2026, 5, 1, 9),
        formattedDate: 'Sexta, 1 de maio',
        firstName: 'Ana',
      );
      final day2 = HomeSummaryData.forToday(
        now: DateTime(2026, 5, 2, 15),
        formattedDate: 'Sábado, 2 de maio',
        firstName: 'Ana',
      );
      final day3 = HomeSummaryData.forToday(
        now: DateTime(2026, 5, 3, 20),
        formattedDate: 'Domingo, 3 de maio',
        firstName: 'Ana',
      );

      expect(day1.greeting, 'Bom dia, Ana');
      expect(day2.greeting, 'Boa tarde, Ana');
      expect(day3.greeting, 'Boa noite, Ana');

      final distinctDailyPaths = {
        day1.heroIllustration.path,
        day2.heroIllustration.path,
        day3.heroIllustration.path,
      };
      expect(distinctDailyPaths.length, 3);

      final highPain = HomeSummaryData.forToday(
        now: DateTime(2026, 5, 1, 9),
        formattedDate: 'Sexta, 1 de maio',
        firstName: 'Ana',
        todayPainLevel: 9,
      );
      expect(
        highPain.heroIllustration.path,
        AppAssets.overwhelmedRafiki.path,
      );
    });

    testWidgets(
      'Primeiro acesso autenticado passa pelas 3 telas de Onboarding, cai no Início e abre atalho de registro',
      (WidgetTester tester) async {
        const verifiedUser = AppAuthUser(
          uid: 'uid_ana',
          email: 'ana@exemplo.com',
          emailVerified: true,
          displayName: 'Ana Clara',
        );
        final fakeProfiles = FakeUserProfileRepository()
          ..seedUser(
            const UserProfile(
              uid: 'uid_ana',
              email: 'ana@exemplo.com',
              nome: 'Ana Clara',
              preferencias: UserPreferences(onboardingConcluido: false),
            ),
          );
        final fakeAuth = FakeAuthRepository(
          fakeProfiles,
          initialUser: verifiedUser,
        );
        final fakeOnboarding = FakeOnboardingStorage(initialCompleted: false);
        final fakeSymptoms = FakeSymptomLogRepository();
        final fakeCycles = FakeCycleRepository();
        final fakeTreatments = FakeTreatmentRepository();
        final fakeAppointments = FakeAppointmentRepository();
        final fakeImpact = FakeImpactLogRepository();
        final fakeScheduler = FakeReminderScheduler();

        addTearDown(() {
          fakeAuth.dispose();
          fakeProfiles.dispose();
          fakeSymptoms.dispose();
          fakeCycles.dispose();
          fakeTreatments.dispose();
          fakeAppointments.dispose();
          fakeImpact.dispose();
          fakeScheduler.dispose();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingStorageProvider.overrideWithValue(fakeOnboarding),
              userProfileRepositoryProvider.overrideWithValue(fakeProfiles),
              authRepositoryProvider.overrideWithValue(fakeAuth),
              symptomLogRepositoryProvider.overrideWithValue(fakeSymptoms),
              cycleRepositoryProvider.overrideWithValue(fakeCycles),
              treatmentRepositoryProvider.overrideWithValue(fakeTreatments),
              appointmentRepositoryProvider.overrideWithValue(fakeAppointments),
              impactLogRepositoryProvider.overrideWithValue(fakeImpact),
              reminderSchedulerProvider.overrideWithValue(fakeScheduler),
              homeClockProvider.overrideWithValue(
                () => DateTime(2026, 11, 2, 15, 30),
              ),
            ],
            child: const EndoCareApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Passo 1 de 3'), findsOneWidget);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 2 de 3'), findsOneWidget);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 3 de 3'), findsOneWidget);
        await tester.tap(find.text('Começar no EndoCare'));
        await tester.pumpAndSettle();

        expect(
          fakeProfiles.profileFor('uid_ana')?.preferencias.onboardingConcluido,
          isTrue,
        );

        expect(find.text('Boa tarde, Ana'), findsOneWidget);
        expect(find.text('Resumo de hoje'), findsOneWidget);
        expect(find.text('Próximos lembretes'), findsOneWidget);

        final quickLogShortcut = find.text('Registrar como estou hoje');
        await tester.ensureVisible(quickLogShortcut);
        await tester.tap(quickLogShortcut);
        await tester.pumpAndSettle();

        expect(find.text('Como está sua dor?'), findsOneWidget);
        expect(find.text('Salvar registro'), findsOneWidget);
      },
    );
  });

  group('Registro diário de sintomas — Etapa 3', () {
    testWidgets(
      'Reaproveita valores do dia anterior, permite expandir detalhes opcionais, salva em symptomLogs e reflete no Início',
      (WidgetTester tester) async {
        const verifiedUser = AppAuthUser(
          uid: 'uid_lara',
          email: 'lara@exemplo.com',
          emailVerified: true,
          displayName: 'Lara Mendes',
        );
        final fakeProfiles = FakeUserProfileRepository()
          ..seedUser(
            const UserProfile(
              uid: 'uid_lara',
              email: 'lara@exemplo.com',
              nome: 'Lara Mendes',
              preferencias: UserPreferences(onboardingConcluido: true),
            ),
          );
        final fakeAuth = FakeAuthRepository(
          fakeProfiles,
          initialUser: verifiedUser,
        );
        final fakeOnboarding = FakeOnboardingStorage(initialCompleted: true);

        final yesterday = DateTime(2026, 11, 1);
        final today = DateTime(2026, 11, 2, 14, 0);
        final fakeSymptoms = FakeSymptomLogRepository()
          ..seedLog(
            'uid_lara',
            SymptomLog(
              id: SymptomLog.dateKeyFor(yesterday),
              data: yesterday,
              dor: 6,
              sono: 5,
              humor: 'Sensível',
              tipos: const ['Cólica', 'Fadiga'],
              intestinal: const ['Estufamento / gases'],
              fadiga: 7,
              notas: 'Observação particular de ontem',
            ),
          );

        final fakeCycles = FakeCycleRepository();
        final fakeTreatments = FakeTreatmentRepository();
        final fakeAppointments = FakeAppointmentRepository();
        final fakeImpact = FakeImpactLogRepository();
        final fakeScheduler = FakeReminderScheduler();

        addTearDown(() {
          fakeAuth.dispose();
          fakeProfiles.dispose();
          fakeSymptoms.dispose();
          fakeCycles.dispose();
          fakeTreatments.dispose();
          fakeAppointments.dispose();
          fakeImpact.dispose();
          fakeScheduler.dispose();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingStorageProvider.overrideWithValue(fakeOnboarding),
              userProfileRepositoryProvider.overrideWithValue(fakeProfiles),
              authRepositoryProvider.overrideWithValue(fakeAuth),
              symptomLogRepositoryProvider.overrideWithValue(fakeSymptoms),
              cycleRepositoryProvider.overrideWithValue(fakeCycles),
              treatmentRepositoryProvider.overrideWithValue(fakeTreatments),
              appointmentRepositoryProvider.overrideWithValue(fakeAppointments),
              impactLogRepositoryProvider.overrideWithValue(fakeImpact),
              reminderSchedulerProvider.overrideWithValue(fakeScheduler),
              homeClockProvider.overrideWithValue(() => today),
            ],
            child: const EndoCareApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Abre a aba central Registrar
        await tester.tap(find.text('Registrar'));
        await tester.pumpAndSettle();

        // Confirma o banner de reaproveitamento do dia anterior e dor 6/10
        expect(
          find.textContaining('Valores preenchidos com base no seu registro anterior'),
          findsOneWidget,
        );
        expect(find.text('6 • Moderada'), findsOneWidget);

        // Detalhes opcionais iniciam recolhidos
        expect(
          find.text('Dor durante ou após relação sexual'),
          findsNothing,
        );

        // Marca mais um chip rápido ("Dor lombar")
        final lombarChip = find.text('Dor lombar');
        await tester.ensureVisible(lombarChip);
        await tester.tap(lombarChip);
        await tester.pump();

        // Expande a seção de Detalhes opcionais e registra dor em relação sexual
        final optionalHeader = find.text('Detalhes opcionais');
        await tester.ensureVisible(optionalHeader);
        await tester.tap(optionalHeader);
        await tester.pumpAndSettle();

        final sexualPainToggle =
            find.text('Dor durante ou após relação sexual');
        await tester.ensureVisible(sexualPainToggle);
        await tester.tap(sexualPainToggle);
        await tester.pumpAndSettle();

        final deepLocationChip = find.text('Fundo pélvico (profunda)');
        await tester.ensureVisible(deepLocationChip);
        await tester.tap(deepLocationChip);
        await tester.pump();

        // Notas de ontem NÃO devem ter sido copiadas para hoje
        final notesField = find.byType(TextField);
        await tester.ensureVisible(notesField);
        expect(
          find.text('Observação particular de ontem'),
          findsNothing,
        );
        await tester.enterText(notesField, 'Bolsa morna ajudou à tarde.');

        // Botão "Salvar registro" permanece fixo e acessível sem precisar rolar de volta
        await tester.tap(find.text('Salvar registro'));
        await tester.pumpAndSettle();

        // Verifica gravação em `symptomLogs/2026-11-02`
        final saved = fakeSymptoms.logFor('uid_lara', today);
        expect(saved, isNotNull);
        expect(saved!.dor, 6);
        expect(saved.sono, 5);
        expect(saved.humor, 'Sensível');
        expect(saved.tipos, containsAll(['Cólica', 'Fadiga', 'Dor lombar']));
        expect(saved.intestinal, contains('Estufamento / gases'));
        expect(saved.fadiga, 7);
        expect(saved.dorRelacao?.local, 'Fundo pélvico (profunda)');
        expect(saved.notas, 'Bolsa morna ajudou à tarde.');

        // Volta ao Início e confirma atualização em tempo real do Resumo de hoje
        await tester.tap(find.text('Início'));
        await tester.pumpAndSettle();
        expect(find.text('Nível 6/10'), findsOneWidget);
        expect(find.text('Sensível'), findsOneWidget);
        expect(find.text('Atualizar registro de hoje'), findsOneWidget);
      },
    );
  });

  group('Mapa corporal interativo — Etapa 4', () {
    test(
      'BodyHeatmapSummary agrega regiões frente e costas com ocorrências, média, pico e atributos predominantes',
      () {
        final logs = [
          SymptomLog(
            id: '2026-10-30',
            data: DateTime(2026, 10, 30),
            dor: 8,
            sono: 6,
            mapaCorporal: const [
              BodyRegionPainEntry(
                regionId: 'pelve_central',
                regionLabel: 'Pelve central / Útero',
                side: BodySide.front,
                intensidade: 8,
                tipoDor: 'Pontada / Fisgada',
                duracao: 'Dia todo',
                frequencia: 'Frequente',
              ),
            ],
          ),
          SymptomLog(
            id: '2026-11-01',
            data: DateTime(2026, 11, 1),
            dor: 7,
            sono: 7,
            mapaCorporal: const [
              BodyRegionPainEntry(
                regionId: 'pelve_central',
                regionLabel: 'Pelve central / Útero',
                side: BodySide.front,
                intensidade: 6,
                tipoDor: 'Pontada / Fisgada',
                duracao: 'Dia todo',
                frequencia: 'Frequente',
              ),
              BodyRegionPainEntry(
                regionId: 'lombar_central',
                regionLabel: 'Lombar central',
                side: BodySide.back,
                intensidade: 7,
                tipoDor: 'Pressão / Peso',
                duracao: 'Metade do dia',
                frequencia: 'Constante',
              ),
            ],
          ),
          // Dia sem regiões mapeadas não deve inflar `totalMappedDays`
          SymptomLog(
            id: '2026-11-02',
            data: DateTime(2026, 11, 2),
            dor: 2,
            sono: 8,
          ),
        ];

        final summary = BodyHeatmapSummary.aggregate(
          period: BodyHeatmapPeriod.days30,
          logs: logs,
        );

        expect(summary.totalMappedDays, 2);
        expect(summary.countForSide(BodySide.front), 1);
        expect(summary.countForSide(BodySide.back), 1);
        expect(summary.rankedRegions.length, 2);

        final top = summary.rankedRegions.first;
        expect(top.region.id, 'pelve_central');
        expect(top.occurrences, 2);
        expect(top.averageIntensity, 7.0);
        expect(top.maxIntensity, 8);
        expect(top.predominantPainType, 'Pontada / Fisgada');
        expect(top.predominantDuration, 'Dia todo');
        expect(top.predominantFrequency, 'Frequente');

        final second = summary.rankedRegions[1];
        expect(second.region.id, 'lombar_central');
        expect(second.occurrences, 1);
        expect(second.averageIntensity, 7.0);
      },
    );

    testWidgets(
      'Marca regiões tocáveis na silhueta Frente e Costas, salva em symptomLogs e exibe no Heatmap histórico',
      (WidgetTester tester) async {
        const verifiedUser = AppAuthUser(
          uid: 'uid_clara',
          email: 'clara@exemplo.com',
          emailVerified: true,
          displayName: 'Clara Nunes',
        );
        final fakeProfiles = FakeUserProfileRepository()
          ..seedUser(
            const UserProfile(
              uid: 'uid_clara',
              email: 'clara@exemplo.com',
              nome: 'Clara Nunes',
              preferencias: UserPreferences(onboardingConcluido: true),
            ),
          );
        final fakeAuth = FakeAuthRepository(
          fakeProfiles,
          initialUser: verifiedUser,
        );
        final fakeOnboarding = FakeOnboardingStorage(initialCompleted: true);

        final priorDay = DateTime(2026, 10, 30);
        final today = DateTime(2026, 11, 2, 16, 0);
        final fakeSymptoms = FakeSymptomLogRepository()
          ..seedLog(
            'uid_clara',
            SymptomLog(
              id: SymptomLog.dateKeyFor(priorDay),
              data: priorDay,
              dor: 8,
              sono: 6,
              mapaCorporal: const [
                BodyRegionPainEntry(
                  regionId: 'pelve_central',
                  regionLabel: 'Pelve central / Útero',
                  side: BodySide.front,
                  intensidade: 8,
                  tipoDor: 'Cólica',
                  duracao: 'Algumas horas',
                  frequencia: 'Frequente',
                ),
              ],
            ),
          );

        final fakeCycles = FakeCycleRepository();
        final fakeTreatments = FakeTreatmentRepository();
        final fakeAppointments = FakeAppointmentRepository();
        final fakeImpact = FakeImpactLogRepository();
        final fakeScheduler = FakeReminderScheduler();

        addTearDown(() {
          fakeAuth.dispose();
          fakeProfiles.dispose();
          fakeSymptoms.dispose();
          fakeCycles.dispose();
          fakeTreatments.dispose();
          fakeAppointments.dispose();
          fakeImpact.dispose();
          fakeScheduler.dispose();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingStorageProvider.overrideWithValue(fakeOnboarding),
              userProfileRepositoryProvider.overrideWithValue(fakeProfiles),
              authRepositoryProvider.overrideWithValue(fakeAuth),
              symptomLogRepositoryProvider.overrideWithValue(fakeSymptoms),
              cycleRepositoryProvider.overrideWithValue(fakeCycles),
              treatmentRepositoryProvider.overrideWithValue(fakeTreatments),
              appointmentRepositoryProvider.overrideWithValue(fakeAppointments),
              impactLogRepositoryProvider.overrideWithValue(fakeImpact),
              reminderSchedulerProvider.overrideWithValue(fakeScheduler),
              homeClockProvider.overrideWithValue(() => today),
            ],
            child: const EndoCareApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Navega para a aba central Registrar e abre o Mapa Corporal
        await tester.tap(find.text('Registrar'));
        await tester.pumpAndSettle();

        final openBodyMapBtn = find.text('Abrir mapa corporal');
        await tester.ensureVisible(openBodyMapBtn);
        await tester.tap(openBodyMapBtn);
        await tester.pumpAndSettle();

        expect(find.text('Mapa corporal da dor'), findsOneWidget);

        // 1. Atualiza a região frontal pré-carregada ("pelve_central")
        final pelveCentralZone =
            find.byKey(const ValueKey('body_region_pelve_central'));
        await tester.ensureVisible(pelveCentralZone);
        await tester.tap(pelveCentralZone);
        await tester.pumpAndSettle();

        final painTypeChip = find.text('Pontada / Fisgada');
        await tester.ensureVisible(painTypeChip);
        await tester.tap(painTypeChip);
        await tester.pump();

        final durationChip = find.text('Dia todo');
        await tester.ensureVisible(durationChip);
        await tester.tap(durationChip);
        await tester.pump();

        final updateRegionBtn = find.text('Atualizar região');
        await tester.ensureVisible(updateRegionBtn);
        await tester.tap(updateRegionBtn);
        await tester.pumpAndSettle();

        // 2. Alterna para Costas e adiciona "lombar_central"
        final backSideChip = find.text('Costas');
        await tester.ensureVisible(backSideChip);
        await tester.tap(backSideChip);
        await tester.pumpAndSettle();

        final lombarZone =
            find.byKey(const ValueKey('body_region_lombar_central'));
        await tester.ensureVisible(lombarZone);
        await tester.tap(lombarZone);
        await tester.pumpAndSettle();

        final frequencyChip = find.text('Constante');
        await tester.ensureVisible(frequencyChip);
        await tester.tap(frequencyChip);
        await tester.pump();

        final confirmRegionBtn = find.text('Confirmar região');
        await tester.ensureVisible(confirmRegionBtn);
        await tester.tap(confirmRegionBtn);
        await tester.pumpAndSettle();

        // 3. Salva o mapa corporal (2 regiões: Frente + Costas)
        await tester.tap(find.text('Salvar mapa corporal (2)'));
        await tester.pumpAndSettle();

        final savedToday = fakeSymptoms.logFor('uid_clara', today);
        expect(savedToday, isNotNull);
        expect(savedToday!.mapaCorporal.length, 2);
        expect(
          savedToday.regioes,
          containsAll(['Pelve central / Útero', 'Lombar central']),
        );
        final savedPelve = savedToday.mapaCorporal.firstWhere(
          (e) => e.regionId == 'pelve_central',
        );
        expect(savedPelve.tipoDor, 'Pontada / Fisgada');
        expect(savedPelve.duracao, 'Dia todo');
        final savedLombar = savedToday.mapaCorporal.firstWhere(
          (e) => e.regionId == 'lombar_central',
        );
        expect(savedLombar.frequencia, 'Constante');

        // 4. Alterna para "Heatmap histórico" e verifica regiões salvas no histórico
        await tester.tap(find.text('Heatmap histórico'));
        await tester.pumpAndSettle();

        expect(
          find.text('Baseado em 2 dias com mapa registrado'),
          findsOneWidget,
        );
        expect(find.text('Pelve central / Útero • Frente'), findsOneWidget);
        expect(find.text('Lombar central • Costas'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('heatmap_region_lombar_central')),
          findsOneWidget,
        );
      },
    );
  });

  group('Calendário e ciclo — Etapa 5', () {
    test(
      'CyclePredictionEngine calcula média do ciclo, próxima menstruação, ovulação estimada e ignora escapes isolados',
      () {
        final entries = [
          // Ciclo 1: início em 2026-09-01 (4 dias de fluxo)
          for (var d = 1; d <= 4; d++)
            CycleEntry(
              id: '2026-09-0$d',
              data: DateTime(2026, 9, d),
              fluxo: MenstrualFlowLevel.moderate,
            ),
          // Escape isolado no meio do ciclo NÃO deve reiniciar contagem
          CycleEntry(
            id: '2026-09-16',
            data: DateTime(2026, 9, 16),
            fluxo: MenstrualFlowLevel.spotting,
          ),
          // Ciclo 2: início em 2026-09-30 (intervalo de 29 dias)
          for (var d = 0; d < 4; d++)
            CycleEntry(
              id: SymptomLog.dateKeyFor(
                DateTime(2026, 9, 30).add(Duration(days: d)),
              ),
              data: DateTime(2026, 9, 30).add(Duration(days: d)),
              fluxo: MenstrualFlowLevel.heavy,
            ),
          // Ciclo 3: início em 2026-10-30 (intervalo de 30 dias -> média arredondada = 30)
          for (var d = 0; d < 4; d++)
            CycleEntry(
              id: SymptomLog.dateKeyFor(
                DateTime(2026, 10, 30).add(Duration(days: d)),
              ),
              data: DateTime(2026, 10, 30).add(Duration(days: d)),
              fluxo: MenstrualFlowLevel.moderate,
            ),
        ];

        final estimate = CyclePredictionEngine.compute(
          entries: entries,
          referenceDate: DateTime(2026, 11, 2),
        );

        expect(estimate.periodStarts.length, 3);
        expect(estimate.usesDefaultCycleLength, isFalse);
        expect(estimate.averageCycleLength, 30);
        expect(estimate.averagePeriodDuration, 4);
        expect(estimate.currentCycleDay, 4);
        expect(estimate.nextPredictedPeriodStart, DateTime(2026, 11, 29));
        expect(estimate.nextEstimatedOvulationDate, DateTime(2026, 11, 15));
        expect(
          estimate.isEstimatedOvulationDay(DateTime(2026, 11, 15)),
          isTrue,
        );
        expect(
          estimate.isEstimatedFertileWindow(DateTime(2026, 11, 13)),
          isTrue,
        );
        expect(
          CyclePredictionEngine.approximateDisclaimer,
          contains('estimativas aproximadas'),
        );
      },
    );

    testWidgets(
      'Exibe juntos no calendário dados dos módulos 3 e 5, estimativa aproximada e gráficos fl_chart sem afirmar causalidade',
      (WidgetTester tester) async {
        const verifiedUser = AppAuthUser(
          uid: 'uid_helena',
          email: 'helena@exemplo.com',
          emailVerified: true,
          displayName: 'Helena Costa',
        );
        final fakeProfiles = FakeUserProfileRepository()
          ..seedUser(
            const UserProfile(
              uid: 'uid_helena',
              email: 'helena@exemplo.com',
              nome: 'Helena Costa',
              preferencias: UserPreferences(onboardingConcluido: true),
            ),
          );
        final fakeAuth = FakeAuthRepository(
          fakeProfiles,
          initialUser: verifiedUser,
        );
        final fakeOnboarding = FakeOnboardingStorage(initialCompleted: true);

        final today = DateTime(2026, 11, 2, 11, 0);
        final fakeSymptoms = FakeSymptomLogRepository()
          // Sintomas e crise no dia 02/11 (Módulo 3 + Módulo 4)
          ..seedLog(
            'uid_helena',
            SymptomLog(
              id: '2026-11-02',
              data: DateTime(2026, 11, 2),
              dor: 8,
              sono: 5,
              humor: 'Cansada',
              tipos: const ['Cólica', 'Fadiga'],
              regioes: const ['Pelve central / Útero'],
            ),
          )
          // Dor registrada fora do fluxo menstrual (dia 12/11)
          ..seedLog(
            'uid_helena',
            SymptomLog(
              id: '2026-11-12',
              data: DateTime(2026, 11, 12),
              dor: 5,
              sono: 7,
              tipos: const ['Dor lombar'],
            ),
          );

        final fakeCycles = FakeCycleRepository();
        // Ciclo anterior iniciado 28 dias atrás (05/10 a 08/10) -> projeta
        // previsão de menstruação para 02/11 antes mesmo do registro manual de hoje!
        for (var d = 5; d <= 8; d++) {
          fakeCycles.seedEntry(
            'uid_helena',
            CycleEntry(
              id: '2026-10-0$d',
              data: DateTime(2026, 10, d),
              fluxo: MenstrualFlowLevel.moderate,
            ),
          );
        }
        final fakeTreatments = FakeTreatmentRepository();
        final fakeAppointments = FakeAppointmentRepository();
        final fakeImpact = FakeImpactLogRepository();
        final fakeScheduler = FakeReminderScheduler();

        addTearDown(() {
          fakeAuth.dispose();
          fakeProfiles.dispose();
          fakeSymptoms.dispose();
          fakeCycles.dispose();
          fakeTreatments.dispose();
          fakeAppointments.dispose();
          fakeImpact.dispose();
          fakeScheduler.dispose();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingStorageProvider.overrideWithValue(fakeOnboarding),
              userProfileRepositoryProvider.overrideWithValue(fakeProfiles),
              authRepositoryProvider.overrideWithValue(fakeAuth),
              symptomLogRepositoryProvider.overrideWithValue(fakeSymptoms),
              cycleRepositoryProvider.overrideWithValue(fakeCycles),
              treatmentRepositoryProvider.overrideWithValue(fakeTreatments),
              appointmentRepositoryProvider.overrideWithValue(fakeAppointments),
              impactLogRepositoryProvider.overrideWithValue(fakeImpact),
              reminderSchedulerProvider.overrideWithValue(fakeScheduler),
              homeClockProvider.overrideWithValue(() => today),
            ],
            child: const EndoCareApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Abre a aba Calendário
        await tester.tap(find.byIcon(Icons.calendar_month_outlined));
        await tester.pumpAndSettle();

        // Confirma exibição conjunta: previsão do ciclo (Módulo 5) + sintomas/dor (Módulo 3)
        expect(find.text('Previsão de menstruação'), findsOneWidget);
        expect(find.text('Crise de sintomas'), findsOneWidget);
        expect(find.text('Dor 8/10 • Intensa'), findsOneWidget);
        expect(find.text('Sintomas: Cólica, Fadiga'), findsOneWidget);
        expect(
          find.text('Regiões de dor: Pelve central / Útero'),
          findsOneWidget,
        );

        // Registra fluxo menstrual real, medicamento e consulta em 02/11
        final editCycleBtn = find.text('Marcar fluxo ou evento');
        await tester.ensureVisible(editCycleBtn);
        await tester.tap(editCycleBtn);
        await tester.pumpAndSettle();

        final heavyFlowChip = find.text('Intenso');
        await tester.ensureVisible(heavyFlowChip);
        await tester.tap(heavyFlowChip);
        await tester.pump();

        final medChip = find.text('Anti-inflamatório');
        await tester.ensureVisible(medChip);
        await tester.tap(medChip);
        await tester.pump();

        final apptChip = find.text('Consulta ginecológica');
        await tester.ensureVisible(apptChip);
        await tester.tap(apptChip);
        await tester.pump();

        final saveCalendarBtn = find.text('Salvar no calendário');
        await tester.ensureVisible(saveCalendarBtn);
        await tester.tap(saveCalendarBtn);
        await tester.pumpAndSettle();

        // Verifica persistência em `cycleEntries/2026-11-02`
        final savedCycle = fakeCycles.entryFor('uid_helena', today);
        expect(savedCycle, isNotNull);
        expect(savedCycle!.fluxo, MenstrualFlowLevel.heavy);
        expect(savedCycle.medicamentos, contains('Anti-inflamatório'));
        expect(savedCycle.consultaOuExame, 'Consulta ginecológica');

        // Confirma detalhe unificado exibindo Módulos 3 e 5 juntos
        expect(find.text('Fluxo intenso'), findsOneWidget);
        expect(find.text('Medicamentos: Anti-inflamatório'), findsOneWidget);
        expect(
          find.text('Consulta / exame: Consulta ginecológica'),
          findsOneWidget,
        );
        expect(find.text('Dor 8/10 • Intensa'), findsOneWidget);

        // Confirma cartão de estimativa aproximada e gráficos fl_chart sem causalidade
        expect(find.text('Estimativa do ciclo e ovulação'), findsOneWidget);
        expect(
          find.textContaining('estimativas aproximadas'),
          findsOneWidget,
        );
        expect(
          find.textContaining('sem afirmar causa e efeito'),
          findsOneWidget,
        );
        expect(
          find.textContaining('1 com dor fora do fluxo'),
          findsOneWidget,
        );
        expect(find.byType(LineChart), findsOneWidget);
        expect(find.byType(BarChart), findsOneWidget);

        // Seleciona o dia estimado de ovulação (16/11: 30/11 previsto - 14 dias)
        final ovulationCell =
            find.byKey(const ValueKey('calendar_day_2026-11-16'));
        await tester.ensureVisible(ovulationCell);
        await tester.tap(ovulationCell);
        await tester.pumpAndSettle();
        // Há tanto o rótulo "Ovulação estimada" no cartão de métricas quanto a pílula no detalhe do dia
        expect(find.text('Ovulação estimada'), findsNWidgets(2));

        // Volta ao Início e confirma sincronização do card de Ciclo
        await tester.tap(find.text('Início'));
        await tester.pumpAndSettle();
        expect(find.text('Fluxo intenso'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'Fluxo completo: primeiro acesso deslogado (Onboarding) -> Cadastro -> Verificação -> Início -> Logout -> Login',
    (WidgetTester tester) async {
      final fakeProfiles = FakeUserProfileRepository()
        ..seedUser(
          const UserProfile(
            uid: 'uid_outra_usuaria',
            email: 'outra@exemplo.com',
            nome: 'Beatriz Outra',
          ),
        );
      final fakeAuth = FakeAuthRepository(fakeProfiles);
      final fakeOnboarding = FakeOnboardingStorage(initialCompleted: false);
      final fakeSymptoms = FakeSymptomLogRepository();
      final fakeCycles = FakeCycleRepository();
      final fakeTreatments = FakeTreatmentRepository();
      final fakeAppointments = FakeAppointmentRepository();
      final fakeImpact = FakeImpactLogRepository();
      final fakeScheduler = FakeReminderScheduler();
      addTearDown(() {
        fakeAuth.dispose();
        fakeProfiles.dispose();
        fakeSymptoms.dispose();
        fakeCycles.dispose();
        fakeTreatments.dispose();
        fakeAppointments.dispose();
        fakeImpact.dispose();
        fakeScheduler.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingStorageProvider.overrideWithValue(fakeOnboarding),
            userProfileRepositoryProvider.overrideWithValue(fakeProfiles),
            authRepositoryProvider.overrideWithValue(fakeAuth),
            symptomLogRepositoryProvider.overrideWithValue(fakeSymptoms),
            cycleRepositoryProvider.overrideWithValue(fakeCycles),
            treatmentRepositoryProvider.overrideWithValue(fakeTreatments),
            appointmentRepositoryProvider.overrideWithValue(fakeAppointments),
            impactLogRepositoryProvider.overrideWithValue(fakeImpact),
            reminderSchedulerProvider.overrideWithValue(fakeScheduler),
            homeClockProvider.overrideWithValue(
              () => DateTime(2026, 11, 2, 10, 0),
            ),
          ],
          child: const EndoCareApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Passo 1 de 3'), findsOneWidget);
      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      expect(find.text('Que bom ter você aqui'), findsOneWidget);

      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();
      expect(find.text('Recuperar senha'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'mariana@exemplo.com',
      );
      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pumpAndSettle();
      expect(find.text('Confira seu e-mail'), findsOneWidget);
      expect(fakeAuth.passwordResetEmailsSent, contains('mariana@exemplo.com'));

      final backToLogin = find.text('Voltar para o login');
      await tester.ensureVisible(backToLogin);
      await tester.tap(backToLogin);
      await tester.pumpAndSettle();

      final createAccountLink = find.text('Criar minha conta');
      await tester.ensureVisible(createAccountLink);
      await tester.tap(createAccountLink);
      await tester.pumpAndSettle();
      expect(find.text('Crie sua conta'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Mariana Silva');
      await tester.enterText(fields.at(1), 'mariana@exemplo.com');
      await tester.enterText(fields.at(2), 'senha123');
      await tester.enterText(fields.at(3), 'senha123');

      final checkboxFinder = find.byType(Checkbox);
      await tester.ensureVisible(checkboxFinder);
      await tester.tap(checkboxFinder);
      await tester.pump();

      final submitRegister = find.widgetWithText(
        ElevatedButton,
        'Criar minha conta',
      );
      await tester.ensureVisible(submitRegister);
      await tester.tap(submitRegister);
      await tester.pumpAndSettle();

      final createdUid = fakeAuth.currentUser!.uid;
      expect(fakeProfiles.profileFor(createdUid)?.nome, 'Mariana Silva');
      expect(fakeAuth.verificationEmailsSent, 1);

      expect(find.text('Confirme seu e-mail'), findsOneWidget);

      fakeAuth.nextReloadMarksEmailVerified = true;
      final confirmEmailBtn = find.text('Já confirmei meu e-mail');
      await tester.ensureVisible(confirmEmailBtn);
      await tester.tap(confirmEmailBtn);
      await tester.pumpAndSettle();

      expect(find.text('Bom dia, Mariana'), findsOneWidget);
      expect(find.textContaining('Beatriz'), findsNothing);

      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();
      expect(find.text('Mariana Silva'), findsOneWidget);
      expect(find.text('mariana@exemplo.com'), findsOneWidget);
      expect(find.text('outra@exemplo.com'), findsNothing);

      final signOutBtn = find.text('Sair da conta');
      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();
      expect(find.text('Que bom ter você aqui'), findsOneWidget);

      final loginFields = find.byType(TextFormField);
      await tester.enterText(loginFields.at(0), 'mariana@exemplo.com');
      await tester.enterText(loginFields.at(1), 'senha123');
      final loginSubmitBtn = find.widgetWithText(ElevatedButton, 'Entrar');
      await tester.ensureVisible(loginSubmitBtn);
      await tester.tap(loginSubmitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Bom dia, Mariana'), findsOneWidget);
    },
  );

  group('Gestão de tratamentos e consultas — Etapa 6', () {
    test(
      'agenda lembretes ativos, ignora histórico encerrado e dispara exatamente no horário configurado',
      () async {
        final scheduler = FakeReminderScheduler();
        addTearDown(scheduler.dispose);

        final treatments = [
          Treatment(
            id: 'treat_1',
            medicamento: 'Dienogeste',
            dose: '2 mg',
            horarios: const ['08:00', '20:00'],
            inicio: DateTime(2026, 11, 1),
            ativo: true,
            lembretesAtivos: true,
          ),
          Treatment(
            id: 'treat_2',
            medicamento: 'Ibuprofeno',
            horarios: const ['12:00'],
            inicio: DateTime(2026, 10, 1),
            fim: DateTime(2026, 10, 15),
            ativo: false,
            lembretesAtivos: false,
          ),
        ];

        final appointments = [
          MedicalAppointment(
            id: 'appt_1',
            tipo: AppointmentType.exam,
            titulo: 'Ressonância magnética pélvica',
            data: DateTime(2026, 11, 3, 15, 0),
            local: 'Centro Diagnóstico',
            status: AppointmentStatus.scheduled,
            lembreteAntecedenciaMinutos: 60,
          ),
          MedicalAppointment(
            id: 'appt_2',
            tipo: AppointmentType.procedure,
            titulo: 'Videolaparoscopia',
            data: DateTime(2026, 10, 10, 8, 0),
            status: AppointmentStatus.completed,
            lembreteAntecedenciaMinutos: 60,
          ),
        ];

        final now = DateTime(2026, 11, 2, 19, 30);
        await scheduler.syncAllSchedules(
          treatments: treatments,
          appointments: appointments,
          now: now,
        );

        expect(scheduler.activeSchedules.length, 3);
        expect(
          scheduler.activeSchedules[0].scheduledAt,
          DateTime(2026, 11, 2, 20, 0),
        );
        expect(
          scheduler.activeSchedules[1].scheduledAt,
          DateTime(2026, 11, 3, 8, 0),
        );
        expect(
          scheduler.activeSchedules[2].scheduledAt,
          DateTime(2026, 11, 3, 14, 0),
        );

        // Antes do horário configurado (19:59): nada dispara
        final beforeDue = await scheduler.evaluateAndFireDue(
          treatments: treatments,
          appointments: appointments,
          previousCheck: DateTime(2026, 11, 2, 19, 58),
          currentTime: DateTime(2026, 11, 2, 19, 59),
        );
        expect(beforeDue, isEmpty);

        // Exatamente no horário configurado do medicamento (20:00): dispara!
        final medDue = await scheduler.evaluateAndFireDue(
          treatments: treatments,
          appointments: appointments,
          previousCheck: DateTime(2026, 11, 2, 19, 59),
          currentTime: DateTime(2026, 11, 2, 20, 0),
        );
        expect(medDue.length, 1);
        expect(medDue.first.title, 'Hora do seu cuidado: Dienogeste');
        expect(medDue.first.body, 'Horário das 20:00 (2 mg).');

        // Reavaliação da mesma janela não duplica disparo
        final duplicateCheck = await scheduler.evaluateAndFireDue(
          treatments: treatments,
          appointments: appointments,
          previousCheck: DateTime(2026, 11, 2, 19, 59),
          currentTime: DateTime(2026, 11, 2, 20, 0),
        );
        expect(duplicateCheck, isEmpty);

        // Exatamente no horário configurado da antecedência do exame (14:00 para exame às 15:00): dispara!
        final apptDue = await scheduler.evaluateAndFireDue(
          treatments: treatments,
          appointments: appointments,
          previousCheck: DateTime(2026, 11, 3, 13, 59),
          currentTime: DateTime(2026, 11, 3, 14, 0),
        );
        expect(apptDue.length, 1);
        expect(apptDue.first.title, 'Exame: Ressonância magnética pélvica');
        expect(scheduler.firedReminders.length, 2);
      },
    );

    testWidgets(
      'CRUD de medicamentos, horários, efeitos percebidos, histórico, consultas/procedimentos, push FCM e disparo no horário configurado',
      (WidgetTester tester) async {
        const verifiedUser = AppAuthUser(
          uid: 'uid_sofia',
          email: 'sofia@exemplo.com',
          emailVerified: true,
          displayName: 'Sofia Ribeiro',
        );
        final fakeProfiles = FakeUserProfileRepository()
          ..seedUser(
            const UserProfile(
              uid: 'uid_sofia',
              email: 'sofia@exemplo.com',
              nome: 'Sofia Ribeiro',
              preferencias: UserPreferences(onboardingConcluido: true),
            ),
          );
        final fakeAuth = FakeAuthRepository(
          fakeProfiles,
          initialUser: verifiedUser,
        );
        final fakeOnboarding = FakeOnboardingStorage(initialCompleted: true);
        final fakeSymptoms = FakeSymptomLogRepository();
        final fakeCycles = FakeCycleRepository();
        final fakeTreatments = FakeTreatmentRepository();
        final fakeAppointments = FakeAppointmentRepository();
        final fakeImpact = FakeImpactLogRepository();
        final fakeScheduler = FakeReminderScheduler();
        final today = DateTime(2026, 11, 2, 19, 30);

        addTearDown(() {
          fakeAuth.dispose();
          fakeProfiles.dispose();
          fakeSymptoms.dispose();
          fakeCycles.dispose();
          fakeTreatments.dispose();
          fakeAppointments.dispose();
          fakeImpact.dispose();
          fakeScheduler.dispose();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingStorageProvider.overrideWithValue(fakeOnboarding),
              userProfileRepositoryProvider.overrideWithValue(fakeProfiles),
              authRepositoryProvider.overrideWithValue(fakeAuth),
              symptomLogRepositoryProvider.overrideWithValue(fakeSymptoms),
              cycleRepositoryProvider.overrideWithValue(fakeCycles),
              treatmentRepositoryProvider.overrideWithValue(fakeTreatments),
              appointmentRepositoryProvider.overrideWithValue(fakeAppointments),
              impactLogRepositoryProvider.overrideWithValue(fakeImpact),
              reminderSchedulerProvider.overrideWithValue(fakeScheduler),
              homeClockProvider.overrideWithValue(() => today),
            ],
            child: const EndoCareApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Navega para a aba Cuidar e sincroniza permissões locais + token push FCM
        await tester.tap(find.text('Cuidar'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sincronizar alertas'));
        await tester.pumpAndSettle();
        expect(
          fakeProfiles.profileFor('uid_sofia')?.fcmTokens,
          contains('fcm_token_cuidar_test'),
        );

        // 2. Cadastra medicamento contínuo Dienogeste com horário das 20:00
        await tester.tap(find.text('Novo medicamento'));
        await tester.pumpAndSettle();

        final medFields = find.byType(TextFormField);
        await tester.enterText(medFields.at(0), 'Dienogeste');
        await tester.enterText(medFields.at(1), '2 mg');

        final slot20Chip = find.text('20:00');
        await tester.ensureVisible(slot20Chip);
        await tester.pumpAndSettle();
        await tester.tap(slot20Chip);
        await tester.pump();

        final saveTreatmentBtn = find.text('Salvar tratamento');
        await tester.ensureVisible(saveTreatmentBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveTreatmentBtn);
        await tester.pumpAndSettle();

        expect(find.text('Em uso atualmente (1)'), findsOneWidget);
        expect(find.text('Dienogeste'), findsOneWidget);
        expect(find.text('Horário 20:00'), findsOneWidget);
        expect(
          fakeScheduler.activeSchedules.any(
            (r) =>
                r.kind == ReminderKind.medication &&
                r.scheduledAt == DateTime(2026, 11, 2, 20, 0),
          ),
          isTrue,
        );

        // 3. Registra efeito percebido do medicamento
        final logEffectBtn = find.text('Registrar efeito');
        await tester.ensureVisible(logEffectBtn);
        await tester.pumpAndSettle();
        await tester.tap(logEffectBtn);
        await tester.pumpAndSettle();

        final reliefChip = find.text('Redução da cólica');
        await tester.ensureVisible(reliefChip);
        await tester.pumpAndSettle();
        await tester.tap(reliefChip);
        await tester.pump();

        final saveEffectBtn = find.text('Salvar efeito percebido');
        await tester.ensureVisible(saveEffectBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveEffectBtn);
        await tester.pumpAndSettle();

        expect(find.text('Efeitos percebidos (1)'), findsOneWidget);
        expect(find.text('Redução da cólica • Dienogeste'), findsOneWidget);

        // 4. Simula chegada do horário configurado (20:00) e verifica banner de disparo ao vivo
        final fired = await fakeScheduler.evaluateAndFireDue(
          treatments: fakeTreatments.treatmentsFor('uid_sofia'),
          appointments: fakeAppointments.appointmentsFor('uid_sofia'),
          previousCheck: DateTime(2026, 11, 2, 19, 59),
          currentTime: DateTime(2026, 11, 2, 20, 0),
        );
        expect(fired.length, 1);
        await tester.pumpAndSettle();

        expect(find.text('Hora do seu cuidado: Dienogeste'), findsOneWidget);
        expect(find.text('Horário das 20:00 (2 mg).'), findsOneWidget);

        // 5. Alterna para "Consultas e exames", agenda consulta e registra procedimento cirúrgico
        final appointmentsTab = find.text('Consultas e exames');
        await tester.ensureVisible(appointmentsTab);
        await tester.pumpAndSettle();
        await tester.tap(appointmentsTab);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Agendar consulta / exame'));
        await tester.pumpAndSettle();

        final gynChip = find.text('Ginecologista especialista');
        await tester.ensureVisible(gynChip);
        await tester.pumpAndSettle();
        await tester.tap(gynChip);
        await tester.pump();

        final apptFields = find.byType(TextFormField);
        await tester.ensureVisible(apptFields.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(apptFields.at(1), 'Clínica Mulher');

        final saveApptBtn = find.text('Salvar agendamento');
        await tester.ensureVisible(saveApptBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveApptBtn);
        await tester.pumpAndSettle();

        expect(find.text('Próximos agendamentos (1)'), findsOneWidget);
        expect(find.text('Ginecologista especialista'), findsOneWidget);

        final registerProcBtn = find.text('Registrar procedimento');
        await tester.ensureVisible(registerProcBtn);
        await tester.pumpAndSettle();
        await tester.tap(registerProcBtn);
        await tester.pumpAndSettle();

        final procChip = find.text('Videolaparoscopia');
        await tester.ensureVisible(procChip);
        await tester.pumpAndSettle();
        await tester.tap(procChip);
        await tester.pump();

        final completedStatusChip = find.text('Realizado');
        await tester.ensureVisible(completedStatusChip);
        await tester.pumpAndSettle();
        await tester.tap(completedStatusChip);
        await tester.pump();

        final saveProcBtn = find.text('Salvar agendamento');
        await tester.ensureVisible(saveProcBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveProcBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Histórico clínico e procedimentos (1)'),
          findsOneWidget,
        );
        expect(
          find.text('Procedimento / Cirurgia: Videolaparoscopia'),
          findsOneWidget,
        );

        // 6. Conclui/arquiva Dienogeste para o histórico de tratamentos e confirma remoção dos lembretes dele
        final medsTab = find.text('Medicamentos');
        await tester.ensureVisible(medsTab);
        await tester.pumpAndSettle();
        await tester.tap(medsTab);
        await tester.pumpAndSettle();

        final archiveBtn = find.text('Concluir');
        await tester.ensureVisible(archiveBtn);
        await tester.pumpAndSettle();
        await tester.tap(archiveBtn);
        await tester.pumpAndSettle();

        expect(find.text('Em uso atualmente (0)'), findsOneWidget);
        expect(find.text('Histórico de tratamentos (1)'), findsOneWidget);
        expect(
          fakeScheduler.activeSchedules
              .where((r) => r.kind == ReminderKind.medication),
          isEmpty,
        );

        // 7. Confirma sincronização ao vivo em Início ("Próximos lembretes") e no Calendário (dia 05/11)
        await tester.tap(find.text('Início'));
        await tester.pumpAndSettle();
        expect(
          find.text('Consulta: Ginecologista especialista'),
          findsOneWidget,
        );

        await tester.tap(find.byIcon(Icons.calendar_month_outlined));
        await tester.pumpAndSettle();
        final apptCalendarDay =
            find.byKey(const ValueKey('calendar_day_2026-11-05'));
        await tester.ensureVisible(apptCalendarDay);
        await tester.tap(apptCalendarDay);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Consulta: Ginecologista especialista'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Videolaparoscopia'),
          findsOneWidget,
        );
      },
    );
  });

  group('Diário de impacto e linha do tempo — Etapa 7', () {
    test(
      'ImpactLog, Firestore serialization e ImpactSummary.aggregate calculam estatísticas dos últimos 30 dias',
      () {
        final date = DateTime(2026, 11, 2);
        final log = ImpactLog(
          id: '2026-11-02',
          data: date,
          niveis: {
            ImpactArea.work: 8,
            ImpactArea.sleep: 9,
            ImpactArea.exercise: 6,
            ImpactArea.routine: 4,
          },
          notas: 'Impacto severo no sono devido à dor noturna',
        );

        expect(log.hasAnyLevel, isTrue);
        expect(log.isHighImpact, isTrue);
        expect(log.highImpactAreas.map((e) => e.key), [
          ImpactArea.sleep,
          ImpactArea.work,
        ]);
        expect(log.averageLevel, closeTo(6.75, 0.01));
        expect(ImpactLog.levelLabel(0), 'Sem impacto');
        expect(ImpactLog.levelLabel(3), 'Leve');
        expect(ImpactLog.levelLabel(5), 'Moderado');
        expect(ImpactLog.levelLabel(8), 'Alto');
        expect(ImpactLog.levelLabel(10), 'Muito alto');

        final firestoreMap = log.toFirestoreMap();
        expect(firestoreMap['trabalho'], 8);
        expect(firestoreMap['sono'], 9);
        expect(firestoreMap['exercicio'], 6);
        expect(firestoreMap['rotina'], 4);
        expect(firestoreMap['estudos'], isNull);
        expect(firestoreMap['relacionamentos'], isNull);
        expect(firestoreMap['notas'], 'Impacto severo no sono devido à dor noturna');

        final restored = ImpactLog.fromFirestore(firestoreMap, id: '2026-11-02');
        expect(restored.id, '2026-11-02');
        expect(restored.niveis[ImpactArea.work], 8);
        expect(restored.niveis[ImpactArea.sleep], 9);
        expect(restored.notas, 'Impacto severo no sono devido à dor noturna');

        // Teste de agregação dos últimos 30 dias
        final logs = [
          log,
          ImpactLog(
            id: '2026-10-30',
            data: DateTime(2026, 10, 30),
            niveis: {
              ImpactArea.work: 7,
              ImpactArea.sleep: 5,
              ImpactArea.routine: 2,
            },
          ),
          ImpactLog(
            id: '2026-10-25',
            data: DateTime(2026, 10, 25),
            niveis: {
              ImpactArea.work: 4,
              ImpactArea.exercise: 3,
            },
          ),
          // Fora da janela de 30 dias
          ImpactLog(
            id: '2026-09-01',
            data: DateTime(2026, 9, 1),
            niveis: {ImpactArea.work: 10},
          ),
        ];

        final summary = ImpactSummary.aggregate(
          logs: logs,
          referenceDate: date,
          periodDays: 30,
        );

        expect(summary.periodDays, 30);
        expect(summary.daysLogged, 3);
        expect(summary.highImpactDays, 2); // 02/11 (sono 9, trab 8) e 30/10 (trab 7)

        final workStats =
            summary.areaStats.firstWhere((s) => s.area == ImpactArea.work);
        expect(workStats.daysRegistered, 3);
        expect(workStats.average, closeTo(6.33, 0.05));
        expect(workStats.highImpactDays, 2);

        // O topo da lista deve ser Sono ou Trabalho
        expect(
          [ImpactArea.sleep, ImpactArea.work].contains(summary.areaStats.first.area),
          isTrue,
        );
      },
    );

    test(
      'TimelineBuilder unifica todos os módulos em ordem cronológica (crises, consultas, cirurgias, tratamentos, sintomas, ciclo, impacto)',
      () {
        final now = DateTime(2026, 11, 2, 12, 0);

        // 1. Crises: 2 dias consecutivos com dor >= 7
        final symptomLogs = [
          SymptomLog(
            id: 's_1',
            data: DateTime(2026, 10, 10),
            dor: 8,
            tipos: const ['cólica menstrual', 'dor lombar'],
          ),
          SymptomLog(
            id: 's_2',
            data: DateTime(2026, 10, 11),
            dor: 9,
            tipos: const ['cólica menstrual'],
          ),
          // Semana 1 (média 3.0)
          SymptomLog(
            id: 's_3',
            data: DateTime(2026, 10, 19),
            dor: 3,
            tipos: const ['dor leve'],
          ),
          // Semana 2 (média 6.0) -> Variação de dor delta >= 2
          SymptomLog(
            id: 's_4',
            data: DateTime(2026, 10, 26),
            dor: 6,
            tipos: const ['cólica irradiada'],
          ),
        ];

        // 2. Ciclo: início da menstruação
        final cycleEntries = [
          CycleEntry(
            id: 'c_1',
            data: DateTime(2026, 10, 10),
            fluxo: MenstrualFlowLevel.heavy,
          ),
          CycleEntry(
            id: 'c_2',
            data: DateTime(2026, 10, 11),
            fluxo: MenstrualFlowLevel.moderate,
          ),
        ];

        // 3. Tratamentos e efeitos
        final treatments = [
          Treatment(
            id: 't_dienogeste',
            medicamento: 'Dienogeste',
            dose: '2mg',
            categoria: TreatmentCategory.hormonal,
            inicio: DateTime(2026, 9, 15),
            horarios: const ['08:00'],
            ativo: true,
          ),
        ];
        final effects = [
          TreatmentEffect(
            id: 'eff_1',
            treatmentId: 't_dienogeste',
            treatmentName: 'Dienogeste',
            data: DateTime(2026, 10, 1),
            efeito: 'Redução do sangramento',
            tipo: TreatmentEffectKind.relief,
            intensidade: 8,
          ),
        ];

        // 4. Consultas e Cirurgias
        final appointments = [
          MedicalAppointment(
            id: 'appt_laparo',
            tipo: AppointmentType.procedure,
            titulo: 'Videolaparoscopia diagnóstica',
            data: DateTime(2026, 9, 20, 9, 0),
            local: 'Hospital São Lucas',
            status: AppointmentStatus.completed,
          ),
          MedicalAppointment(
            id: 'appt_consulta',
            tipo: AppointmentType.consultation,
            titulo: 'Retorno com ginecologista',
            data: DateTime(2026, 11, 10, 14, 0),
            local: 'Clínica Mulher',
            status: AppointmentStatus.scheduled,
          ),
        ];

        // 5. Diário de impacto
        final impactLogs = [
          ImpactLog(
            id: '2026-10-10',
            data: DateTime(2026, 10, 10),
            niveis: {
              ImpactArea.work: 9,
              ImpactArea.sleep: 8,
            },
          ),
        ];

        // Constrói a linha do tempo mais recentes primeiro
        final eventsNewestFirst = TimelineBuilder.build(
          now: now,
          symptomLogs: symptomLogs,
          cycleEntries: cycleEntries,
          treatments: treatments,
          treatmentEffects: effects,
          appointments: appointments,
          impactLogs: impactLogs,
          newestFirst: true,
        );

        expect(eventsNewestFirst, isNotEmpty);

        // Confirma que todos os módulos geraram eventos
        final categories = eventsNewestFirst.map((e) => e.category).toSet();
        expect(categories.contains(TimelineCategory.crisis), isTrue);
        expect(categories.contains(TimelineCategory.appointments), isTrue);
        expect(categories.contains(TimelineCategory.procedures), isTrue);
        expect(categories.contains(TimelineCategory.treatments), isTrue);
        expect(categories.contains(TimelineCategory.symptoms), isTrue);
        expect(categories.contains(TimelineCategory.cycle), isTrue);
        expect(categories.contains(TimelineCategory.impact), isTrue);

        // Confirma ordenação cronológica decrescente (mais recente primeiro)
        for (var i = 0; i < eventsNewestFirst.length - 1; i++) {
          final a = eventsNewestFirst[i].date;
          final b = eventsNewestFirst[i + 1].date;
          expect(
            a.isAfter(b) || a.isAtSameMomentAs(b),
            isTrue,
            reason: 'Evento $i (${eventsNewestFirst[i].title}) anterior a $b',
          );
        }

        // Confirma ordenação crescente (mais antigo primeiro)
        final eventsOldestFirst = TimelineBuilder.build(
          now: now,
          symptomLogs: symptomLogs,
          cycleEntries: cycleEntries,
          treatments: treatments,
          treatmentEffects: effects,
          appointments: appointments,
          impactLogs: impactLogs,
          newestFirst: false,
        );
        for (var i = 0; i < eventsOldestFirst.length - 1; i++) {
          final a = eventsOldestFirst[i].date;
          final b = eventsOldestFirst[i + 1].date;
          expect(
            a.isBefore(b) || a.isAtSameMomentAs(b),
            isTrue,
            reason: 'Evento $i (${eventsOldestFirst[i].title}) posterior a $b',
          );
        }

        // Confirma filtro por categoria
        final onlyCrises = TimelineBuilder.filter(
          eventsNewestFirst,
          categories: {TimelineCategory.crisis},
        );
        expect(onlyCrises, isNotEmpty);
        expect(
          onlyCrises.every((e) => e.category == TimelineCategory.crisis),
          isTrue,
        );

        final crisisEvent = onlyCrises.first;
        expect(crisisEvent.title, contains('Crise de sintomas'));
        expect(crisisEvent.title, contains('2 dias'));
        expect(crisisEvent.subtitle, contains('Pico de dor 9/10'));
      },
    );

    testWidgets(
      'Diário de impacto e Linha do tempo na UI — registro de impacto nas 6 áreas, navegação e feed unificado de todos os módulos',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final verifiedUser = AppAuthUser(
          uid: 'user_etapa7_test',
          email: 'etapa7@endocare.com',
          emailVerified: true,
          displayName: 'Mariana Silva',
        );

        final fakeProfiles = FakeUserProfileRepository()
          ..seedUser(
            const UserProfile(
              uid: 'user_etapa7_test',
              email: 'etapa7@endocare.com',
              nome: 'Mariana Silva',
              preferencias: UserPreferences(
                onboardingConcluido: true,
              ),
            ),
          );

        final fakeAuth = FakeAuthRepository(
          fakeProfiles,
          initialUser: verifiedUser,
        );
        final fakeOnboarding = FakeOnboardingStorage(initialCompleted: true);
        final fakeSymptoms = FakeSymptomLogRepository();
        final fakeCycles = FakeCycleRepository();
        final fakeTreatments = FakeTreatmentRepository();
        final fakeAppointments = FakeAppointmentRepository();
        final fakeImpact = FakeImpactLogRepository();
        final fakeScheduler = FakeReminderScheduler();
        final today = DateTime(2026, 11, 2, 10, 0);

        // Preenche eventos para a linha do tempo
        fakeSymptoms.seedLog(
          verifiedUser.uid,
          SymptomLog(
            id: 's_etapa7',
            data: DateTime(2026, 10, 15),
            dor: 8,
            tipos: const ['cólica menstrual', 'dor lombar'],
          ),
        );
        fakeCycles.seedEntry(
          verifiedUser.uid,
          CycleEntry(
            id: 'c_etapa7',
            data: DateTime(2026, 10, 15),
            fluxo: MenstrualFlowLevel.heavy,
          ),
        );
        await fakeTreatments.saveTreatment(
          uid: verifiedUser.uid,
          treatment: Treatment(
            id: 't_etapa7',
            medicamento: 'Dienogeste',
            dose: '2mg',
            categoria: TreatmentCategory.hormonal,
            inicio: DateTime(2026, 10, 1),
            horarios: const ['08:00'],
            ativo: true,
          ),
        );
        await fakeTreatments.saveEffect(
          uid: verifiedUser.uid,
          effect: TreatmentEffect(
            id: 'eff_etapa7',
            treatmentId: 't_etapa7',
            treatmentName: 'Dienogeste',
            data: DateTime(2026, 10, 20),
            efeito: 'Diminuição das cólicas',
            tipo: TreatmentEffectKind.relief,
            intensidade: 8,
          ),
        );
        await fakeAppointments.saveAppointment(
          uid: verifiedUser.uid,
          appointment: MedicalAppointment(
            id: 'appt_etapa7',
            tipo: AppointmentType.procedure,
            titulo: 'Videolaparoscopia diagnóstica',
            data: DateTime(2026, 9, 25, 9, 30),
            local: 'Hospital Santa Maria',
            status: AppointmentStatus.completed,
          ),
        );

        addTearDown(() {
          fakeAuth.dispose();
          fakeProfiles.dispose();
          fakeSymptoms.dispose();
          fakeCycles.dispose();
          fakeTreatments.dispose();
          fakeAppointments.dispose();
          fakeImpact.dispose();
          fakeScheduler.dispose();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingStorageProvider.overrideWithValue(fakeOnboarding),
              userProfileRepositoryProvider.overrideWithValue(fakeProfiles),
              authRepositoryProvider.overrideWithValue(fakeAuth),
              symptomLogRepositoryProvider.overrideWithValue(fakeSymptoms),
              cycleRepositoryProvider.overrideWithValue(fakeCycles),
              treatmentRepositoryProvider.overrideWithValue(fakeTreatments),
              appointmentRepositoryProvider.overrideWithValue(fakeAppointments),
              impactLogRepositoryProvider.overrideWithValue(fakeImpact),
              reminderSchedulerProvider.overrideWithValue(fakeScheduler),
              homeClockProvider.overrideWithValue(() => today),
            ],
            child: const EndoCareApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Navega para a aba Mais e verifica os atalhos do Diário de impacto e Linha do tempo
        final moreTab = find.text('Mais');
        await tester.tap(moreTab);
        await tester.pumpAndSettle();

        expect(find.text('Diário de impacto'), findsOneWidget);
        expect(find.text('Linha do tempo da doença'), findsOneWidget);

        // 2. Abre o Diário de impacto
        final openImpactBtn = find.text('Abrir diário de impacto');
        await tester.ensureVisible(openImpactBtn);
        await tester.pumpAndSettle();
        await tester.tap(openImpactBtn);
        await tester.pumpAndSettle();

        // 3. Verifica as 6 áreas obrigatórias
        expect(find.text('Trabalho'), findsOneWidget);
        expect(find.text('Estudos'), findsOneWidget);
        expect(find.text('Sono'), findsOneWidget);
        expect(find.text('Exercícios'), findsOneWidget);
        expect(find.text('Relacionamentos'), findsOneWidget);
        expect(find.text('Rotina'), findsOneWidget);

        // 4. Seleciona avaliação para Trabalho (Alto 8) e Sono (Moderado 5)
        final workAltoChip = find.text('Alto (8)').first;
        await tester.ensureVisible(workAltoChip);
        await tester.pumpAndSettle();
        await tester.tap(workAltoChip);
        await tester.pumpAndSettle();

        final sleepCard = find.widgetWithText(EndoCareCard, 'Sono');
        await tester.ensureVisible(sleepCard);
        await tester.pumpAndSettle();
        final sleepModeradoChip = find.descendant(
          of: sleepCard,
          matching: find.text('Moderado (5)'),
        );
        await tester.tap(sleepModeradoChip);
        await tester.pumpAndSettle();

        // Preenche notas
        final notesInput = find.byType(TextField);
        await tester.ensureVisible(notesInput);
        await tester.pumpAndSettle();
        await tester.enterText(
          notesInput,
          'Dificuldade para sentar no escritório devido a dor pélvica.',
        );
        await tester.pumpAndSettle();

        // Salva o registro
        final saveImpactBtn = find.text('Salvar registro');
        await tester.ensureVisible(saveImpactBtn);
        await tester.pumpAndSettle();
        await tester.tap(saveImpactBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Registro de impacto salvo com sucesso!'),
          findsOneWidget,
        );

        final savedLog = await fakeImpact.getLogForDate(
          uid: verifiedUser.uid,
          date: today,
        );
        expect(savedLog, isNotNull);
        expect(savedLog!.niveis[ImpactArea.work], 8);
        expect(savedLog.niveis[ImpactArea.sleep], 5);
        expect(
          savedLog.notas,
          'Dificuldade para sentar no escritório devido a dor pélvica.',
        );

        // 5. Clica para abrir a linha do tempo pelo ícone da AppBar
        final viewTimelineBtn = find.byTooltip('Linha do tempo');
        await tester.tap(viewTimelineBtn);
        await tester.pumpAndSettle();

        // 6. Confirma que a Linha do tempo unificada exibe eventos de todos os módulos
        expect(find.text('Linha do tempo'), findsOneWidget);
        expect(find.textContaining('Crise de sintomas'), findsOneWidget);
        expect(find.textContaining('Início do tratamento: Dienogeste'), findsOneWidget);
        expect(find.textContaining('Efeito percebido: Diminuição das cólicas'), findsOneWidget);
        expect(find.textContaining('Procedimento / Cirurgia: Videolaparoscopia diagnóstica'), findsOneWidget);
        expect(find.textContaining('Alto impacto na rotina'), findsOneWidget);

        // 7. Testa filtros por categoria
        final crisisFilterChip = find.widgetWithText(EndoCareChip, 'Crises (1)');
        await tester.tap(crisisFilterChip);
        await tester.pumpAndSettle();

        expect(find.textContaining('Crise de sintomas'), findsOneWidget);
        expect(find.textContaining('Início do tratamento: Dienogeste'), findsNothing);

        // Reseta filtro
        final allFilterChip = find.descendant(
          of: find.byType(SingleChildScrollView).first,
          matching: find.textContaining('Todos'),
        );
        await tester.tap(allFilterChip);
        await tester.pumpAndSettle();
        expect(find.textContaining('Início do tratamento: Dienogeste'), findsOneWidget);

        // 8. Inverte a ordenação (Mais antigas primeiro)
        final sortBtn = find.byTooltip('Mais recentes primeiro (toque para inverter)');
        await tester.tap(sortBtn);
        await tester.pumpAndSettle();
        expect(find.textContaining('Mais antigos primeiro'), findsOneWidget);
      },
    );
  });
}
