# EndoCare — Especificação do Aplicativo

App acolhedor, moderno e simples para **mulheres e moças com endometriose** e para **controle menstrual**. Este documento descreve funções, design, arquitetura e um plano de desenvolvimento em etapas para um agente de IA implementar em **Flutter**.

---

## 1. Visão geral

| Item | Definição |
|---|---|
| Público | Mulheres e moças com endometriose ou suspeita, e qualquer pessoa que queira controle menstrual |
| Plataformas | Android e iOS (Flutter) |
| Princípio de UX | Registrar em poucos segundos, sem formulários enormes |
| Tom | Acolhedor, claro, sem jargão médico desnecessário |
| Backend | Firebase Auth (email e senha), Cloud Firestore, Firebase Cloud Messaging |

---

## 2. Design

### 2.1 Estilo visual
- Baseado em **Storyset** e **flat illustration**.
- Cantos arredondados, cores suaves, bastante espaço em branco.
- Efeitos pontuais com os pacotes já no projeto (mesh gradient, neo glass), sem poluir a interface.

### 2.2 Logos (`assets/logos/`)

Usar **exclusivamente** os 3 arquivos JPEG já existentes em `assets/logos/` (não criar nem referenciar versões SVG, PNG, 1x1, vertical ou azul):

| Arquivo | Descrição | Uso no app |
|---|---|---|
| `logo_horizontal.jpg` | Logo principal horizontal (símbolo + texto "EndoCare" em tons malva, rosa e pêssego sobre fundo branco) | Splash screen, login/cadastro, cabeçalhos amplos e tela "Sobre" |
| `logo_negative_bw.jpg` | Logo horizontal monocromática P&B (símbolo + texto em grafite/preto sobre fundo branco) | Contextos monocromáticos, alto contraste, impressão P&B (ou inversão via filtro em fundo escuro) |
| `wordmark.jpg` | Somente logotipo tipográfico ("EndoCare" em malva e rosa sobre fundo branco) | AppBars compactas, rodapés, cabeçalho de relatórios PDF e documentos |

> **Nota técnica (JPEG):** todos os logos são renderizados via `Image.asset` e possuem fundo branco (`#FFFFFF`). Aplicá-los sobre superfícies claras, containers brancos com cantos arredondados ou com tratamento de blend/filtro adequado quando houver fundo colorido ou escuro.

Estrutura real dos assets existentes no projeto:

```
assets/
  logos/
    logo_horizontal.jpg
    logo_negative_bw.jpg
    wordmark.jpg
  storysets/
    # 32 ilustrações SVG locais (com variações de estilo e cor)
```

### 2.3 Ilustrações Storyset (`assets/storysets/`)

Todas as ilustrações já estão disponíveis localmente em `assets/storysets/` em formato `.svg` (renderizadas com `flutter_svg`). Respeitar os nomes exatos dos arquivos (incluindo espaços, maiúsculas/minúsculas como `personal growth-bro.svg` e sufixos `(1)`):

| Contexto no app | Arquivos existentes em `assets/storysets/` (e cor de destaque) |
|---|---|
| Onboarding, boas-vindas, bem-estar | `Peace of mind-bro.svg` (rosa), `personal growth-bro.svg` (coral), `Healthy habit-rafiki.svg` (azul/pêssego) |
| Dor, mal-estar, registro de sintomas | `Dizzy face-amico.svg` (pêssego/roxo), `Overwhelmed-rafiki.svg` (rosa), `Overwhelmed-pana.svg` (coral) |
| Humor e saúde mental | `Anxiety-bro.svg` (rosa), `Anxiety-pana.svg` (coral), `Anxiety-rafiki.svg` (azul), `Mental health-bro.svg` (verde menta), `Mental health-cuate.svg` (amarelo) |
| Sintomas intestinais | `Gut health-amico.svg` (rosa) |
| Mapa corporal | `Types of female body shapes-amico.svg` (roxo/rosado) |
| Calendário e ciclo | `Calendar-bro.svg` (rosa), `Menstrual calendar-amico.svg` (vermelho), `Menstrual calendar-amico (1).svg` (rosa), `Menstrual calendar-rafiki.svg` (azul) |
| Tratamentos e medicamentos | `Medical prescription-amico.svg` (rosa) |
| Biblioteca, educação e ginecologia | `Woman reading-pana.svg` (coral), `Female reproductive system-amico.svg` (lilás), `Female reproductive system-amico (1).svg` (rosa), `Female reproductive system-bro.svg` (rosa), `Female reproductive system-cuate.svg` (amarelo), `Female reproductive system-pana.svg` (coral), `Female reproductive system-rafiki.svg` (azul), `Female reproductive system-rafiki (1).svg` (rosa) |
| Fertilidade | `Woman infertility-amico.svg` (roxo) |
| Imunidade e alimentação | `Boost your immune system-bro.svg` (rosa) |
| Estados vazios e apoio emocional | `Eating disorder-bro.svg` (rosa), `Eating disorder-cuate.svg` (amarelo/rosado), `Eating disorder-pana.svg` (coral), `Eating disorder-rafiki.svg` (azul) |

