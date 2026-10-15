import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// One destination in the floating pill navigation.
class NavBarDestination {
  const NavBarDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String value;
}

/// The floating pill bottom navigation used by the home shell: chunky,
/// rounded, always reachable by thumb, with a bouncing active pill.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
  });

  final List<NavBarDestination> destinations;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          0,
          AppTokens.space4,
          AppTokens.space3,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space2,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: destinations.map((NavBarDestination destination) {
              final bool isActive = destination.value == selected;
              return Expanded(
                child: _NavBarItem(
                  destination: destination,
                  active: isActive,
                  onTap: () {
                    HapticFeedback.selectionClick().catchError((Object _) {});
                    onSelect(destination.value);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final NavBarDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF5C6BC0);
    const Color inactiveColor = Color(0xFF718096);
    final Color textColor = active ? activeColor : inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.pressDuration,
        curve: AppTokens.easeOutCubic,
        height: 56,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: AppTokens.pressDuration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFE8EAF6) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                active ? destination.selectedIcon : destination.icon,
                size: 24,
                color: active ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontVariations: <FontVariation>[
                  FontVariation('wght', active ? 800 : 600),
                ],
                color: textColor,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
