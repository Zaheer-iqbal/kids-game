import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A round "sticker" holding a single emoji: white ring, soft drop shadow and
/// an optional tinted background. Emoji always render with a color-emoji font
/// fallback so they look identical on every device.
class EmojiSticker extends StatelessWidget {
  const EmojiSticker({
    super.key,
    required this.emoji,
    this.size = 72,
    this.background,
    this.ring = true,
    this.shadow = true,
  });

  final String emoji;
  final double size;

  /// Defaults to a soft white disc.
  final Color? background;
  final bool ring;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: ring
            ? Border.all(color: Colors.white, width: size * 0.045)
            : null,
        boxShadow: shadow
            ? <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: size * 0.56,
          height: 1,
          fontFamilyFallback: const <String>[
            'Noto Color Emoji',
            'Apple Color Emoji',
            'Segoe UI Emoji',
          ],
        ),
      ),
    );
  }
}

/// The large picture shown on lesson/meet screens: sticker + gentle float.
class EmojiHero extends StatelessWidget {
  const EmojiHero({
    super.key,
    required this.emoji,
    this.size = 168,
    this.animate = true,
    this.color = AppColors.primary,
  });

  final String emoji;
  final double size;
  final bool animate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Widget sticker = EmojiSticker(
      emoji: emoji,
      size: size,
      background: Colors.white,
    );
    if (!animate) return sticker;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: sticker,
    );
  }
}