**Uso dinâmico das variações de cores e estilos (para não ficar repetitivo):**
- Alguns Storysets possuem **variações diretas de cor da mesma arte** — `Menstrual calendar-amico` (vermelho `#C53F3F` vs rosa `#FF81AE`), `Female reproductive system-amico` (lilás `#BA68C8` vs rosa `#FF81AE`) e `Female reproductive system-rafiki` (azul `#407BFF` vs rosa `#FF81AE`) — além de famílias com **múltiplos estilos e paletas** (`bro`, `pana`, `rafiki`, `amico`, `cuate` em rosa, coral, azul, lilás, verde menta e amarelo).
- **Alternância por contexto e estado:** variar a ilustração conforme a fase ou dado exibido (ex.: no calendário, usar `Menstrual calendar-amico.svg` em vermelho nos dias de fluxo menstrual, `Menstrual calendar-amico (1).svg` em rosa ou `Menstrual calendar-rafiki.svg` em azul em outras fases/visões e `Calendar-bro.svg` em agendamentos; em sintomas/humor, alternar conforme intensidade ou emoção selecionada).
- **Distribuição sem repetição em listas e fluxos:** nas 3 telas de Onboarding, nos cards da Biblioteca, nas categorias de Calculadoras e nos Estados Vazios, distribuir variações de cores distintas por índice ou categoria (`index % variacoes.length`) para que telas seguidas ou cards vizinhos nunca repitam a mesma arte/cor.
- **Rotação leve no Início:** alternar a ilustração de boas-vindas/resumo por dia ou período (`dayOfYear % variacoes.length`) dentro do grupo temático correspondente, trazendo frescor visual ao uso diário.

> Atenção: as ilustrações `Eating disorder-*.svg` retratam originalmente outro tema. Use apenas onde o contexto visual fizer sentido (ex.: estados vazios genéricos e acolhimento emocional) e mantenha a atribuição exigida pela licença Storyset/Freepik (ex.: na tela "Sobre").

---

## 3. Funções principais

### 01. Registro diário de sintomas
Interface simples, com registro completo em poucos segundos.
- Intensidade da dor (0–10).
- Localização da dor no mapa corporal.
- Cólicas e dores pélvicas.
- Dor durante relações sexuais: local e escala.
- Sintomas intestinais e urinários.
- Fadiga, náuseas e inchaço.
- Humor e qualidade do sono.

**Registro rápido:** tela única com chips e sliders, valores padrão do dia anterior, botão "Salvar" fixo. Detalhes opcionais ficam recolhidos.

### 02. Calendário menstrual e ciclo
Calendário interativo com:
- Menstruação e fluxo.
- Período de ovulação estimado.
- Dias de dor.
- Crises de sintomas.
- Medicamentos utilizados.
- Consultas e exames.

**Diferencial:** cruzar calendário e sintomas para mostrar padrões individuais, **sem presumir** que todo sintoma esteja ligado ao ciclo.

### 03. Inteligência artificial de acompanhamento
Assistente especializado em endometriose:
- Responde dúvidas educativas.
- Explica termos médicos.
- Ajuda a organizar sintomas.
- Identifica padrões nos registros.
- Prepara perguntas para consultas.
- Orienta quando procurar avaliação médica.

**Regras de segurança (obrigatórias):**
- Não diagnostica nem prescreve; sempre reforça que não substitui o médico.
- Sinais de alerta (dor súbita e intensa, sangramento muito volumoso, desmaio, febre com dor pélvica) geram orientação para atendimento imediato.
- Chamada à IA feita por backend (Cloud Functions), nunca com chave de API dentro do app.

### 04. Relatórios inteligentes para médicos
Funcionalidade de maior valor do produto. PDF com:
- Histórico de sintomas.
- Evolução da intensidade da dor.
- Frequência das crises.
- Ciclo menstrual.
- Medicamentos registrados.
- Impacto na rotina.
- Observações da paciente.

