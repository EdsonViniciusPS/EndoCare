/// Estilo visual das famílias Storyset presentes no projeto.
enum StorysetStyle { bro, pana, rafiki, amico, cuate }

/// Paleta predominante de cada arquivo Storyset local.
enum StorysetPalette {
  pink,
  coral,
  blue,
  peach,
  purple,
  lilac,
  red,
  mint,
  yellow,
}

/// Grupos temáticos oficiais definidos na seção 2.3 do EndoCare.md.
enum StorysetThemeGroup {
  onboardingAndWellness,
  painAndSymptoms,
  moodAndMentalHealth,
  gutSymptoms,
  bodyMap,
  calendarAndCycle,
  treatmentsAndMedications,
  libraryAndEducation,
  fertility,
  immunityAndNutrition,
  emptyStatesAndSupport,
}

/// Metadados de uma ilustração Storyset SVG local.
class StorysetAsset {
  const StorysetAsset({
    required this.path,
    required this.style,
    required this.palette,
    required this.semanticLabel,
  });

  final String path;
  final StorysetStyle style;
  final StorysetPalette palette;
  final String semanticLabel;
}

/// Catálogo central e exclusivo de assets do EndoCare.
///
/// Regra da especificação:
/// - Usar exclusivamente os 3 arquivos JPEG em `assets/logos/`.
/// - Usar exclusivamente as 32 ilustrações SVG locais em `assets/storysets/`.
abstract final class AppAssets {
  // ---------------------------------------------------------------------------
  // 1. Logos oficiais (exclusivamente os 3 JPEGs existentes em assets/logos/)
  // ---------------------------------------------------------------------------
  static const String logoHorizontal = 'assets/logos/logo_horizontal.jpg';
  static const String logoNegativeBw = 'assets/logos/logo_negative_bw.jpg';
  static const String wordmark = 'assets/logos/wordmark.jpg';

  static const List<String> allLogos = [
    logoHorizontal,
    logoNegativeBw,
    wordmark,
  ];

  // ---------------------------------------------------------------------------
  // 2. Ilustrações Storyset (32 SVGs locais com nomes exatos)
  // ---------------------------------------------------------------------------

  // Onboarding, boas-vindas e bem-estar
  static const StorysetAsset peaceOfMindBro = StorysetAsset(
    path: 'assets/storysets/Peace of mind-bro.svg',
    style: StorysetStyle.bro,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração de tranquilidade e acolhimento',
  );
  static const StorysetAsset personalGrowthBro = StorysetAsset(
    path: 'assets/storysets/personal growth-bro.svg',
    style: StorysetStyle.bro,
    palette: StorysetPalette.coral,
    semanticLabel: 'Ilustração de autocuidado e evolução pessoal',
  );
  static const StorysetAsset healthyHabitRafiki = StorysetAsset(
    path: 'assets/storysets/Healthy habit-rafiki.svg',
    style: StorysetStyle.rafiki,
    palette: StorysetPalette.blue,
    semanticLabel: 'Ilustração de hábitos saudáveis e rotina leve',
  );

  // Dor, mal-estar e registro de sintomas
  static const StorysetAsset dizzyFaceAmico = StorysetAsset(
    path: 'assets/storysets/Dizzy face-amico.svg',
    style: StorysetStyle.amico,
    palette: StorysetPalette.peach,
    semanticLabel: 'Ilustração de desconforto e tontura',
  );
  static const StorysetAsset overwhelmedRafiki = StorysetAsset(
    path: 'assets/storysets/Overwhelmed-rafiki.svg',
    style: StorysetStyle.rafiki,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração de sobrecarga e dor intensa',
  );
  static const StorysetAsset overwhelmedPana = StorysetAsset(
    path: 'assets/storysets/Overwhelmed-pana.svg',
    style: StorysetStyle.pana,
    palette: StorysetPalette.coral,
    semanticLabel: 'Ilustração de cansaço e sintomas intensos',
  );

