import 'package:cloud_firestore/cloud_firestore.dart';

/// Preferências da usuária armazenadas em `users/{uid}.profile.preferencias`.
class UserPreferences {
  const UserPreferences({
    this.onboardingConcluido = false,
    this.notificacoesMedicamentos = true,
    this.notificacoesConsultas = true,
    this.notificacoesCiclo = true,
    this.notificacoesRegistroDiario = true,
  });

  final bool onboardingConcluido;
  final bool notificacoesMedicamentos;
  final bool notificacoesConsultas;
  final bool notificacoesCiclo;
  final bool notificacoesRegistroDiario;

  UserPreferences copyWith({
    bool? onboardingConcluido,
    bool? notificacoesMedicamentos,
    bool? notificacoesConsultas,
    bool? notificacoesCiclo,
    bool? notificacoesRegistroDiario,
  }) {
    return UserPreferences(
      onboardingConcluido: onboardingConcluido ?? this.onboardingConcluido,
      notificacoesMedicamentos:
          notificacoesMedicamentos ?? this.notificacoesMedicamentos,
      notificacoesConsultas:
          notificacoesConsultas ?? this.notificacoesConsultas,
      notificacoesCiclo: notificacoesCiclo ?? this.notificacoesCiclo,
      notificacoesRegistroDiario:
          notificacoesRegistroDiario ?? this.notificacoesRegistroDiario,
    );
  }

  factory UserPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPreferences();
    return UserPreferences(
      onboardingConcluido: map['onboardingConcluido'] as bool? ?? false,
      notificacoesMedicamentos:
          map['notificacoesMedicamentos'] as bool? ?? true,
      notificacoesConsultas: map['notificacoesConsultas'] as bool? ?? true,
      notificacoesCiclo: map['notificacoesCiclo'] as bool? ?? true,
      notificacoesRegistroDiario:
          map['notificacoesRegistroDiario'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'onboardingConcluido': onboardingConcluido,
      'notificacoesMedicamentos': notificacoesMedicamentos,
      'notificacoesConsultas': notificacoesConsultas,
      'notificacoesCiclo': notificacoesCiclo,
      'notificacoesRegistroDiario': notificacoesRegistroDiario,
    };
  }
}

/// Modelo do documento `users/{uid}` conforme a seção 5.1 do EndoCare.md:
/// `profile: nome, nascimento, preferências, fcmTokens[]`.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.nome,
    this.nascimento,
    this.preferencias = const UserPreferences(),
    this.fcmTokens = const [],
    this.consentimentoLgpd = true,
    this.criadoEm,
    this.atualizadoEm,
  });

  final String uid;
  final String email;
  final String nome;
  final DateTime? nascimento;
  final UserPreferences preferencias;
  final List<String> fcmTokens;
  final bool consentimentoLgpd;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  String get primeiroNome {
    final trimmed = nome.trim();
    if (trimmed.isEmpty) return 'você';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? nome,
    DateTime? nascimento,
    UserPreferences? preferencias,
    List<String>? fcmTokens,
    bool? consentimentoLgpd,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      nascimento: nascimento ?? this.nascimento,
      preferencias: preferencias ?? this.preferencias,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      consentimentoLgpd: consentimentoLgpd ?? this.consentimentoLgpd,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  factory UserProfile.fromFirestore(
    Map<String, dynamic> data, {
    required String uid,
  }) {
    final rawProfile = data['profile'];
    final profileMap = rawProfile is Map<String, dynamic> ? rawProfile : data;

    final rawTokens = profileMap['fcmTokens'];
    final tokens = rawTokens is Iterable
        ? rawTokens.whereType<String>().toList(growable: false)
        : const <String>[];

    final rawPrefs = profileMap['preferencias'];
    final prefsMap = rawPrefs is Map<String, dynamic> ? rawPrefs : null;

    return UserProfile(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      nome: (profileMap['nome'] as String?)?.trim().isNotEmpty == true
          ? (profileMap['nome'] as String).trim()
          : 'Usuária',
      nascimento: _toDateTime(profileMap['nascimento']),
      preferencias: UserPreferences.fromMap(prefsMap),
      fcmTokens: tokens,
      consentimentoLgpd: data['consentimentoLgpd'] as bool? ?? true,
      criadoEm: _toDateTime(data['criadoEm']),
      atualizadoEm: _toDateTime(data['atualizadoEm']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'email': email,
      'profile': {
        'nome': nome,
        'nascimento': nascimento != null
            ? Timestamp.fromDate(nascimento!)
            : null,
        'preferencias': preferencias.toMap(),
        'fcmTokens': fcmTokens,
      },
      'consentimentoLgpd': consentimentoLgpd,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _toDateTime(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
