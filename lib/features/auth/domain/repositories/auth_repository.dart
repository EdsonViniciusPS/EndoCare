import 'package:endocare/features/auth/domain/models/app_auth_user.dart';

/// Contrato de autenticação do EndoCare (e-mail e senha).
abstract interface class AuthRepository {
  /// Emite mudanças de sessão e de estado da usuária (incluindo `emailVerified`).
  Stream<AppAuthUser?> authStateChanges();

  /// Usuária atualmente autenticada (se houver).
  AppAuthUser? get currentUser;

  /// Cria conta com e-mail e senha, grava `users/{uid}` e envia verificação de e-mail.
  Future<AppAuthUser> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    DateTime? birthDate,
  });

  /// Realiza login com e-mail e senha e garante o documento `users/{uid}`.
  Future<AppAuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Envia link de redefinição de senha para o e-mail informado.
  Future<void> sendPasswordResetEmail({required String email});

  /// Reenvia o e-mail de confirmação da conta atual.
  Future<void> sendEmailVerification();

  /// Recarrega os dados da usuária no servidor (para checar `emailVerified`).
  Future<AppAuthUser?> reloadCurrentUser();

  /// Remove o token FCM deste aparelho e encerra a sessão.
  Future<void> signOut();
}

