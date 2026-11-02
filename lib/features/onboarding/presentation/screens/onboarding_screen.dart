import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:endocare/core/router/app_routes.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/core/widgets/endocare_card.dart';
import 'package:endocare/core/widgets/endocare_logo.dart';
import 'package:endocare/core/widgets/storyset_illustration.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/onboarding/domain/models/onboarding_slide_data.dart';
import 'package:endocare/features/onboarding/presentation/providers/onboarding_providers.dart';

/// Fluxo de Onboarding em 3 telas com ilustrações Storyset de paletas distintas
/// e animações suaves com `flutter_animate`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.isReplay = false,
  });

  /// Quando `true`, foi aberto manualmente (ex.: "Rever boas-vindas" na aba Mais).
  final bool isReplay;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  late final List<OnboardingSlideData> _slides = OnboardingSlideData.slides;

  int _currentIndex = 0;
  bool _isFinishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finishToDestination(String destinationPath) async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding();
      if (!mounted) return;
      context.go(destinationPath);
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentSlide = _slides[_currentIndex];
    final isLastSlide = _currentIndex == _slides.length - 1;

    final authUser = ref.watch(authStateChangesProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;
    final isAuthenticated = authUser != null;

    final skipDestination = isAuthenticated ? AppRoutes.home : AppRoutes.login;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  // Cabeçalho com logo horizontal e botão Pular/Fechar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const EndoCareLogo(
                        variant: EndoCareLogoVariant.horizontal,
                        height: 40,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                      ),
                      if (widget.isReplay)
                        TextButton.icon(
                          onPressed: _isFinishing
                              ? null
                              : () => context.go(AppRoutes.home),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Fechar'),
                        )
                      else if (!isLastSlide)
                        TextButton(
                          onPressed: _isFinishing
                              ? null
                              : () => _finishToDestination(skipDestination),
                          child: const Text('Pular'),
                        )
                      else
                        const SizedBox(width: 64),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Carrossel das 3 telas com paletas distintas
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return _OnboardingSlideView(
                          key: ValueKey('onboarding_slide_$index'),
                          slide: slide,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Indicadores animados de página
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 28 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? currentSlide.accentColor
                              : AppColors.outlineStrong.withValues(alpha: 0.6),
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Rodapé com botões de avanço / conclusão
                  if (!isLastSlide)
                    EndoCareButton(
                      label: 'Continuar',
                      trailingIcon: Icons.arrow_forward_rounded,
                      isExpanded: true,
                      onPressed: _isFinishing ? null : _nextSlide,
                    )
                  else if (isAuthenticated)
                    EndoCareButton(
                      label: widget.isReplay
                          ? 'Voltar ao Início'
                          : 'Começar no EndoCare',
                      icon: Icons.favorite_rounded,
                      isLoading: _isFinishing,
                      isExpanded: true,
                      onPressed: () => _finishToDestination(AppRoutes.home),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EndoCareButton(
                          label: 'Criar minha conta',
                          trailingIcon: Icons.arrow_forward_rounded,
                          isLoading: _isFinishing,
                          isExpanded: true,
                          onPressed: () =>
                              _finishToDestination(AppRoutes.register),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        EndoCareButton(
                          label: 'Já tenho conta • Entrar',
                          variant: EndoCareButtonVariant.outlined,
                          isExpanded: true,
                          onPressed: _isFinishing
                              ? null
                              : () => _finishToDestination(AppRoutes.login),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Passo ${_currentIndex + 1} de ${_slides.length}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({
    super.key,
    required this.slide,
  });

  final OnboardingSlideData slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: EndoCareCard(
          elevated: true,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Halo colorido suave harmonizado com a paleta do Storyset da tela
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: slide.haloColor.withValues(alpha: 0.7),
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: StorysetIllustration(
                  asset: slide.illustration,
                  height: 195,
                ),
              )
                  .animate()
                  .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                    duration: 420.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: AppSpacing.lg),

              // Badge temático
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xxs + 2,
                ),
                decoration: BoxDecoration(
                  color: slide.haloColor,
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
                child: Text(
                  slide.badge,
                  style: textTheme.labelSmall?.copyWith(
                    color: slide.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 90.ms, duration: 320.ms)
                  .slideY(begin: 0.18, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.md),

              // Título principal
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge,
              )
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 360.ms)
                  .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.sm),

              // Descrição acolhedora
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 380.ms)
                  .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      ),
    );
  }
}