  // Humor e saúde mental
  static const StorysetAsset anxietyBro = StorysetAsset(
    path: 'assets/storysets/Anxiety-bro.svg',
    style: StorysetStyle.bro,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração sobre ansiedade em tons de rosa',
  );
  static const StorysetAsset anxietyPana = StorysetAsset(
    path: 'assets/storysets/Anxiety-pana.svg',
    style: StorysetStyle.pana,
    palette: StorysetPalette.coral,
    semanticLabel: 'Ilustração sobre ansiedade em tons de coral',
  );
  static const StorysetAsset anxietyRafiki = StorysetAsset(
    path: 'assets/storysets/Anxiety-rafiki.svg',
    style: StorysetStyle.rafiki,
    palette: StorysetPalette.blue,
    semanticLabel: 'Ilustração sobre ansiedade em tons de azul',
  );
  static const StorysetAsset mentalHealthBro = StorysetAsset(
    path: 'assets/storysets/Mental health-bro.svg',
    style: StorysetStyle.bro,
    palette: StorysetPalette.mint,
    semanticLabel: 'Ilustração de saúde mental e equilíbrio',
  );
  static const StorysetAsset mentalHealthCuate = StorysetAsset(
    path: 'assets/storysets/Mental health-cuate.svg',
    style: StorysetStyle.cuate,
    palette: StorysetPalette.yellow,
    semanticLabel: 'Ilustração de cuidado emocional',
  );

  // Sintomas intestinais
  static const StorysetAsset gutHealthAmico = StorysetAsset(
    path: 'assets/storysets/Gut health-amico.svg',
    style: StorysetStyle.amico,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração de saúde intestinal',
  );

  // Mapa corporal
  static const StorysetAsset femaleBodyShapesAmico = StorysetAsset(
    path: 'assets/storysets/Types of female body shapes-amico.svg',
    style: StorysetStyle.amico,
    palette: StorysetPalette.purple,
    semanticLabel: 'Ilustração corporal feminina',
  );

  // Calendário e ciclo
  static const StorysetAsset calendarBro = StorysetAsset(
    path: 'assets/storysets/Calendar-bro.svg',
    style: StorysetStyle.bro,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração de calendário e agendamentos',
  );
  static const StorysetAsset menstrualCalendarAmicoRed = StorysetAsset(
    path: 'assets/storysets/Menstrual calendar-amico.svg',
    style: StorysetStyle.amico,
    palette: StorysetPalette.red,
    semanticLabel: 'Ilustração de calendário menstrual em dias de fluxo',
  );
  static const StorysetAsset menstrualCalendarAmicoPink = StorysetAsset(
    path: 'assets/storysets/Menstrual calendar-amico (1).svg',
    style: StorysetStyle.amico,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração de calendário menstrual em tons suaves',
  );
  static const StorysetAsset menstrualCalendarRafikiBlue = StorysetAsset(
    path: 'assets/storysets/Menstrual calendar-rafiki.svg',
    style: StorysetStyle.rafiki,
    palette: StorysetPalette.blue,
    semanticLabel: 'Ilustração de acompanhamento do ciclo em azul',
  );

  // Tratamentos e medicamentos
  static const StorysetAsset medicalPrescriptionAmico = StorysetAsset(
    path: 'assets/storysets/Medical prescription-amico.svg',
    style: StorysetStyle.amico,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração de prescrição médica e tratamento',
  );

  // Biblioteca, educação e ginecologia
  static const StorysetAsset womanReadingPana = StorysetAsset(
    path: 'assets/storysets/Woman reading-pana.svg',
    style: StorysetStyle.pana,
    palette: StorysetPalette.coral,
    semanticLabel: 'Ilustração de leitura e aprendizado em saúde',
  );
  static const StorysetAsset femaleReproductiveAmicoLilac = StorysetAsset(
    path: 'assets/storysets/Female reproductive system-amico.svg',
    style: StorysetStyle.amico,
    palette: StorysetPalette.lilac,
    semanticLabel: 'Ilustração educativa do sistema reprodutivo em lilás',
  );
  static const StorysetAsset femaleReproductiveAmicoPink = StorysetAsset(
    path: 'assets/storysets/Female reproductive system-amico (1).svg',
    style: StorysetStyle.amico,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração educativa do sistema reprodutivo em rosa',
  );
  static const StorysetAsset femaleReproductiveBroPink = StorysetAsset(
    path: 'assets/storysets/Female reproductive system-bro.svg',
    style: StorysetStyle.bro,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração ginecológica estilo bro',
  );
  static const StorysetAsset femaleReproductiveCuateYellow = StorysetAsset(
    path: 'assets/storysets/Female reproductive system-cuate.svg',
    style: StorysetStyle.cuate,
    palette: StorysetPalette.yellow,
    semanticLabel: 'Ilustração ginecológica em amarelo suave',
  );
  static const StorysetAsset femaleReproductivePanaCoral = StorysetAsset(
    path: 'assets/storysets/Female reproductive system-pana.svg',
    style: StorysetStyle.pana,
    palette: StorysetPalette.coral,
    semanticLabel: 'Ilustração ginecológica em coral',
  );
  static const StorysetAsset femaleReproductiveRafikiBlue = StorysetAsset(
    path: 'assets/storysets/Female reproductive system-rafiki.svg',
    style: StorysetStyle.rafiki,
    palette: StorysetPalette.blue,
    semanticLabel: 'Ilustração ginecológica em azul',
  );
  static const StorysetAsset femaleReproductiveRafikiPink = StorysetAsset(
    path: 'assets/storysets/Female reproductive system-rafiki (1).svg',
    style: StorysetStyle.rafiki,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração ginecológica estilo rafiki em rosa',
  );

