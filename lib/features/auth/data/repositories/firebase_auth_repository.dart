import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:endocare/core/firebase/fcm_token_service.dart';
import 'package:endocare/features/auth/domain/models/app_auth_user.dart';
import 'package:endocare/features/auth/domain/models/auth_failure.dart';
import 'package:endocare/features/auth/domain/repositories/auth_repository.dart';
import 'package:endocare/features/auth/domain/repositories/user_profile_repository.dart';

/// Implementação Firebase Auth integrada ao Firestore (`users/{uid}`) e FCM.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this.firebaseAuth,
    required this.userProfileRepository,
    required this.fcmTokenService,
  });

  final FirebaseAuth firebaseAuth;
  final UserProfileRepository userProfileRepository;
  final FcmTokenService fcmTokenService;

  @override
  Stream<AppAuthUser?> authStateChanges() {
    // `userChanges()` emite em login, logout, updateDisplayName e user.reload()
    // (essencial para detectar confirmação de e-mail em tempo real).
    return firebaseAuth.userChanges().map(_mapUser);
  }

  @override
  AppAuthUser? get currentUser => _mapUser(firebaseAuth.currentUser);

  @override
  Future<AppAuthUser> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    DateTime? birthDate,
  }) async {
    try {
      final trimmedName = name.trim();
      final trimmedEmail = email.trim();

      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthFailure(
          'Não foi possível concluir a criação da conta. Tente novamente.',
        );
      }

      if (trimmedName.isNotEmpty) {
        await firebaseUser.updateDisplayName(trimmedName);
      }

      final fcmToken = await fcmTokenService.registerAndGetTokenSafely();
      final mappedUser = _mapUser(firebaseAuth.currentUser ?? firebaseUser)!
          .copyWith(displayName: trimmedName);

      await userProfileRepository.ensureUserDocument(
        user: mappedUser,
        nameOverride: trimmedName,
        birthDate: birthDate,
        fcmToken: fcmToken,
      );

      if (!firebaseUser.emailVerified) {
        try {
          await firebaseUser.sendEmailVerification();
        } catch (_) {
          // A tela de verificação permite reenviar caso haja falha transitória.
        }
      }

      return mappedUser;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseAuthException(e);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'Ocorreu um erro inesperado ao criar sua conta. Tente novamente.',
      );
    }
  }

  @override
  Future<AppAuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthFailure(
          'Não foi possível iniciar sua sessão. Tente novamente.',
        );
      }

      final mappedUser = _mapUser(firebaseUser)!;
      final fcmToken = await fcmTokenService.registerAndGetTokenSafely();

      await userProfileRepository.ensureUserDocument(
        user: mappedUser,
        fcmToken: fcmToken,
      );

      return mappedUser;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseAuthException(e);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'Não foi possível entrar agora. Verifique sua conexão e tente novamente.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseAuthException(e);
    } catch (_) {
      throw const AuthFailure(
        'Não foi possível enviar o e-mail de recuperação agora.',
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthFailure('Sua sessão expirou. Entre novamente.');
    }
    if (user.emailVerified) return;

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseAuthException(e);
    } catch (_) {
      throw const AuthFailure(
        'Não foi possível reenviar o e-mail de confirmação agora.',
      );
    }
  }

  @override
  Future<AppAuthUser?> reloadCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      await user.reload();
      final refreshed = _mapUser(firebaseAuth.currentUser);
      if (refreshed != null && refreshed.emailVerified) {
        final fcmToken = await fcmTokenService.registerAndGetTokenSafely();
        await userProfileRepository.ensureUserDocument(
          user: refreshed,
          fcmToken: fcmToken,
        );
      }
      return refreshed;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseAuthException(e);
    } catch (_) {
      throw const AuthFailure(
        'Não foi possível verificar o status do e-mail agora. Tente novamente.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    final uid = firebaseAuth.currentUser?.uid;
    final activeToken = fcmTokenService.currentToken;
    if (uid != null && activeToken != null && activeToken.isNotEmpty) {
      await userProfileRepository.removeFcmToken(uid, activeToken);
    }
    await fcmTokenService.unregisterSafely();
    await firebaseAuth.signOut();
  }

  AppAuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppAuthUser(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
      displayName: user.displayName,
    );
  }
}
