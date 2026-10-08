import 'package:flutter/material.dart';

/// A big, colorful emoji drawn with a plain [Text] widget on a soft tinted
/// tile, so the app never needs an image asset for a picture.
///
/// The emoji itself keeps its own system colors; the tile is a very light
/// wash of [color] so bright emoji (yellow stars, green apples) still pop.
class EmojiPicture extends StatelessWidget {
  const EmojiPicture({
    super.key,
    required this.emoji,
    this.color,
    this.fontSize = 64,
    this.tint = true,
  });

  /// The emoji character(s) to show, e.g. `"🍎"`.
  final String emoji;

  /// Tile color; when null only the emoji is painted.
  final Color? color;

  /// Font size used before the glyph is scaled down to fit.
  final double fontSize;

  /// Whether to paint the soft tinted background tile.
  final bool tint;

  @override
  Widget build(BuildContext context) {
    final Widget glyph = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.1,
          shadows: <Shadow>[
            Shadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );

    if (!tint || color == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(4), child: glyph));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.80)!,
            Color.lerp(color, Colors.white, 0.93)!,
          ],
        ),
      ),
      child: Center(child: Padding(padding: const EdgeInsets.all(4), child: glyph)),
    );
  }
}
