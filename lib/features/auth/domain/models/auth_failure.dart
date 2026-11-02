import 'package:firebase_auth/firebase_auth.dart';

/// Erro de domínio amigável para fluxos de autenticação em português do Brasil.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  factory AuthFailure.fromFirebaseAuthException(FirebaseAuthException error) {
    final friendlyMessage = switch (error.code) {
      'invalid-email' =>
        'O e-mail informado não parece válido. Confira e tente novamente.',
      'user-disabled' =>
        'Esta conta foi desativada. Entre em contato com o suporte se precisar de ajuda.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'E-mail ou senha incorretos. Confira seus dados e tente novamente.',
      'email-already-in-use' =>
        'Este e-mail já está cadastrado. Tente entrar ou recuperar sua senha.',
      'weak-password' =>
        'Escolha uma senha um pouco mais forte (mínimo de 6 caracteres).',
      'too-many-requests' =>
        'Muitas tentativas seguidas. Aguarde alguns instantes antes de tentar novamente.',
      'network-request-failed' =>
        'Sem conexão no momento. Verifique sua internet e tente novamente.',
      'requires-recent-login' =>
        'Por segurança, entre novamente na sua conta para concluir esta ação.',
      'operation-not-allowed' =>
        'O login por e-mail e senha ainda não está habilitado no servidor.',
      _ =>
        'Não foi possível concluir sua solicitação agora. Tente novamente em instantes.',
    };

    return AuthFailure(friendlyMessage, code: error.code);
  }

  @override
  String toString() => message;
}

