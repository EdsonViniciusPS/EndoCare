import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de agendamento clínico (compatível com `firestore.rules`: consulta | exame | procedimento).
enum AppointmentType {
  consultation('consulta', 'Consulta'),
  exam('exame', 'Exame'),
  procedure('procedimento', 'Procedimento / Cirurgia');

  const AppointmentType(this.code, this.label);

  final String code;
  final String label;

  static AppointmentType fromCode(String? raw) {
    for (final item in values) {
      if (item.code == raw?.trim()) return item;
    }
    return AppointmentType.consultation;
  }
}

/// Status do agendamento ou procedimento clínico.
enum AppointmentStatus {
  scheduled('agendado', 'Agendado'),
  completed('realizado', 'Realizado'),
  canceled('cancelado', 'Cancelado');

  const AppointmentStatus(this.code, this.label);

  final String code;
  final String label;

  static AppointmentStatus fromCode(String? raw) {
    for (final item in values) {
      if (item.code == raw?.trim()) return item;
    }
    return AppointmentStatus.scheduled;
  }
}

/// Antecedência configurável do lembrete para consultas, exames e procedimentos.
enum AppointmentReminderLead {
  none(-1, 'Sem lembrete'),
  atExactTime(0, 'No horário exato'),
  oneHourBefore(60, '1 hora antes'),
  oneDayBefore(1440, '1 dia antes');

  const AppointmentReminderLead(this.minutes, this.label);

  final int minutes;
  final String label;

  static AppointmentReminderLead fromMinutes(int? raw) {
    if (raw == null) return AppointmentReminderLead.oneHourBefore;
    for (final item in values) {
      if (item.minutes == raw) return item;
    }
    return AppointmentReminderLead.oneHourBefore;
  }
}

/// Modelo de consulta, exame ou procedimento (`users/{uid}/appointments/{id}`).
class MedicalAppointment {
  const MedicalAppointment({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.data,
    this.local,
    this.profissional,
    this.notas,
    this.status = AppointmentStatus.scheduled,
    this.lembreteAntecedenciaMinutos = 60,
  });

  final String id;
  final AppointmentType tipo;
  final String titulo;

  /// Data e horário completo (`ano, mês, dia, hora, minuto`) do compromisso.
  final DateTime data;
  final String? local;
  final String? profissional;
  final String? notas;
  final AppointmentStatus status;
  final int lembreteAntecedenciaMinutos;

  AppointmentReminderLead get reminderLead =>
      AppointmentReminderLead.fromMinutes(lembreteAntecedenciaMinutos);

  /// Horário exato em que o lembrete deve disparar (`null` se desativado ou não agendado).
  DateTime? get reminderTriggerAt {
    if (status != AppointmentStatus.scheduled ||
        lembreteAntecedenciaMinutos < 0) {
      return null;
    }
    return data.subtract(Duration(minutes: lembreteAntecedenciaMinutos));
  }

  MedicalAppointment copyWith({
    String? id,
    AppointmentType? tipo,
    String? titulo,
    DateTime? data,
    String? local,
    bool clearLocal = false,
    String? profissional,
    bool clearProfissional = false,
    String? notas,
    bool clearNotas = false,
    AppointmentStatus? status,
    int? lembreteAntecedenciaMinutos,
  }) {
    return MedicalAppointment(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      data: data ?? this.data,
      local: clearLocal ? null : (local ?? this.local),
      profissional:
          clearProfissional ? null : (profissional ?? this.profissional),
      notas: clearNotas ? null : (notas ?? this.notas),
      status: status ?? this.status,
      lembreteAntecedenciaMinutos:
          lembreteAntecedenciaMinutos ?? this.lembreteAntecedenciaMinutos,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final trimmedLocal = local?.trim();
    final trimmedProf = profissional?.trim();
    final trimmedNotas = notas?.trim();

    return <String, dynamic>{
      'tipo': tipo.code,
      'titulo': titulo.trim(),
      'data': Timestamp.fromDate(data),
      'local': (trimmedLocal != null && trimmedLocal.isNotEmpty)
          ? trimmedLocal
          : null,
      'profissional': (trimmedProf != null && trimmedProf.isNotEmpty)
          ? trimmedProf
          : null,
      'notas': (trimmedNotas != null && trimmedNotas.isNotEmpty)
          ? trimmedNotas
          : null,
      'status': status.code,
      'lembreteAntecedenciaMinutos': lembreteAntecedenciaMinutos,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MedicalAppointment.fromFirestoreDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? const <String, dynamic>{};
    final tipo = AppointmentType.fromCode(map['tipo'] as String?);
    final rawDate = map['data'];
    final rawTitulo = (map['titulo'] as String?)?.trim();
    final rawLead = map['lembreteAntecedenciaMinutos'];

    return MedicalAppointment(
      id: doc.id,
      tipo: tipo,
      titulo: (rawTitulo != null && rawTitulo.isNotEmpty)
          ? rawTitulo
          : tipo.label,
      data: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      local: map['local'] as String?,
      profissional: map['profissional'] as String?,
      notas: map['notas'] as String?,
      status: AppointmentStatus.fromCode(map['status'] as String?),
      lembreteAntecedenciaMinutos: rawLead is num ? rawLead.toInt() : 60,
    );
  }
}

