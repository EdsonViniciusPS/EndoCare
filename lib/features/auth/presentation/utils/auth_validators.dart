/// Validadores simples e acolhedores em português do Brasil para formulários de autenticação.
abstract final class AuthValidators {
  static final RegExp _emailRegex = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static String? validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Informe como você gostaria de ser chamada.';
    }
    if (trimmed.length < 2) {
      return 'Informe pelo menos 2 letras.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Informe seu e-mail.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Digite um e-mail válido (ex.: nome@dominio.com).';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final raw = value ?? '';
    if (raw.isEmpty) {
      return 'Informe sua senha.';
    }
    if (raw.length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    final raw = value ?? '';
    if (raw.isEmpty) {
      return 'Confirme sua senha.';
    }
    if (raw != password) {
      return 'As senhas não coincidem.';
    }
    return null;
  }
}

