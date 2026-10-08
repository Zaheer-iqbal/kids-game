import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/emoji_picture.dart';
import '../../../../core/widgets/tap_delight.dart';
import '../../domain/entities/letter_item.dart';

/// Big, colorful, rounded tap target for one letter in the grid: the letter up
/// front, its emoji picture and the word underneath.
///
/// [TapDelight] adds the pop, the little random tilt and the occasional
/// sparkle burst around it.
class LetterCard extends StatelessWidget {
  const LetterCard({
    super.key,
    required this.letter,
    required this.explored,
    required this.onTap,
  });

  final LetterItem letter;
  final bool explored;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(letter.colorValue);
    final ThemeData theme = Theme.of(context);

    return TapDelight(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[color, Color.lerp(color, Colors.white, 0.15)!],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: explored ? AppColors.gold : Colors.white.withValues(alpha: 0.75),
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
            Center(
              child: Text(
                letter.letter,
                style: theme.textTheme.displayMedium?.copyWith(
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
              right: 6,
              bottom: 22,
              child: IgnorePointer(
                child: EmojiPicture(
                  emoji: letter.emoji,
                  fontSize: 26,
                  tint: false,
                ),
              ),
            ),
            Positioned(
              left: 4,
              right: 4,
              bottom: 9,
              child: Text(
                letter.word,
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