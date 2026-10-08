import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/emoji_picture.dart';
import '../../../../core/widgets/tap_delight.dart';
import '../../domain/entities/number_entity.dart';

/// Big, colorful, rounded tap target for one number in the grid: numeral up
/// front, a fun emoji and the word underneath.
///
/// [TapDelight] adds the pop, the little random tilt and the occasional
/// sparkle burst around it.
class NumberCard extends StatelessWidget {
  const NumberCard({
    super.key,
    required this.number,
    required this.explored,
    required this.onTap,
  });

  final NumberEntity number;
  final bool explored;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(number.colorValue);
    final ThemeData theme = Theme.of(context);

    return TapDelight(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[color, Color.lerp(color, Colors.white, 0.13)!],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: explored
                ? AppColors.gold
                : Colors.white.withValues(alpha: 0.75),
            width: explored ? 4 : 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              top: 5,
              right: 5,
              child: IgnorePointer(
                child: EmojiPicture(
                  emoji: number.emoji,
                  fontSize: 22,
                  tint: false,
                ),
              ),
            ),
            Center(
              child: Text(
                '${number.number}',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: <Shadow>[
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 4,
              right: 4,
              bottom: 9,
              child: Text(
                number.word,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (explored)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}