A paciente escolhe o período, gera o PDF e compartilha com o ginecologista.

### 05. Biblioteca de conhecimento
Conteúdo educativo sobre:
- O que é endometriose.
- Adenomiose e condições associadas.
- Tratamentos disponíveis.
- Alimentação e qualidade de vida.
- Fertilidade.
- Saúde mental.
- Exercícios e bem-estar.

Cada artigo exibe: fontes confiáveis, profissional revisor, data da última atualização.

### 06. Gestão de tratamentos
- Cadastro de medicamentos.
- Lembretes de horários (push).
- Registro de efeitos percebidos.
- Histórico de tratamentos.
- Agendamento de consultas e exames.
- Registro de procedimentos.

### 07. Calculadoras clínicas
Seção com ferramentas fáceis de usar, uma pergunta por tela quando for questionário.

**1. Avaliação de sintomas**
- Escala EVA (intensidade da dor)
- Monitoramento do ciclo menstrual
- Dor pélvica
- Registro de sintomas
- Sintomas intestinais / monitoramento gastrointestinal

**2. Apoio diagnóstico e classificação**
- rASRM
- #Enzian
- AAGL
- UBESS
- dPEI

**3. Saúde reprodutiva**
- EFI
- Avaliação de histórico reprodutivo
- Janela fértil
- Acompanhamento de fertilidade

**4. Qualidade de vida**
- EHP-30
- EHP-5
- SF-36
- GAD-7
- PHQ-9
- CSI

**Pontos de atenção:**
- rASRM, #Enzian, AAGL, UBESS, dPEI e EFI são classificações e índices baseados em achados cirúrgicos ou de imagem, normalmente preenchidos por profissionais. Sugestão: marcar essas calculadoras como "para uso com seu médico" e permitir salvar o resultado para o relatório.
- EHP-30, EHP-5 e SF-36 têm licenciamento. Confirmar direitos de uso e versão validada em português do Brasil antes de publicar.
- PHQ-9 e GAD-7 são de domínio público. Resultado de depressão ou ansiedade deve sempre exibir orientação de apoio profissional e, no item 9 do PHQ-9, um fluxo de ajuda imediata (CVV 188).
- Toda calculadora mostra interpretação em linguagem simples e aviso de que o resultado não é diagnóstico.

---

## 4. Diferenciais

1. **Mapa corporal interativo:** seleção da região exata da dor. Registra localização anatômica, intensidade, tipo, duração e frequência. Gera mapa histórico (heatmap) ao longo do tempo.
2. **Linha do tempo da doença:** crises, consultas, exames, cirurgias, tratamentos e mudanças de sintomas em uma visão única.
3. **Diário de impacto na qualidade de vida:** registro de efeitos da dor em trabalho, estudos, sono, exercícios, relacionamentos e rotina.
4. **Preparação para consultas:** antes da consulta, a IA resume o que aconteceu desde a última visita e sugere perguntas para levar ao médico.

---

## 5. Firebase

| Serviço | Uso |
|---|---|
| Firebase Auth | Cadastro, login, recuperação de senha e verificação de email (email e senha) |
| Cloud Firestore | Registros de sintomas, ciclo, tratamentos, consultas, resultados de calculadoras, conteúdo da biblioteca |
| Firebase Cloud Messaging | Push: lembretes de medicamento, consulta, previsão de menstruação e registro diário |
| Cloud Functions (recomendado) | Proxy seguro da IA, agendamento de pushes, geração de agregados |

### 5.1 Modelo de dados (Firestore)

```
users/{uid}
  profile: nome, nascimento, preferências, fcmTokens[]
  symptomLogs/{logId}      # data, dor(0-10), regiões[], tipos[], intestinal, urinário,
                           # fadiga, náusea, inchaço, humor, sono, dorRelação{local, escala}, notas
  cycleEntries/{id}        # data, fluxo, ovulaçãoEstimada, observações
  treatments/{id}          # medicamento, dose, horários[], início, fim, ativo
  treatmentEffects/{id}    # treatmentId, data, efeito, intensidade
  appointments/{id}        # tipo (consulta|exame|procedimento), data, local, notas, status
  impactLogs/{id}          # data, trabalho, estudos, sono, exercício, relacionamentos, rotina
  calculatorResults/{id}   # calculadora, data, respostas, pontuação, interpretação
  reports/{id}             # período, data de geração, caminho do arquivo
articles/{articleId}       # título, categoria, corpo, fontes[], revisor, atualizadoEm
```

