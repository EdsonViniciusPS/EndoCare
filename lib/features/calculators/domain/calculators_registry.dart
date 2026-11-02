import 'package:endocare/features/calculators/domain/models/calculator_category.dart';
import 'package:endocare/features/calculators/domain/models/calculator_definition.dart';
import 'package:endocare/features/calculators/domain/models/calculator_interpretation.dart';
import 'package:endocare/features/calculators/domain/models/calculator_question.dart';

/// Catálogo central e motor determinístico das calculadoras clínicas do EndoCare.
///
/// Todas as calculadoras são configuradas por dados (perguntas, pontuações,
/// opções, interpretações simples e aviso de não diagnóstico).
abstract final class CalculatorsRegistry {
  // ---------------------------------------------------------------------------
  // 1. ESCALA VISUAL ANALÓGICA (EVA) - AVALIAÇÃO DE INTENSIDADE DA DOR
  // ---------------------------------------------------------------------------
  static final CalculatorDefinition eva = CalculatorDefinition(
    id: 'eva',
    title: 'Escala Visual Analógica (EVA)',
    shortName: 'EVA',
    category: CalculatorCategory.symptoms,
    description:
        'Avalia a intensidade da dor percebida em uma escala contínua de 0 (sem dor) a 10 (pior dor imaginável).',
    instructions:
        'Mova o seletor para indicar a intensidade máxima ou média da sua dor no momento ou ao longo do dia.',
    estimatedMinutes: 1,
    questions: const [
      CalculatorQuestion(
        id: 'eva_pain',
        text: 'Qual o nível da sua dor agora ou neste momento de avaliação?',
        hint: 'Arraste o controle de 0 a 10.',
        type: QuestionInputType.slider,
        minSliderValue: 0,
        maxSliderValue: 10,
        sliderDivisions: 10,
        sliderMinLabel: '0 - Sem dor',
        sliderMaxLabel: '10 - Pior dor possível',
      ),
    ],
    compute: (answers) {
      final raw = answers['eva_pain'];
      final score = raw is num ? raw.round().clamp(0, 10) : 0;

      final (label, summary, recs) = switch (score) {
        0 => (
            'Sem dor',
            'Nenhuma dor relatada no momento.',
            [
              'Continue registrando seu dia a dia no calendário para identificar dias de alívio e conforto.',
            ],
          ),
        <= 3 => (
            'Dor leve',
            'Dor de intensidade suave que geralmente permite manter a maioria das atividades cotidianas.',
            [
              'Mantenha hidratação e faça pausas leves de respiração.',
              'Observe se a dor se intensifica com determinados esforços ou fases do ciclo.',
            ],
          ),
        <= 6 => (
            'Dor moderada',
            'Dor incômoda que pode interferir na sua concentração, produtividade ou disposição.',
            [
              'Aplicação de calor local (bolsa térmica morna) no baixo ventre ou lombar pode auxiliar no relaxamento.',
              'Consulte suas prescrições médicas para medicações de alívio orientadas pelo seu médico.',
            ],
          ),
        <= 8 => (
            'Dor intensa',
            'Dor importante com limitação significativa da rotina e das atividades habituais.',
            [
              'Repouse em posição confortável (posição fetal ou com travesseiro sob os joelhos).',
              'Siga o plano de manejo de crises pactuado com seu ginecologista.',
              'Se acompanhada de febre ou sangramento incomum, procure pronto atendimento.',
            ],
          ),
        _ => (
            'Dor muito intensa / incapacitante',
            'Nível crítico de dor, incapacitante e de difícil tolerância.',
            [
              'Acione sua rede de apoio e comunique seu médico de referência.',
              'Caso haja dor súbita com desmaio, vômitos contínuos ou febre, procure serviço de urgência imediatamente.',
            ],
          ),
      };

      return CalculatorInterpretation(
        score: score,
        maxScore: 10,
        severityLabel: label,
        summary: summary,
        recommendations: recs,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 2. PHQ-9 (PATIENT HEALTH QUESTIONNAIRE-9) - RASTREIO DE HUMOR / DEPRESSÃO
  // ---------------------------------------------------------------------------
  static const List<CalculatorQuestionOption> _phqOptions = [
    CalculatorQuestionOption(label: 'Nenhuma vez', score: 0),
    CalculatorQuestionOption(label: 'Vários dias', score: 1),
    CalculatorQuestionOption(label: 'Mais da metade dos dias', score: 2),
    CalculatorQuestionOption(label: 'Quase todos os dias', score: 3),
  ];

  static final CalculatorDefinition phq9 = CalculatorDefinition(
    id: 'phq9',
    title: 'PHQ-9 — Rastreio de Humor e Depressão',
    shortName: 'PHQ-9',
    category: CalculatorCategory.qualityOfLife,
    description:
        'Instrumento validado internacionalmente para avaliar a frequência de sintomas de humor nas últimas 2 semanas.',
    instructions:
        'Nas últimas 2 semanas, com que frequência você foi incomodada por qualquer um dos problemas abaixo?',
    estimatedMinutes: 3,
    questions: const [
      CalculatorQuestion(
        id: 'phq9_q1',
        text: 'Pouco interesse ou pouco prazer em fazer as coisas',
        options: _phqOptions,
      ),
      CalculatorQuestion(
        id: 'phq9_q2',
        text: 'Sentir-se para baixo, deprimida ou sem perspectiva',
        options: _phqOptions,
      ),
      CalculatorQuestion(
        id: 'phq9_q3',
        text: 'Dificuldade para adormecer, continuar dormindo ou dormir demais',
        options: _phqOptions,
      ),
      CalculatorQuestion(
        id: 'phq9_q4',
        text: 'Sentir-se cansada ou com pouca energia',
        options: _phqOptions,
      ),
      CalculatorQuestion(
        id: 'phq9_q5',
        text: 'Falta de apetite ou comer demais',
        options: _phqOptions,
      ),
      CalculatorQuestion(
        id: 'phq9_q6',
        text:
            'Sentir-se mal consigo mesma — ou achar que é um fracasso ou que decepcionou sua família',
        options: _phqOptions,
      ),
      CalculatorQuestion(
        id: 'phq9_q7',
        text:
            'Dificuldade para se concentrar nas coisas, como ler notícias ou assistir à televisão',
        options: _phqOptions,
      ),
      CalculatorQuestion(
        id: 'phq9_q8',
        text:
            'Lentidão para se movimentar ou falar (notada por outras pessoas) ou, ao contrário, agitação e inquietação maior que o habitual',
        options: _phqOptions,
      ),
      CalculatorQuestion(
        id: 'phq9_q9',
        text:
            'Pensamentos de que seria melhor estar morta ou de se ferir de alguma maneira',
        hint:
            'Esta pergunta é de extrema importância para o seu cuidado e acolhimento.',
        options: _phqOptions,
        isCrisisTrigger: true,
      ),
    ],
    compute: (answers) {
      num total = 0;
      for (var i = 1; i <= 9; i++) {
        final val = answers['phq9_q$i'];
        if (val is num) total += val;
      }

      final q9Score = (answers['phq9_q9'] as num?) ?? 0;
      final isCrisis = q9Score > 0;

      final (label, summary, recs) = switch (total) {
        <= 4 => (
            'Sintomas mínimos',
            'Sua pontuação sugere ausência ou níveis mínimos de sintomas depressivos no período avaliado.',
            [
              'Continue cultivando práticas de autocuidado, sono regular e acolhimento.',
            ],
          ),
        <= 9 => (
            'Sintomas leves',
            'Pontuação indicativa de sintomas leves. A dor crônica pode impactar o ânimo e a energia.',
            [
              'Compartilhe como tem se sentido com sua equipe de saúde.',
              'Pequenas pausas e atividades leves prazerosas ajudam na regulação do humor.',
            ],
          ),
        <= 14 => (
            'Sintomas moderados',
            'Pontuação compatível com sintomas moderados de depressão. O sofrimento emocional associado à dor merece atenção.',
            [
              'Recomenda-se conversar com seu médico ou com um psicólogo para avaliação clínica.',
              'O suporte multidisciplinar faz parte do tratamento integral da endometriose.',
            ],
          ),
        <= 19 => (
            'Sintomas moderadamente severos',
            'Pontuação que sugere sintomas moderadamente severos com impacto provável na sua rotina e qualidade de vida.',
            [
              'Procure avaliação com psiquiatra ou psicólogo o quanto antes.',
              'Não enfrente esse momento sozinha: converse com pessoas de sua confiança.',
            ],
          ),
        _ => (
            'Sintomas severos',
            'Pontuação indicativa de sintomas severos. O sofrimento emocional é relevante e necessita de acompanhamento especializado.',
            [
              'Busque atendimento médico ou psicológico especializado prioritariamente.',
              'A dor e a inflamação da endometriose têm forte correlação neurobiológica com o humor e têm tratamento.',
            ],
          ),
      };

      return CalculatorInterpretation(
        score: total,
        maxScore: 27,
        severityLabel: label,
        summary: summary,
        recommendations: recs,
        isCrisisAlert: isCrisis,
        crisisHelpText: isCrisis
            ? 'Você não precisa passar por isso sozinha. Se estiver enfrentando sentimentos difíceis ou pensamentos de se machucar, procure acolhimento imediato. O CVV (Centro de Valorização da Vida) oferece apoio emocional gratuito, confidencial e 24h por dia pelo telefone 188 ou pelo site cvv.org.br.'
            : null,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 3. GAD-7 (GENERALIZED ANXIETY DISORDER-7) - RASTREIO DE ANSIEDADE
  // ---------------------------------------------------------------------------
  static const List<CalculatorQuestionOption> _gadOptions = [
    CalculatorQuestionOption(label: 'Nenhuma vez', score: 0),
    CalculatorQuestionOption(label: 'Vários dias', score: 1),
    CalculatorQuestionOption(label: 'Mais da metade dos dias', score: 2),
    CalculatorQuestionOption(label: 'Quase todos os dias', score: 3),
  ];

  static final CalculatorDefinition gad7 = CalculatorDefinition(
    id: 'gad7',
    title: 'GAD-7 — Rastreio de Ansiedade',
    shortName: 'GAD-7',
    category: CalculatorCategory.qualityOfLife,
    description:
        'Escala de domínio público para triagem e acompanhamento de sintomas de ansiedade nas últimas 2 semanas.',
    instructions:
        'Nas últimas 2 semanas, com que frequência você foi incomodada pelos seguintes problemas?',
    estimatedMinutes: 2,
    questions: const [
      CalculatorQuestion(
        id: 'gad7_q1',
        text: 'Sentir-se nervosa, ansiosa ou muito tensa',
        options: _gadOptions,
      ),
      CalculatorQuestion(
        id: 'gad7_q2',
        text: 'Não ser capaz de impedir ou de controlar as preocupações',
        options: _gadOptions,
      ),
      CalculatorQuestion(
        id: 'gad7_q3',
        text: 'Preocupar-se demais com diversas coisas',
        options: _gadOptions,
      ),
      CalculatorQuestion(
        id: 'gad7_q4',
        text: 'Dificuldade para relaxar',
        options: _gadOptions,
      ),
      CalculatorQuestion(
        id: 'gad7_q5',
        text: 'Ficar tão agitada que se torna difícil ficar parada',
        options: _gadOptions,
      ),
      CalculatorQuestion(
        id: 'gad7_q6',
        text: 'Ficar facilmente irritada ou aborrecida',
        options: _gadOptions,
      ),
      CalculatorQuestion(
        id: 'gad7_q7',
        text: 'Sentir medo como se algo horrível fosse acontecer',
        options: _gadOptions,
      ),
    ],
    compute: (answers) {
      num total = 0;
      for (var i = 1; i <= 7; i++) {
        final val = answers['gad7_q$i'];
        if (val is num) total += val;
      }

      final (label, summary, recs) = switch (total) {
        <= 4 => (
            'Ansiedade mínima',
            'Pontuação dentro da faixa esperada ou de sintomas mínimos de ansiedade.',
            [
              'Mantenha suas rotinas relaxantes e observe como seu corpo responde aos momentos de descanso.',
            ],
          ),
        <= 9 => (
            'Ansiedade leve',
            'Sintomas leves de ansiedade. Preocupações frequentes com consultas e crises podem elevar esse nível.',
            [
              'Exercícios de respiração diafragmática e higiene do sono podem ajudar a acalmar o sistema nervoso.',
              'Anote suas dúvidas para a próxima consulta para diminuir a incerteza.',
            ],
          ),
        <= 14 => (
            'Ansiedade moderada',
            'Sintomas moderados de ansiedade com possível interferência no bem-estar, sono e tensão muscular.',
            [
              'Recomenda-se acompanhamento com psicólogo ou médico.',
              'Técnicas de manejo de dor crônica integradas à psicoterapia apresentam ótimos resultados.',
            ],
          ),
        _ => (
            'Ansiedade severa',
            'Nível elevado de sintomas de ansiedade, com forte impacto no corpo e na mente.',
            [
              'Recomenda-se buscar avaliação profissional especializada (médica/psicológica).',
              'A ansiedade e a dor crônica se retroalimentam; tratar a ansiedade também alivia a percepção da dor.',
            ],
          ),
      };

      return CalculatorInterpretation(
        score: total,
        maxScore: 21,
        severityLabel: label,
        summary: summary,
        recommendations: recs,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 4. CSI (CENTRAL SENSITIZATION INVENTORY) - SENSIBILIZAÇÃO CENTRAL
  // ---------------------------------------------------------------------------
  static const List<CalculatorQuestionOption> _csiOptions = [
    CalculatorQuestionOption(label: 'Nunca', score: 0),
    CalculatorQuestionOption(label: 'Raramente', score: 1),
    CalculatorQuestionOption(label: 'Às vezes', score: 2),
    CalculatorQuestionOption(label: 'Frequentemente', score: 3),
    CalculatorQuestionOption(label: 'Sempre', score: 4),
  ];

  static final CalculatorDefinition csi = CalculatorDefinition(
    id: 'csi',
    title: 'CSI — Inventário de Sensibilização Central',
    shortName: 'CSI',
    category: CalculatorCategory.symptoms,
    description:
        'Avalia manifestações de hipersensibilidade do sistema nervoso central, fadiga e dor nociplástica comuns na endometriose.',
    instructions:
        'Indique com que frequência você apresenta cada uma das situações a seguir no seu dia a dia.',
    estimatedMinutes: 5,
    questions: const [
      CalculatorQuestion(
        id: 'csi_q1',
        text: 'Sinto cansaço mesmo depois de uma noite inteira de sono.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q2',
        text: 'Minha musculatura fica rígida e dolorida.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q3',
        text: 'Tenho episódios de ansiedade.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q4',
        text: 'Tenho dores de dente ou na mandíbula / ATM.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q5',
        text: 'Sinto dor de cabeça ou enxaqueca com frequência.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q6',
        text: 'Tenho dor que se espalha pelo corpo (pernas, costas, quadril).',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q7',
        text: 'Tenho problemas no estômago, como azia, gases ou dor abdominal.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q8',
        text: 'Tenho crises de diarréia ou intestino preso (constipação).',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q9',
        text: 'Sinto dificuldade para urinar ou dor na bexiga.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q10',
        text: 'Sinto desconforto ou dor na região pélvica.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q11',
        text: 'Luzes fortes me incomodam ou causam dor de cabeça.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q12',
        text: 'Certos cheiros me causam náusea ou desconforto.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q13',
        text: 'Sons altos me irritam ou pioram a dor.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q14',
        text: 'Tenho tonturas ou sensação de desequilíbrio.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q15',
        text: 'Sinto frio ou calor com mais facilidade do que as outras pessoas.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q16',
        text: 'Tenho dificuldade para me concentrar nas tarefas cotidianas.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q17',
        text: 'Tenho lapsos de memória ou sensação de "névoa mental".',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q18',
        text: 'Sinto tristeza ou desânimo frequentes.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q19',
        text: 'Sinto que o estresse piora muito minhas dores físicas.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q20',
        text: 'Sinto que meu corpo é excessivamente sensível ao toque ou pressão.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q21',
        text: 'Sinto dormência ou formigamento nas pernas ou braços.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q22',
        text: 'Fico exausta mesmo após pequenas atividades físicas.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q23',
        text: 'A dor interfere na qualidade do meu sono quase todas as noites.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q24',
        text: 'Tenho sensação de cansaço extremo que dura dias após um esforço.',
        options: _csiOptions,
      ),
      CalculatorQuestion(
        id: 'csi_q25',
        text: 'Sinto que meu corpo reage de forma exagerada a medicamentos ou alimentos.',
        options: _csiOptions,
      ),
    ],
    compute: (answers) {
      num total = 0;
      for (var i = 1; i <= 25; i++) {
        final val = answers['csi_q$i'];
        if (val is num) total += val;
      }

      final (label, summary, recs) = switch (total) {
        <= 29 => (
            'Nível subclínico',
            'Pontuação abaixo do ponto de corte para sensibilização central relevante.',
            [
              'Seus sintomas neurossensoriais estão em patamar controlado ou localizado.',
            ],
          ),
        <= 39 => (
            'Sensibilização leve',
            'Sinais discretos de amplificação da dor pelo sistema nervoso.',
            [
              'Abordagens corporais suaves (alongamentos, calor, acupuntura) ajudam a modular os sinais nervosos.',
            ],
          ),
        <= 49 => (
            'Sensibilização moderada',
            'Nível moderado de sensibilização central. É comum que estímulos antes inofensivos provoquem dor.',
            [
              'Compartilhe este resultado com seu médico assistente.',
              'Fisioterapia pélvica e reabilitação neurológica da dor são altamente indicadas.',
            ],
          ),
        <= 59 => (
            'Sensibilização severa',
            'Sinais importantes de amplificação central da dor e hiper-reatividade a estímulos sensoriais.',
            [
              'Abordagem com equipe multidisciplinar de dor crônica (médico da dor, fisioterapeuta, psicólogo) é fundamental.',
            ],
          ),
        _ => (
            'Sensibilização extrema',
            'Nível extremo de sensibilização com dor generalizada, fadiga e hiperalgesia marcadas.',
            [
              'Indica acompanhamento conjunto com centro especializado em dor crônica e endometriose profunda.',
            ],
          ),
      };

      return CalculatorInterpretation(
        score: total,
        maxScore: 100,
        severityLabel: label,
        summary: summary,
        recommendations: recs,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 5. EHP-5 (ENDOMETRIOSIS HEALTH PROFILE-5) - QUALIDADE DE VIDA NA ENDOMETRIOSE
  // ---------------------------------------------------------------------------
  static const List<CalculatorQuestionOption> _ehpOptions = [
    CalculatorQuestionOption(label: 'Nunca', score: 0),
    CalculatorQuestionOption(label: 'Raramente', score: 1),
    CalculatorQuestionOption(label: 'Às vezes', score: 2),
    CalculatorQuestionOption(label: 'Frequentemente', score: 3),
    CalculatorQuestionOption(label: 'Sempre', score: 4),
  ];

  static final CalculatorDefinition ehp5 = CalculatorDefinition(
    id: 'ehp5',
    title: 'EHP-5 — Perfil de Saúde na Endometriose',
    shortName: 'EHP-5',
    category: CalculatorCategory.qualityOfLife,
    description:
        'Questionário específico e validado para endometriose com 5 dimensões nucleares: dor, controle, emoções, suporte e autonomia.',
    instructions:
        'Pensando nas últimas 4 semanas, com que frequência você vivenciou cada uma das seguintes situações por causa da endometriose?',
    estimatedMinutes: 2,
    questions: const [
      CalculatorQuestion(
        id: 'ehp5_q1',
        text: 'Por causa da endometriose, com que frequência você sentiu dor intensa?',
        hint: 'Dimensão: Dor física.',
        options: _ehpOptions,
      ),
      CalculatorQuestion(
        id: 'ehp5_q2',
        text: 'Com que frequência você sentiu que a endometriose estava controlando a sua vida?',
        hint: 'Dimensão: Controle e autonomia.',
        options: _ehpOptions,
      ),
      CalculatorQuestion(
        id: 'ehp5_q3',
        text: 'Com que frequência você se sentiu triste, deprimida ou desanimada por causa da endometriose?',
        hint: 'Dimensão: Bem-estar emocional.',
        options: _ehpOptions,
      ),
      CalculatorQuestion(
        id: 'ehp5_q4',
        text: 'Com que frequência você sentiu que as pessoas ao seu redor não entendiam pelo que você estava passando?',
        hint: 'Dimensão: Suporte social e relacionamentos.',
        options: _ehpOptions,
      ),
      CalculatorQuestion(
        id: 'ehp5_q5',
        text: 'Com que frequência você sentiu frustração por não conseguir realizar suas atividades cotidianas?',
        hint: 'Dimensão: Autonomia e rotina.',
        options: _ehpOptions,
      ),
    ],
    compute: (answers) {
      num rawSum = 0;
      for (var i = 1; i <= 5; i++) {
        final val = answers['ehp5_q$i'];
        if (val is num) rawSum += val;
      }

      // Converte para percentual de comprometimento (0 a 100%)
      final percentage = (rawSum / 20.0) * 100.0;

      final (label, summary, recs) = switch (percentage) {
        <= 20 => (
            'Impacto mínimo',
            'A endometriose gerou pouco ou nenhum comprometimento nas 5 áreas de qualidade de vida no último mês.',
            [
              'Excelente período de controle. Mantenha os tratamentos e rotinas que estão funcionando bem para você.',
            ],
          ),
        <= 40 => (
            'Impacto leve',
            'Comprometimento leve a moderado em algumas dimensões do dia a dia.',
            [
              'Registre no diário de impacto quais áreas específicas (trabalho, sono, relacionamentos) mais sentiram o impacto.',
            ],
          ),
        <= 60 => (
            'Impacto moderado',
            'Impacto substancial na rotina, controle da vida e bem-estar emocional.',
            [
              'Leve esse percentual para discussão com seu médico na próxima consulta para avaliar ajustes no plano terapêutico.',
            ],
          ),
        <= 80 => (
            'Impacto alto',
            'Comprometimento relevante e frequente em quase todas as dimensões de vida.',
            [
              'Necessidade clara de reforço terapêutico e suporte multiprofissional (médico, fisioterapia e apoio psicológico).',
            ],
          ),
        _ => (
            'Impacto muito alto',
            'A endometriose está exercendo forte impacto na sua autonomia, vitalidade e qualidade de vida.',
            [
              'Converse urgentemente com seu médico sobre revisão das estratégias de tratamento da dor e suporte social.',
            ],
          ),
      };

      return CalculatorInterpretation(
        score: percentage,
        maxScore: 100,
        severityLabel: label,
        summary: '$summary (Índice de comprometimento: ${percentage.round()}%).',
        recommendations: recs,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 6. JANELA FÉRTIL E ESTIMATIVA REPRODUTIVA
  // ---------------------------------------------------------------------------
  static final CalculatorDefinition fertilityWindow = CalculatorDefinition(
    id: 'janela_fertil',
    title: 'Janela Fértil e Estimativa Reprodutiva',
    shortName: 'Janela Fértil',
    category: CalculatorCategory.reproductiveHealth,
    description:
        'Estima o período fértil e o dia provável da ovulação com base na duração média do ciclo menstrual.',
    instructions:
        'Informe a duração média do seu ciclo menstrual e a quantidade de dias desde o início da sua última menstruação.',
    estimatedMinutes: 2,
    questions: const [
      CalculatorQuestion(
        id: 'cycle_duration',
        text: 'Qual é a duração média habitual do seu ciclo menstrual (em dias)?',
        hint: 'A maioria dos ciclos dura entre 24 e 35 dias (média 28).',
        type: QuestionInputType.slider,
        minSliderValue: 21,
        maxSliderValue: 40,
        sliderDivisions: 19,
        sliderMinLabel: '21 dias',
        sliderMaxLabel: '40 dias',
      ),
      CalculatorQuestion(
        id: 'days_since_period',
        text: 'Há quantos dias começou a sua última menstruação (Dia 1)?',
        hint: 'Ex.: se a menstruação começou hoje, selecione 0.',
        type: QuestionInputType.slider,
        minSliderValue: 0,
        maxSliderValue: 35,
        sliderDivisions: 35,
        sliderMinLabel: 'Hoje (0)',
        sliderMaxLabel: '35 dias atrás',
      ),
    ],
    compute: (answers) {
      final rawCycle = answers['cycle_duration'];
      final rawDays = answers['days_since_period'];

      final cycleLength = rawCycle is num ? rawCycle.round() : 28;
      final daysSince = rawDays is num ? rawDays.round() : 1;

      // Ovulação ocorre aproximadamente 14 dias antes da próxima menstruação
      final ovulationDay = (cycleLength - 14).clamp(7, 30);
      final windowStart = (ovulationDay - 5).clamp(1, 30);
      final windowEnd = (ovulationDay + 1).clamp(1, 35);

      final isCurrentlyInWindow =
          daysSince >= windowStart && daysSince <= windowEnd;
      final daysUntilOvulation = ovulationDay - daysSince;

      final label = isCurrentlyInWindow
          ? 'Janela fértil ativa'
          : (daysUntilOvulation > 0
              ? 'Fase folicular pré-ovulatória'
              : 'Fase lútea pós-ovulatória');

      final summary = isCurrentlyInWindow
          ? 'Você está no período de maior probabilidade de ovulação e concepção (estimada entre os dias $windowStart e $windowEnd do seu ciclo).'
          : (daysUntilOvulation > 0
              ? 'A ovulação estimada ocorrerá por volta do dia $ovulationDay do seu ciclo (faltam aproximadamente $daysUntilOvulation dias).'
              : 'A ovulação deste ciclo provavelmente já ocorreu (dia estimado $ovulationDay). Você está na fase lútea.');

      return CalculatorInterpretation(
        score: ovulationDay,
        maxScore: cycleLength,
        severityLabel: label,
        summary: summary,
        recommendations: const [
          'A janela fértil tem duração aproximada de 6 dias (os 5 dias anteriores à ovulação e o próprio dia da ovulação).',
          'Na endometriose, o acompanhamento reprodutivo com especialista em fertilidade pode ser planejado com antecedência quando houver desejo reprodutivo.',
          'Importante: ciclos variam naturalmente; não utilize este cálculo como método contraceptivo seguro.',
        ],
        disclaimer:
            'Aviso de fertilidade: este cálculo é puramente estimativo e probabilístico. '
            'Variações no ciclo menstrual, anovulação e fatores anatômicos da endometriose '
            'podem alterar a ovulação. Não utilize como método contraceptivo.',
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 7. APOIO AO ESTADIAMENTO MÉDICO (rASRM / #ENZIAN) - PARA USO COM MÉDICO
  // ---------------------------------------------------------------------------
  static final CalculatorDefinition stagingInfo = CalculatorDefinition(
    id: 'estadiamento_medico',
    title: 'Classificação Cirúrgica e Estadiamento (rASRM / #Enzian)',
    shortName: 'Estadiamento',
    category: CalculatorCategory.professionalStaging,
    forDoctorUse: true,
    doctorNotes:
        'Preenchimento em conjunto com seu médico ginecologista ou com base no laudo da sua videolaparoscopia/ressonância magnética.',
    description:
        'Ferramenta informativa para registrar o estadiamento cirúrgico da endometriose (rASRM graus I a IV e compartimentos #Enzian).',
    instructions:
        'Consulte o laudo do seu procedimento ou converse com seu médico para selecionar o grau informado.',
    estimatedMinutes: 2,
    questions: const [
      CalculatorQuestion(
        id: 'staging_asrm',
        text: 'Qual foi o estágio rASRM indicado no seu laudo médico?',
        options: [
          CalculatorQuestionOption(
            label: 'Grau I — Mínima',
            score: 1,
            subtitle: 'Implantes superficiais isolados, sem aderências relevantes',
          ),
          CalculatorQuestionOption(
            label: 'Grau II — Leve',
            score: 2,
            subtitle: 'Implantes superficiais menores que 5 cm sem aderências densas',
          ),
          CalculatorQuestionOption(
            label: 'Grau III — Moderada',
            score: 3,
            subtitle: 'Múltiplos implantes, endometriomas ovarianos e aderências peritubárias',
          ),
          CalculatorQuestionOption(
            label: 'Grau IV — Severa',
            score: 4,
            subtitle: 'Múltiplos implantes profundos, grandes endometriomas e fundo de saco obliterado',
          ),
        ],
      ),
    ],
    compute: (answers) {
      final raw = answers['staging_asrm'];
      final stage = raw is num ? raw.round() : 1;

      final (label, summary) = switch (stage) {
        1 => (
            'Estágio I (Mínima)',
            'Endometriose mínima conforme a classificação rASRM. Nota: o grau cirúrgico não tem correlação direta obrigatória com a intensidade da dor sentida.',
          ),
        2 => (
            'Estágio II (Leve)',
            'Endometriose leve com implantes superficiais e poucas aderências.',
          ),
        3 => (
            'Estágio III (Moderada)',
            'Endometriose moderada com presença de aderências e/ou endometriomas ovarianos.',
          ),
        _ => (
            'Estágio IV (Severa)',
            'Endometriose severa/profunda com aderências firmes e obliteração anatômica.',
          ),
      };

      return CalculatorInterpretation(
        score: stage,
        maxScore: 4,
        severityLabel: label,
        summary: summary,
        recommendations: const [
          'O estadiamento cirúrgico avalia a extensão anatômica das lesões, mas a dor é individual e multifatorial.',
          'Salve este registro para que ele conste no seu relatório médico consolidado.',
        ],
        disclaimer:
            'A classificação rASRM/#Enzian é estritamente cirúrgica e médica. '
            'Deve ser confirmada pelo cirurgião ginecologista responsável.',
      );
    },
  );

  /// Lista com todas as calculadoras ativas no app.
  static final List<CalculatorDefinition> all = [
    eva,
    phq9,
    gad7,
    csi,
    ehp5,
    fertilityWindow,
    stagingInfo,
  ];

  static CalculatorDefinition? findById(String id) {
    for (final calc in all) {
      if (calc.id == id) return calc;
    }
    return null;
  }
}

