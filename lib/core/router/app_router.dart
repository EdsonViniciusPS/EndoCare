import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/widgets/app_shell_scaffold.dart';
import 'package:endocare/features/auth/domain/models/app_auth_user.dart';
import 'package:endocare/features/auth/domain/models/user_profile.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:endocare/features/auth/presentation/screens/login_screen.dart';
import 'package:endocare/features/auth/presentation/screens/register_screen.dart';
import 'package:endocare/features/auth/presentation/screens/splash_screen.dart';
import 'package:endocare/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:endocare/features/body_map/presentation/screens/body_map_screen.dart';
import 'package:endocare/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:endocare/features/care/presentation/screens/care_screen.dart';
import 'package:endocare/features/home/presentation/screens/home_screen.dart';
import 'package:endocare/features/impact/presentation/screens/impact_screen.dart';
import 'package:endocare/features/more/presentation/screens/more_screen.dart';
import 'package:endocare/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:endocare/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/symptoms/presentation/screens/quick_log_screen.dart';
import 'package:endocare/features/timeline/presentation/screens/timeline_screen.dart';

/// Notificador que reavalia o guard do `GoRouter` quando sessão, perfil ou
/// status de onboarding mudam, sem recriar a instância do roteador.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<AppAuthUser?>>(
      authStateChangesProvider,
      (_, _) => notifyListeners(),
    );
    ref.listen<AsyncValue<bool>>(
      onboardingControllerProvider,
      (_, _) => notifyListeners(),
    );
    ref.listen<AsyncValue<UserProfile?>>(
      currentUserProfileProvider,
      (_, _) => notifyListeners(),
    );
  }
}

/// Provider global do `GoRouter` com guard completo de onboarding, autenticação e verificação.
final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final refreshNotifier = RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateChangesProvider);
      final onboardingAsync = ref.read(onboardingControllerProvider);
      final location = state.matchedLocation;
      final isReplayOnboarding = location == AppRoutes.onboarding &&
          state.uri.queryParameters['rever'] == '1';

      // Aguarda inicialização do estado de autenticação e do onboarding local.
      if ((authAsync.isLoading && !authAsync.hasValue) ||
          (onboardingAsync.isLoading && !onboardingAsync.hasValue)) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final user = authAsync.asData?.value;
      final completedLocally = onboardingAsync.asData?.value ?? false;

      // 1. Não autenticada: primeiro acesso passa pelo Onboarding (3 telas)
      // antes de seguir para Cadastro / Login.
      if (user == null) {
        if (!completedLocally) {
          return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
        }
        if (AppRoutes.publicAuthPaths.contains(location)) {
          return null;
        }
        return AppRoutes.login;
      }

      // 2. Autenticada com e-mail pendente de confirmação.
      if (!user.emailVerified) {
        return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
      }

      // 3. Autenticada e verificada: garante que o primeiro acesso passe pelo
      // Onboarding caso nem o aparelho nem `users/{uid}` o tenham concluído.
      final profileAsync = ref.read(currentUserProfileProvider);
      if (!completedLocally &&
          profileAsync.isLoading &&
          !profileAsync.hasValue) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final completedOnProfile =
          profileAsync.asData?.value?.preferencias.onboardingConcluido ?? false;
      final hasCompletedOnboarding = completedLocally || completedOnProfile;

      if (!hasCompletedOnboarding) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      if (isReplayOnboarding) {
        return null;
      }

      if (location == AppRoutes.splash ||
          location == AppRoutes.verifyEmail ||
          location == AppRoutes.onboarding ||
          AppRoutes.publicAuthPaths.contains(location)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboardingName,
        builder: (context, state) => OnboardingScreen(
          isReplay: state.uri.queryParameters['rever'] == '1',
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: AppRoutes.verifyEmailName,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.bodyMap,
        name: AppRoutes.bodyMapName,
        builder: (context, state) {
          final parsedDate = SymptomLog.tryParseDateKey(
            state.uri.queryParameters['data'],
          );
          final openHeatmap = state.uri.queryParameters['modo'] == 'heatmap';
          return BodyMapScreen(
            initialDate: parsedDate,
            openInHeatmap: openHeatmap,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.impact,
        name: AppRoutes.impactName,
        builder: (context, state) {
          final parsedDate = SymptomLog.tryParseDateKey(
            state.uri.queryParameters['data'],
          );
          return ImpactScreen(initialDate: parsedDate);
        },
      ),
      GoRoute(
        path: AppRoutes.timeline,
        name: AppRoutes.timelineName,
        builder: (context, state) => const TimelineScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                name: AppRoutes.calendarName,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.quickLog,
                name: AppRoutes.quickLogName,
                builder: (context, state) => const QuickLogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.care,
                name: AppRoutes.careName,
                builder: (context, state) => const CareScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                name: AppRoutes.moreName,
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