### 5.2 Regras de segurança
- Cada usuária lê e escreve **apenas** em `users/{uid}/**` quando `request.auth.uid == uid`.
- `articles` somente leitura para autenticadas.
- Validar tipos e limites (ex.: dor entre 0 e 10) nas regras.

### 5.3 Privacidade
São dados de saúde, sensíveis pela **LGPD**. Prever: consentimento explícito, política de privacidade, exportação e exclusão de conta e dados.

---

## 6. Pacotes

**Já existentes no projeto**
`cupertino_icons`, `fl_chart`, `intl`, `google_fonts`, `flutter_animate`, `lucide_icons`, `mesh_gradient`, `flutter_shaders_ui`, `neo_glass`, `rive`, `lottie`, `flutter_staggered_animations`

**A adicionar (sugestão)**

| Pacote | Uso |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging` | Firebase |
| `flutter_local_notifications`, `timezone` | Lembretes locais agendados |
| `flutter_riverpod` | Estado |
| `go_router` | Navegação |
| `table_calendar` | Calendário |
| `flutter_svg` | Ilustrações Storyset em SVG (`assets/storysets/`) |
| `pdf`, `printing`, `share_plus` | Relatórios PDF |
| `cloud_functions` | Chamar a IA com segurança |

---

## 7. Estrutura de telas

```
Onboarding (3 telas) → Cadastro / Login