  // Fertilidade
  static const StorysetAsset womanInfertilityAmico = StorysetAsset(
    path: 'assets/storysets/Woman infertility-amico.svg',
    style: StorysetStyle.amico,
    palette: StorysetPalette.purple,
    semanticLabel: 'Ilustração sobre saúde reprodutiva e fertilidade',
  );

  // Imunidade e alimentação
  static const StorysetAsset boostImmuneSystemBro = StorysetAsset(
    path: 'assets/storysets/Boost your immune system-bro.svg',
    style: StorysetStyle.bro,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração de alimentação e bem-estar',
  );

  // Estados vazios e apoio emocional
  static const StorysetAsset eatingDisorderBro = StorysetAsset(
    path: 'assets/storysets/Eating disorder-bro.svg',
    style: StorysetStyle.bro,
    palette: StorysetPalette.pink,
    semanticLabel: 'Ilustração de acolhimento emocional em rosa',
  );
  static const StorysetAsset eatingDisorderCuate = StorysetAsset(
    path: 'assets/storysets/Eating disorder-cuate.svg',
    style: StorysetStyle.cuate,
    palette: StorysetPalette.yellow,
    semanticLabel: 'Ilustração de acolhimento emocional em amarelo',
  );
  static const StorysetAsset eatingDisorderPana = StorysetAsset(
    path: 'assets/storysets/Eating disorder-pana.svg',
    style: StorysetStyle.pana,
    palette: StorysetPalette.coral,
    semanticLabel: 'Ilustração de acolhimento emocional em coral',
  );
  static const StorysetAsset eatingDisorderRafiki = StorysetAsset(
    path: 'assets/storysets/Eating disorder-rafiki.svg',
    style: StorysetStyle.rafiki,
    palette: StorysetPalette.blue,
    semanticLabel: 'Ilustração de acolhimento emocional em azul',
  );

  /// Lista completa das 32 ilustrações SVG locais.
  static const List<StorysetAsset> allStorysets = [
    peaceOfMindBro,
    personalGrowthBro,
    healthyHabitRafiki,
    dizzyFaceAmico,
    overwhelmedRafiki,
    overwhelmedPana,
    anxietyBro,
    anxietyPana,
    anxietyRafiki,
    mentalHealthBro,
    mentalHealthCuate,
    gutHealthAmico,
    femaleBodyShapesAmico,
    calendarBro,
    menstrualCalendarAmicoRed,
    menstrualCalendarAmicoPink,
    menstrualCalendarRafikiBlue,
    medicalPrescriptionAmico,
    womanReadingPana,
    femaleReproductiveAmicoLilac,
    femaleReproductiveAmicoPink,
    femaleReproductiveBroPink,
    femaleReproductiveCuateYellow,
    femaleReproductivePanaCoral,
    femaleReproductiveRafikiBlue,
    femaleReproductiveRafikiPink,
    womanInfertilityAmico,
    boostImmuneSystemBro,
    eatingDisorderBro,
    eatingDisorderCuate,
    eatingDisorderPana,
    eatingDisorderRafiki,
  ];

