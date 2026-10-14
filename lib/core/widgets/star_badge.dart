import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// Compact pill showing how many stars a child has collected.
class StarBadge extends StatelessWidget {
  const StarBadge({super.key, required this.count, this.compact = false});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Re-key on the count so the star gives a little bounce whenever it grows.
    return AppMotion(
      key: ValueKey<String>('star-badge-$count'),
      style: MotionPresets.rewardStar,
      child: _pill(context),
    );
  }

  Widget _pill(BuildContext context) {
    return Container(
      height: compact ? 34 : 40,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTokens.space2 : AppTokens.space3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '⭐',
            style: TextStyle(fontSize: compact ? 16 : 20),
          ),
          const SizedBox(width: AppTokens.space1),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w700,
              fontVariations: const <FontVariation>[FontVariation('wght', 700)],
              color: const Color(0xFFB45309),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small flame pill showing the daily play streak.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, this.compact = false});

  final int days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // The flame keeps a gentle heartbeat while a streak is alive.
    if (days > 0) {
      return AppMotion(
        style: MotionPresets.rewardStreak,
        child: _pill(),
      );
    }
    return _pill();
  }

  Widget _pill() {
    return Container(
      height: compact ? 34 : 40,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTokens.space2 : AppTokens.space3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDE4),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: AppColors.accentOrange, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('🔥', style: TextStyle(fontSize: compact ? 16 : 20)),
          const SizedBox(width: AppTokens.space1),
          Text(
            '$days',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w700,
              fontVariations: const <FontVariation>[FontVariation('wght', 700)],
              color: const Color(0xFFC2410C),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Up to three stars awarded at the end of a level, animating in one by one.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.earned,
    this.size = 34,
    this.animate = false,
  });

  /// How many of the three stars are filled (0-3).
  final int earned;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int index) {
        final bool filled = index < earned;
        Widget star = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? AppColors.gold : const Color(0xFFCBD5E1),
          shadows: filled
              ? const <Shadow>[
                  Shadow(color: Color(0xFFF59E0B), blurRadius: 8),
                ]
              : null,
        );
        if (animate && filled) {
          star = AppMotion(
            key: ValueKey<String>('rating-star-$earned-$index'),
            style: MotionPresets.rewardStar,
            delay: Duration(milliseconds: index * 180),
            child: star,
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.12),
          child: star,
        );
      }),
    );
  }
}
