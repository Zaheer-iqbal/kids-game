import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'star_badge.dart';

/// The one header every screen shares: back/home affordance, screen title,
/// star + streak counters and the grown-up settings shortcut.
///
/// Counters are passed in so the widget stays pure and testable.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.showHome = false,
    this.showSettings = true,
    this.stars,
    this.streak,
    this.actions = const <Widget>[],
    this.elevated = true,
  });

  final String title;
  final VoidCallback? onBack;

  /// Replaces the back arrow with a home button (top level screens).
  final bool showHome;

  /// Hidden on the tab that already shows the settings content.
  final bool showSettings;

  /// Total stars; hidden when null.
  final int? stars;

  /// Daily streak; hidden when null.
  final int? streak;
  final List<Widget> actions;
  final bool elevated;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bool canPop = onBack != null || context.canPop();

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: AppTokens.space2,
      title: Row(
        children: <Widget>[
          if (showHome)
            _BarIcon(
              icon: Icons.home_rounded,
              tooltip: 'Home',
              onTap: () => context.go(AppRoutes.home),
            )
          else if (canPop)
            _BarIcon(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: onBack ?? () => context.pop(),
            ),
          if (canPop || showHome) const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (stars != null) ...<Widget>[
            StarBadge(count: stars!, compact: true),
            const SizedBox(width: AppTokens.space2),
          ],
          if (streak != null && streak! > 0) ...<Widget>[
            StreakBadge(days: streak!, compact: true),
            const SizedBox(width: AppTokens.space2),
          ],
          ...actions,
          if (showSettings)
            _BarIcon(
              icon: Icons.tune_rounded,
              tooltip: 'Grown-up settings',
              onTap: () => context.push(AppRoutes.settings),
            ),
        ],
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: AppTokens.minTapTarget - 8,
            child: Icon(icon, size: 24, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