  // ---------------------------------------------------------------------------
  // 3. Grupos temáticos com paletas intercaladas para evitar repetição vizinha
  // ---------------------------------------------------------------------------
  static const Map<StorysetThemeGroup, List<StorysetAsset>> _groups = {
    StorysetThemeGroup.onboardingAndWellness: [
      peaceOfMindBro, // rosa
      personalGrowthBro, // coral
      healthyHabitRafiki, // azul/pêssego
    ],
    StorysetThemeGroup.painAndSymptoms: [
      dizzyFaceAmico, // pêssego/roxo
      overwhelmedPana, // coral
      overwhelmedRafiki, // rosa
    ],
    StorysetThemeGroup.moodAndMentalHealth: [
      mentalHealthBro, // verde menta
      mentalHealthCuate, // amarelo
      anxietyRafiki, // azul
      anxietyPana, // coral
      anxietyBro, // rosa
    ],
    StorysetThemeGroup.gutSymptoms: [gutHealthAmico],
    StorysetThemeGroup.bodyMap: [femaleBodyShapesAmico],
    StorysetThemeGroup.calendarAndCycle: [
      menstrualCalendarAmicoPink, // rosa
      menstrualCalendarRafikiBlue, // azul
      calendarBro, // rosa (estilo bro)
      menstrualCalendarAmicoRed, // vermelho
    ],
    StorysetThemeGroup.treatmentsAndMedications: [medicalPrescriptionAmico],
    // Intercalado para que itens seguidos nunca repitam a mesma arte/paleta
    StorysetThemeGroup.libraryAndEducation: [
      womanReadingPana, // coral
      femaleReproductiveAmicoLilac, // lilás
      femaleReproductiveRafikiBlue, // azul
      femaleReproductiveBroPink, // rosa (bro)
      femaleReproductiveCuateYellow, // amarelo
      femaleReproductiveAmicoPink, // rosa (amico)
      femaleReproductivePanaCoral, // coral (pana)
      femaleReproductiveRafikiPink, // rosa (rafiki)
    ],
    StorysetThemeGroup.fertility: [womanInfertilityAmico],
    StorysetThemeGroup.immunityAndNutrition: [boostImmuneSystemBro],
    StorysetThemeGroup.emptyStatesAndSupport: [
      eatingDisorderBro, // rosa
      eatingDisorderCuate, // amarelo/rosado
      eatingDisorderPana, // coral
      eatingDisorderRafiki, // azul
    ],
  };

  /// Retorna todas as variações disponíveis de um grupo temático.
  static List<StorysetAsset> group(StorysetThemeGroup themeGroup) {
    return _groups[themeGroup]!;
  }

  /// Distribuição sem repetição para listas, cards, categorias e onboarding:
  /// `index % variacoes.length`.
  static StorysetAsset byIndex(StorysetThemeGroup themeGroup, int index) {
    final variations = _groups[themeGroup]!;
    return variations[index.abs() % variations.length];
  }

  /// Rotação diária leve (ex.: tela Início): `dayOfYear % variacoes.length`.
  static StorysetAsset forDayOfYear(
    StorysetThemeGroup themeGroup, [
    DateTime? date,
  ]) {
    final target = date ?? DateTime.now();
    final startOfYear = DateTime(target.year, 1, 1);
    final dayOfYear = target.difference(startOfYear).inDays + 1;
    return byIndex(themeGroup, dayOfYear);
  }

  /// Alternância contextual para o calendário e ciclo menstrual.
  static StorysetAsset forCalendarContext({
    bool isMenstrualFlow = false,
    bool isAppointmentView = false,
    int variantIndex = 0,
  }) {
    if (isAppointmentView) return calendarBro;
    if (isMenstrualFlow) return menstrualCalendarAmicoRed;
    const generalCycleVariants = [
      menstrualCalendarAmicoPink,
      menstrualCalendarRafikiBlue,
    ];
    return generalCycleVariants[variantIndex.abs() % generalCycleVariants.length];
  }

  /// Alternância contextual conforme intensidade de dor (0–10).
  static StorysetAsset forPainIntensity(int intensity) {
    final clamped = intensity.clamp(0, 10);
    if (clamped <= 2) return peaceOfMindBro;
    if (clamped <= 5) return dizzyFaceAmico;
    if (clamped <= 7) return overwhelmedPana;
    return overwhelmedRafiki;
  }

  /// Atribuição exigida pela licença Storyset / Freepik (para exibir na tela "Sobre").
  static const String storysetAttribution =
      'Ilustrações por Storyset (storyset.com / Freepik).';
}

