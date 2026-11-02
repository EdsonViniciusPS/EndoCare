import 'package:shared_preferences/shared_preferences.dart';

/// Contrato de persistência local do status de onboarding neste dispositivo.
abstract interface class OnboardingStorage {
  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingCompleted();
}

/// Implementação persistente via `SharedPreferences`.
class SharedPreferencesOnboardingStorage implements OnboardingStorage {
  static const String _key = 'endocare.onboarding_completed';

  @override
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

