import 'package:flutter/material.dart';

import '../../../../core/motion/app_motion.dart';
import '../../../../core/theme/app_colors.dart';

/// A single stop on a world's winding path: a chunky circle with the level
/// number (or a lock), up to three stars underneath, and a motion cue —
/// the current level gently pulses, locked levels wobble.
class LevelNode extends StatelessWidget {
  const LevelNode({
    super.key,
    required this.level,
    required this.color,
    required this.stars,
    required this.locked,
    required this.onTap,
    required this.isCurrent,
  });

  final int level;

  /// Face color of an unlocked, not-yet-completed level.
  final Color color;

  /// Stars already earned (0-3).
  final int stars;
  final bool locked;
  final VoidCallback? onTap;

  /// The next level to play - it gently pulses to invite a tap.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final bool done = stars > 0;
    final Color face = locked
        ? const Color(0xFFE2E8F0)
        : done
            ? AppColors.gold
            : color;
    final Color ink = locked
        ? const Color(0xFF94A3B8)
        : done
            ? const Color(0xFF7C2D12)
            : Colors.white;

    final Widget node = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 68,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: face,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: locked
              ? Icon(Icons.lock_rounded, color: ink, size: 28)
              : Text(
                  '$level',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    color: ink,
                    height: 1,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int i) {
            return Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 15,
              color: i < stars
                  ? AppColors.gold
                  : Colors.white.withValues(alpha: 0.7),
            );
          }),
        ),
      ],
    );

    // The current level breathes; a locked level gives a light wobble; a
    // finished or plain level stays still.
    final Widget animated = locked
        ? AppMotion(style: MotionPresets.locked, child: node)
        : isCurrent
            ? AppMotion(
                key: ValueKey<String>('level-pulse-$level'),
                style: MotionPresets.attention,
                child: node,
              )
            : node;

    return Semantics(
      button: true,
      label: locked ? 'Level $level, locked' : 'Level $level',
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: animated,
      ),
    );
  }
}
