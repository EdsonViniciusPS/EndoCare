import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/features/auth/domain/models/user_profile.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/onboarding/data/onboarding_storage.dart';

/// Provider do armazenamento local de onboarding (sobregravável em testes).
final onboardingStorageProvider = Provider<OnboardingStorage>((ref) {
  return SharedPreferencesOnboardingStorage();
});

/// Controlador reativo que sincroniza o status de onboarding entre o dispositivo
/// (`OnboardingStorage`) e `users/{uid}.profile.preferencias.onboardingConcluido`.
class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final completedLocally =
        await ref.watch(onboardingStorageProvider).hasCompletedOnboarding();

    ref.listen<AsyncValue<UserProfile?>>(currentUserProfileProvider, (_, next) {
      final profile = next.asData?.value;
      if (profile == null) return;

      final localValue = state.asData?.value ?? completedLocally;
      if (profile.preferencias.onboardingConcluido && !localValue) {
        unawaited(ref.read(onboardingStorageProvider).setOnboardingCompleted());
        state = const AsyncData(true);
      } else if (!profile.preferencias.onboardingConcluido && localValue) {
        unawaited(
          ref
              .read(userProfileRepositoryProvider)
              .markOnboardingCompleted(profile.uid),
        );
      }
    });

    return completedLocally;
  }

  /// Marca o onboarding como concluído localmente e, se houver usuária autenticada,
  /// também persiste em `users/{uid}.profile.preferencias.onboardingConcluido`.
  Future<void> completeOnboarding() async {
    await ref.read(onboardingStorageProvider).setOnboardingCompleted();
    state = const AsyncData(true);

    final activeUser = ref.read(authStateChangesProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    if (activeUser != null) {
      await ref
          .read(userProfileRepositoryProvider)
          .markOnboardingCompleted(activeUser.uid);
    }
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
