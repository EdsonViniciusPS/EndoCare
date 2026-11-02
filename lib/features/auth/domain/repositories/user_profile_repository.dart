import 'package:endocare/features/auth/domain/models/app_auth_user.dart';
import 'package:endocare/features/auth/domain/models/user_profile.dart';

/// Contrato para leitura e manutenção do documento `users/{uid}` no Firestore.
abstract interface class UserProfileRepository {
  /// Observa em tempo real apenas o documento `users/{uid}` da própria usuária.
  Stream<UserProfile?> watchProfile(String uid);

  /// Garante que `users/{uid}` exista com `profile` válido e sincroniza token FCM.
  Future<void> ensureUserDocument({
    required AppAuthUser user,
    String? nameOverride,
    DateTime? birthDate,
    String? fcmToken,
    bool? onboardingCompleted,
  });

  /// Marca o onboarding como concluído em `users/{uid}.profile.preferencias`.
  Future<void> markOnboardingCompleted(String uid);

  /// Registra um token FCM em `users/{uid}.profile.fcmTokens`.
  Future<void> addFcmToken(String uid, String token);

  /// Remove um token FCM de `users/{uid}.profile.fcmTokens` (ex.: no logout).
  Future<void> removeFcmToken(String uid, String token);
}
