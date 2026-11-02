import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:endocare/features/auth/domain/models/app_auth_user.dart';
import 'package:endocare/features/auth/domain/models/user_profile.dart';
import 'package:endocare/features/auth/domain/repositories/user_profile_repository.dart';

/// Implementação Firestore de `UserProfileRepository` escopada em `users/{uid}`.
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return UserProfile.fromFirestore(data, uid: snapshot.id);
    });
  }

  @override
  Future<void> ensureUserDocument({
    required AppAuthUser user,
    String? nameOverride,
    DateTime? birthDate,
    String? fcmToken,
    bool? onboardingCompleted,
  }) async {
    final docRef = _userDoc(user.uid);
    final snapshot = await docRef.get();

    final resolvedName = _resolveName(
      nameOverride: nameOverride,
      displayName: user.displayName,
      email: user.email,
    );

    if (!snapshot.exists) {
      final profile = UserProfile(
        uid: user.uid,
        email: user.email,
        nome: resolvedName,
        nascimento: birthDate,
        preferencias: UserPreferences(
          onboardingConcluido: onboardingCompleted ?? false,
        ),
        fcmTokens: fcmToken != null && fcmToken.isNotEmpty
            ? [fcmToken]
            : const [],
      );
      await docRef.set(profile.toCreateMap());
      return;
    }

    final updates = <String, Object?>{
      'email': user.email,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    if (nameOverride != null && nameOverride.trim().isNotEmpty) {
      updates['profile.nome'] = nameOverride.trim();
    }
    if (birthDate != null) {
      updates['profile.nascimento'] = Timestamp.fromDate(birthDate);
    }
    if (fcmToken != null && fcmToken.isNotEmpty) {
      updates['profile.fcmTokens'] = FieldValue.arrayUnion([fcmToken]);
    }
    if (onboardingCompleted == true) {
      updates['profile.preferencias.onboardingConcluido'] = true;
    }

    await docRef.update(updates);
  }

  @override
  Future<void> markOnboardingCompleted(String uid) async {
    try {
      await _userDoc(uid).update({
        'profile.preferencias.onboardingConcluido': true,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silencioso caso esteja offline sem cache inicial do documento.
    }
  }

  @override
  Future<void> addFcmToken(String uid, String token) async {
    if (token.isEmpty) return;
    try {
      await _userDoc(uid).update({
        'profile.fcmTokens': FieldValue.arrayUnion([token]),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silencioso caso o documento ainda esteja sendo provisionado.
    }
  }

  @override
  Future<void> removeFcmToken(String uid, String token) async {
    if (token.isEmpty) return;
    try {
      await _userDoc(uid).update({
        'profile.fcmTokens': FieldValue.arrayRemove([token]),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Não deve impedir o logout da usuária caso esteja offline.
    }
  }

  String _resolveName({
    required String? nameOverride,
    required String? displayName,
    required String email,
  }) {
    if (nameOverride != null && nameOverride.trim().isNotEmpty) {
      return nameOverride.trim();
    }
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final localPart = email.split('@').first.trim();
    if (localPart.isNotEmpty) {
      return localPart;
    }
    return 'Usuária';
  }
}
