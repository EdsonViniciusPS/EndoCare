import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/firebase/fcm_token_service.dart';
import 'package:endocare/core/firebase/firebase_providers.dart';
import 'package:endocare/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:endocare/features/auth/data/repositories/firestore_user_profile_repository.dart';
import 'package:endocare/features/auth/domain/models/app_auth_user.dart';
import 'package:endocare/features/auth/domain/models/user_profile.dart';
import 'package:endocare/features/auth/domain/repositories/auth_repository.dart';
import 'package:endocare/features/auth/domain/repositories/user_profile_repository.dart';

/// Provider do serviço seguro de tokens FCM.
final fcmTokenServiceProvider = Provider<FcmTokenService>((ref) {
  final service = FcmTokenService(ref.watch(firebaseMessagingProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Provider do repositório do perfil da usuária (`users/{uid}`).
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirestoreUserProfileRepository(ref.watch(firestoreProvider));
});

/// Provider do repositório de autenticação (sobregravável em testes de widget).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final fcmService = ref.watch(fcmTokenServiceProvider);
  final profileRepo = ref.watch(userProfileRepositoryProvider);

  final repo = FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    userProfileRepository: profileRepo,
    fcmTokenService: fcmService,
  );

  // Mantém tokens FCM emitidos/renovados sincronizados com `users/{uid}`.
  final subscription = fcmService.onRegistered.listen((newToken) {
    final activeUid = repo.currentUser?.uid;
    if (activeUid != null) {
      unawaited(profileRepo.addFcmToken(activeUid, newToken));
    }
  });
  ref.onDispose(subscription.cancel);

  return repo;
});

/// Stream global da sessão autenticada (`AppAuthUser?`).
final authStateChangesProvider = StreamProvider<AppAuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Perfil em tempo real da usuária autenticada (`users/{uid}`).
/// Só consulta o documento do próprio `uid` autenticado.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream<UserProfile?>.value(null);
  }
  return ref.watch(userProfileRepositoryProvider).watchProfile(authUser.uid);
});
