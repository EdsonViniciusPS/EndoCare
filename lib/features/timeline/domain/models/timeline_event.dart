import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';

/// Categorias de filtro da Linha do tempo da doença.
enum TimelineCategory {
  crisis('Crises', Icons.bolt_rounded, AppColors.painSevere),
  appointments(
    'Consultas e exames',
    Icons.event_available_rounded,
    AppColors.tertiary,
  ),
  procedures(
    'Cirurgias e procedimentos',
    Icons.medical_services_outlined,
    AppColors.primaryDark,
  ),
  treatments('Tratamentos', Icons.medication_outlined, AppColors.success),
  symptoms('Mudanças de sintomas', Icons.trending_up_rounded, AppColors.info),
  cycle('Ciclo', Icons.water_drop_outlined, AppColors.cycleMenstruation),
  impact('Impacto na rotina', Icons.work_history_outlined, AppColors.warning);

  const TimelineCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Tipos específicos de evento exibidos na Linha do tempo.
enum TimelineEventType {
  crisis(TimelineCategory.crisis),
  consultation(TimelineCategory.appointments),
  exam(TimelineCategory.appointments),
  procedure(TimelineCategory.procedures),
  treatmentStarted(TimelineCategory.treatments),
  treatmentEnded(TimelineCategory.treatments),
  treatmentEffect(TimelineCategory.treatments),
  painIncreased(TimelineCategory.symptoms),
  painDecreased(TimelineCategory.symptoms),
  newSymptom(TimelineCategory.symptoms),
  periodStarted(TimelineCategory.cycle),
  impactLogged(TimelineCategory.impact);

  const TimelineEventType(this.category);

  final TimelineCategory category;
}

/// Evento unificado da Linha do tempo, vindo de qualquer módulo do app
/// (sintomas, calendário/ciclo, tratamentos, consultas e diário de impacto).
class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    this.subtitle,
    this.isUpcoming = false,
    this.isHighlighted = false,
  });

  /// Identificador estável (`<origem>_<id>`) usado também como chave de widget.
  final String id;
  final TimelineEventType type;

  /// Momento do evento (com horário quando a origem possuir, ex.: consultas).
  final DateTime date;
  final String title;
  final String? subtitle;

  /// Evento futuro ainda agendado (ex.: consulta marcada).
  final bool isUpcoming;

  /// Evento de destaque (ex.: crise com dor muito intensa ou alto impacto).
  final bool isHighlighted;

  TimelineCategory get category => type.category;
}

