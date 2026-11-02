/// Caminhos e nomes de rotas centrais do EndoCare.
abstract final class AppRoutes {
  // Autenticação, boas-vindas e estado inicial
  static const String splash = '/carregando';
  static const String onboarding = '/boas-vindas';
  static const String login = '/entrar';
  static const String register = '/cadastro';
  static const String forgotPassword = '/recuperar-senha';
  static const String verifyEmail = '/verificar-email';

  // Navegação principal (protegida)
  static const String home = '/inicio';
  static const String calendar = '/calendario';
  static const String quickLog = '/registrar';
  static const String care = '/cuidar';
  static const String more = '/mais';

  // Telas internas protegidas
  static const String bodyMap = '/mapa-corporal';
  static const String impact = '/diario-impacto';
  static const String timeline = '/linha-do-tempo';
  static const String calculators = '/calculadoras';
  static const String calculatorQuestionnaire = '/calculadoras/:id';

  // Nomes de rotas
  static const String splashName = 'splash';
  static const String onboardingName = 'onboarding';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String forgotPasswordName = 'forgot-password';
  static const String verifyEmailName = 'verify-email';
  static const String homeName = 'home';
  static const String calendarName = 'calendar';
  static const String quickLogName = 'quick-log';
  static const String careName = 'care';
  static const String moreName = 'more';
  static const String bodyMapName = 'body-map';
  static const String impactName = 'impact';
  static const String timelineName = 'timeline';
  static const String calculatorsName = 'calculators';
  static const String calculatorQuestionnaireName = 'calculator-questionnaire';

  static const Set<String> publicAuthPaths = {
    login,
    register,
    forgotPassword,
  };
}
