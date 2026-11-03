import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_logo.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/auth/presentation/widgets/sign_out_dialog.dart';

/// Estrutura principal com cabeçalho compacto e navegação inferior de 5 abas
/// (Início, Calendário, botão central Registrar, Cuidar e Mais).
class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onSelectTab(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: false,
        titleSpacing: AppSpacing.sm,
        toolbarHeight: 62,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.outline.withValues(alpha: 0.65),
          ),
        ),
        title: const EndoCareLogo(
          variant: EndoCareLogoVariant.horizontal,
          height: 44,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(
              Icons.logout_rounded,
              size: 22,
              color: AppColors.textSecondary,
            ),
            onPressed: () => confirmAndSignOut(context, ref),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.outline.withValues(alpha: 0.75),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 74,
            child: Row(
              children: [
                Expanded(
                  child: _BottomNavItem(
                    label: 'Início',
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    selected: currentIndex == 0,
                    onTap: () => _onSelectTab(0),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Calendário',
                    icon: Icons.calendar_month_outlined,
                    selectedIcon: Icons.calendar_month_rounded,
                    selected: currentIndex == 1,
                    onTap: () => _onSelectTab(1),
                  ),
                ),
                Expanded(
                  child: _CenterRegisterNavItem(
                    label: 'Registrar',
                    selected: currentIndex == 2,
                    onTap: () => _onSelectTab(2),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Cuidar',
                    icon: Icons.favorite_border_rounded,
                    selectedIcon: Icons.favorite_rounded,
                    selected: currentIndex == 3,
                    onTap: () => _onSelectTab(3),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    label: 'Mais',
                    icon: Icons.grid_view_outlined,
                    selectedIcon: Icons.grid_view_rounded,
                    selected: currentIndex == 4,
                    onTap: () => _onSelectTab(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xxs + 1,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryContainer
                    : Colors.transparent,
                borderRadius: AppSpacing.borderRadiusPill,
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterRegisterNavItem extends StatelessWidget {
  const _CenterRegisterNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selected
                      ? const [AppColors.primaryDark, AppColors.primary]
                      : const [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
