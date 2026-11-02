import 'package:flutter/material.dart';

/// Opção de humor com rótulo acolhedor e ícone simples.
class MoodOption {
  const MoodOption({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

/// Atalho rápido para qualidade do sono (0–10).
class SleepPreset {
  const SleepPreset({
    required this.label,
    required this.score,
  });

  final String label;
  final int score;
}

/// Catálogo padronizado de opções em português do Brasil para o registro diário.
abstract final class SymptomCatalog {
  /// Chips principais do registro rápido (1 toque).
  static const List<String> quickSymptoms = [
    'Cólica',
    'Dor pélvica',
    'Dor lombar',
    'Fadiga',
    'Inchaço abdominal',
    'Náusea',
    'Alteração intestinal',
    'Desconforto urinário',
    'Dor de cabeça',
    'Sensibilidade mamária',
  ];

  /// Opções rápidas de humor.
  static const List<MoodOption> moods = [
    MoodOption(label: 'Tranquila', icon: Icons.sentiment_satisfied_alt_rounded),
    MoodOption(label: 'Bem', icon: Icons.mood_rounded),
    MoodOption(label: 'Sensível', icon: Icons.favorite_border_rounded),
    MoodOption(label: 'Ansiosa', icon: Icons.air_rounded),
    MoodOption(label: 'Desanimada', icon: Icons.sentiment_dissatisfied_rounded),
    MoodOption(label: 'Exausta', icon: Icons.bedtime_outlined),
  ];

  /// Atalhos de 1 toque para qualidade do sono (sincronizados com o slider 0–10).
  static const List<SleepPreset> sleepPresets = [
    SleepPreset(label: 'Ruim', score: 2),
    SleepPreset(label: 'Regular', score: 5),
    SleepPreset(label: 'Bom', score: 8),
    SleepPreset(label: 'Reparador', score: 10),
  ];

  /// Regiões rápidas iniciais (compatíveis com `regioes[]` da Etapa 4 — Mapa Corporal).
  static const List<String> quickRegions = [
    'Pelve central',
    'Ovário / lado esquerdo',
    'Ovário / lado direito',
    'Lombar',
    'Abdômen superior',
    'Irradiando para pernas',
  ];

  /// Locais de dor durante ou após relação sexual (`dorRelacao.local`).
  static const List<String> sexualPainLocations = [
    'Entrada (superficial)',
    'Fundo pélvico (profunda)',
    'Superficial e profunda',
    'Após a relação',
  ];

  /// Sintomas intestinais detalhados (`intestinal[]`).
  static const List<String> intestinalSymptoms = [
    'Estufamento / gases',
    'Constipação',
    'Diarreia',
    'Dor ao evacuar',
    'Urgência intestinal',
  ];

  /// Sintomas urinários detalhados (`urinario[]`).
  static const List<String> urinarySymptoms = [
    'Ardor ou dor ao urinar',
    'Urgência urinária',
    'Idas frequentes',
    'Sensação de bexiga cheia',
  ];

  static String sleepQualityLabel(int score) {
    final clamped = score.clamp(0, 10);
    if (clamped <= 2) return 'Ruim';
    if (clamped <= 5) return 'Regular';
    if (clamped <= 8) return 'Bom';
    return 'Reparador';
  }
}

