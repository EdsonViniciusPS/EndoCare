import 'package:endocare/core/assets/app_assets.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_catalog.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';

/// Item de lembrete futuro exibido no resumo da tela Início.
class HomeReminderPreview {
  const HomeReminderPreview({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

/// Modelo consolidado para exibição da tela Início (dashboard diário).
class HomeSummaryData {
  const HomeSummaryData({
    required this.greeting,
    required this.formattedDate,
    required this.supportiveMessage,
    required this.heroIllustration,
    required this.hasLoggedToday,
    required this.painStatusLabel,
    required this.painStatusSubtitle,
    required this.cycleStatusLabel,
    required this.cycleStatusSubtitle,
    required this.wellnessStatusLabel,
    required this.wellnessStatusSubtitle,
    this.todayPainLevel,
    this.upcomingReminders = const [],
  });

  final String greeting;
  final String formattedDate;
  final String supportiveMessage;
  final StorysetAsset heroIllustration;
  final bool hasLoggedToday;

  final int? todayPainLevel;
  final String painStatusLabel;
  final String painStatusSubtitle;
  final String cycleStatusLabel;
  final String cycleStatusSubtitle;
  final String wellnessStatusLabel;
  final String wellnessStatusSubtitle;

  final List<HomeReminderPreview> upcomingReminders;

  static const List<String> _dailyMessages = [
    'Reserve alguns segundos para registrar como o seu corpo está hoje.',
    'Cada pequeno registro ajuda você e seu médico a enxergarem seus padrões.',
    'Respeite o seu ritmo hoje — anotar o essencial já faz toda a diferença.',
  ];

  /// Constrói o resumo contextual rotativo por data, período do dia e registro atual.
  factory HomeSummaryData.forToday({
    required DateTime now,
    required String formattedDate,
    String? firstName,
    int? todayPainLevel,
    SymptomLog? todayLog,
    String? cycleStatusLabel,
    String? cycleStatusSubtitle,
    List<HomeReminderPreview> upcomingReminders = const [],
  }) {
    final periodGreeting = _periodGreeting(now.hour);
    final greeting = firstName != null && firstName.trim().isNotEmpty
        ? '$periodGreeting, ${firstName.trim()}'
        : periodGreeting;

    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;

    final resolvedPain = todayLog?.dor ?? todayPainLevel;
    final hasLogged = todayLog != null || todayPainLevel != null;

    // Ilustração contextual rotativa: se houver dor registrada no dia (> 2),
    // reflete a intensidade; caso contrário, alterna pelo dia do ano no grupo
    // de boas-vindas e bem-estar (`dayOfYear % variacoes.length`).
    final illustration = resolvedPain != null && resolvedPain > 2
        ? AppAssets.forPainIntensity(resolvedPain)
        : AppAssets.forDayOfYear(
            StorysetThemeGroup.onboardingAndWellness,
            now,
          );

    final message = todayLog != null
        ? 'Seu registro de hoje está salvo. Você pode complementar detalhes quando quiser.'
        : _dailyMessages[dayOfYear % _dailyMessages.length];

    final wellnessLabel = todayLog != null
        ? (todayLog.humor ?? 'Sono ${todayLog.sono}/10')
        : 'Humor e sono';
    final wellnessSubtitle = todayLog != null
        ? 'Sono: ${SymptomCatalog.sleepQualityLabel(todayLog.sono)} (${todayLog.sono}/10)'
        : 'Registrar em segundos';

    return HomeSummaryData(
      greeting: greeting,
      formattedDate: formattedDate,
      supportiveMessage: message,
      heroIllustration: illustration,
      hasLoggedToday: hasLogged,
      todayPainLevel: resolvedPain,
      painStatusLabel: resolvedPain != null
          ? 'Nível $resolvedPain/10'
          : 'Sem registro',
      painStatusSubtitle: resolvedPain != null
          ? AppColors.painLabel(resolvedPain)
          : 'Toque para anotar',
      cycleStatusLabel: cycleStatusLabel ?? 'Calendário',
      cycleStatusSubtitle: cycleStatusSubtitle ?? 'Ver ciclo e fases',
      wellnessStatusLabel: wellnessLabel,
      wellnessStatusSubtitle: wellnessSubtitle,
      upcomingReminders: upcomingReminders,
    );
  }

  static String _periodGreeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }
}