Navegação inferior
├── Início        resumo do dia, botão de registro rápido, próximos lembretes
├── Calendário    ciclo, sintomas, medicamentos, consultas
├── Registrar     registro rápido de sintomas (botão central)
├── Cuidar        tratamentos, consultas, calculadoras
└── Mais          IA, relatórios, biblioteca, linha do tempo, perfil, configurações
```

**Telas principais**
1. Splash, Onboarding, Login, Cadastro, Recuperar senha
2. Início (dashboard)
3. Registro rápido de sintomas + detalhes opcionais
4. Mapa corporal (frente e costas)
5. Diário de impacto
6. Calendário + detalhe do dia
7. Tratamentos (lista, novo, efeitos, histórico)
8. Consultas e exames
9. Calculadoras (lista por categoria, questionário, resultado)
10. Assistente de IA (chat) + preparação para consulta
11. Linha do tempo
12. Relatórios (escolher período, prévia, compartilhar)
13. Biblioteca (categorias, artigo)
14. Perfil, notificações, privacidade, excluir conta

---

## 8. Plano de desenvolvimento em etapas (para o agente de IA)

Regras gerais para o agente: executar **uma etapa por vez**, rodar `flutter analyze` ao final de cada uma, manter código por feature (`lib/features/<nome>/`), usar textos em português do Brasil e entregar cada etapa funcionando antes de seguir.

### Etapa 0 — Fundação
- Estrutura de pastas por feature, tema (cores, tipografia com `google_fonts`), componentes base (botões, cards, chips, sliders).
- Declarar no `pubspec.yaml` apenas os assets existentes (`assets/logos/` com os 3 JPEGs e `assets/storysets/` com os 32 SVGs), criar catálogo central de assets (`AppAssets`) com grupos temáticos e rotação dinâmica das variações de cores/estilos, e configurar `go_router` e `flutter_riverpod`.
- **Pronto quando:** app abre com tema aplicado e navegação inferior vazia.

### Etapa 1 — Firebase e autenticação
- Configurar Firebase (core, auth, firestore, messaging).
- Cadastro, login, recuperação de senha, verificação de email, logout.
- Guard de rotas e criação do documento `users/{uid}`.
- Regras de segurança do Firestore.
- **Pronto quando:** usuária cria conta, entra, sai e só acessa seus dados.

### Etapa 2 — Onboarding e Início
- Onboarding com ilustrações de `assets/storysets/` (uma paleta/arte distinta por tela) e animações (`flutter_animate`).
- Tela Início com resumo, ilustração contextual rotativa e atalho de registro.
- **Pronto quando:** primeiro acesso passa pelo onboarding e cai no Início.

### Etapa 3 — Registro diário de sintomas
- Tela de registro rápido (dor 0–10, chips de sintomas, humor, sono).
- Seção opcional: cólicas, dor em relação sexual (local e escala), intestinal e urinário, fadiga, náusea, inchaço.
- Salvar em `symptomLogs`; reaproveitar valores do dia anterior.
- **Pronto quando:** registro completo em menos de 30 segundos.

### Etapa 4 — Mapa corporal interativo
- Silhueta frente e costas (SVG) com regiões tocáveis.
- Por região: intensidade, tipo de dor, duração, frequência.
- Heatmap histórico agregado.
- **Pronto quando:** regiões selecionadas são salvas e exibidas no histórico.

### Etapa 5 — Calendário e ciclo
- Calendário com fluxo, menstruação, ovulação estimada, dias de dor, crises, medicamentos, consultas.
- Estimativa de ciclo e ovulação com aviso de que é aproximada.
- Gráficos de cruzamento ciclo × sintomas com `fl_chart`, sem afirmar causalidade.
- **Pronto quando:** dados dos módulos 3 e 5 aparecem juntos no calendário.

### Etapa 6 — Gestão de tratamentos e consultas
- CRUD de medicamentos, horários, efeitos, histórico, procedimentos.
- Consultas e exames com agendamento.
- Lembretes locais e push (FCM).
- **Pronto quando:** lembrete dispara no horário configurado.

### Etapa 7 — Diário de impacto e linha do tempo
- Registro de impacto (trabalho, estudos, sono, exercícios, relacionamentos, rotina).
- Linha do tempo unificando crises, consultas, exames, cirurgias, tratamentos e mudanças.
- **Pronto quando:** eventos de todos os módulos aparecem em ordem cronológica.

### Etapa 8 — Calculadoras clínicas
- Motor genérico de questionários (perguntas, pontuação, interpretação) configurado por dados.
- Implementar primeiro: EVA, PHQ-9, GAD-7, CSI, EHP-5; depois EHP-30, SF-36 (após confirmar licença) e as demais.
- Janela fértil e acompanhamento de fertilidade usando dados do ciclo.
- Salvar resultados em `calculatorResults`.
- **Pronto quando:** cada calculadora retorna pontuação, interpretação simples e aviso de não diagnóstico.

### Etapa 9 — Assistente de IA
- Cloud Function como proxy do modelo, com prompt de sistema especializado e regras de segurança da seção 3.
- Chat com histórico, atalhos ("Explicar termo", "Organizar sintomas", "Preparar consulta").
- Contexto enviado: resumo dos registros do período, com consentimento.
- **Pronto quando:** IA responde, detecta sinais de alerta e gera perguntas para consulta.

### Etapa 10 — Relatórios para médicos
- Agregação do período: sintomas, evolução da dor, frequência de crises, ciclo, medicamentos, impacto, observações, resultados de calculadoras.
- Geração de PDF com `assets/logos/wordmark.jpg` (ou `logo_negative_bw.jpg` em modo P&B), gráficos e resumo; compartilhar via `share_plus`.
- **Pronto quando:** PDF legível em uma a três páginas e compartilhável.

### Etapa 11 — Biblioteca de conhecimento
- Lista por categoria, busca, artigo com fontes, revisor e data de atualização (alternando as variações de cores e estilos de `assets/storysets/` entre categorias e cards para evitar repetição).
- Conteúdo no Firestore (`articles`) para atualização sem nova versão do app.
- **Pronto quando:** artigos carregam offline após primeiro acesso (cache).

### Etapa 12 — Notificações push
- Tokens FCM por usuária, permissões iOS e Android 13+.
- Tipos: medicamento, consulta, previsão de menstruação, lembrete de registro diário.
- Preferências de notificação na tela de configurações.
- **Pronto quando:** usuária controla cada tipo de lembrete.

### Etapa 13 — Privacidade, polimento e entrega
- Consentimento LGPD, exportar e excluir dados e conta.
- Acessibilidade (contraste, tamanhos de fonte, leitores de tela), estados vazios variados com as ilustrações de `assets/storysets/`, animações finais (Lottie e Rive).
- Testes dos fluxos críticos, splash e cabeçalhos usando apenas os logos JPEG existentes em `assets/logos/`, build de release.
- **Pronto quando:** checklist de lojas (Google Play e App Store) concluído.

---

## 9. Critérios de qualidade
- Registro de sintomas em poucos segundos.
- Nenhum diagnóstico automático; linguagem sempre informativa.
- Conteúdo de saúde com fonte e revisão profissional.
- Dados protegidos por regras Firestore e consentimento.
- Interface fácil de entender para quem está com dor ou cansada.
