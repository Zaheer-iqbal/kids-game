import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The number of objects drawn by [CountObjects]. Anything above this is
/// clamped so a hundred is always the worst case a child has to look at.
const int kMaxCountedObjects = 100;

/// Draws [count] copies of [emoji] as counting frames (ten-frames: two rows of
/// five), which is how children learn to read big numbers.
///
/// The emoji shrink as the number grows, and the whole block scrolls once it
/// no longer fits, so one hundred objects stay on screen without overflowing.
class CountObjects extends StatelessWidget {
  const CountObjects({
    super.key,
    required this.count,
    required this.emoji,
    required this.color,
    this.maxHeight = 190,
  });

  /// How many objects to draw, clamped to `0..100`.
  final int count;

  /// The repeated object, e.g. `"🍎"`.
  final String emoji;

  /// Frame accent color.
  final Color color;

  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final int total = count.clamp(0, kMaxCountedObjects);
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final int frameCount = (total / 10).ceil();
    // Bigger numbers get smaller frames so ten of them still fit on screen.
    final double cell = (36.0 - (frameCount - 1) * 0.7).clamp(11.0, 36.0);
    final double fontSize = (cell * 0.82).clamp(9.0, 30.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (int frame = 0; frame < frameCount; frame++)
                _TenFrame(
                  index: frame,
                  filled: math.min(10, total - frame * 10),
                  emoji: emoji,
                  color: color,
                  cell: cell,
                  fontSize: fontSize,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One ten-frame: a 2 x 5 grid where the first [filled] slots hold the object.
class _TenFrame extends StatelessWidget {
  const _TenFrame({
    required this.index,
    required this.filled,
    required this.emoji,
    required this.color,
    required this.cell,
    required this.fontSize,
  });

  final int index;
  final int filled;
  final String emoji;
  final Color color;
  final double cell;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final Color accent = index.isEven ? color : Color.lerp(color, Colors.white, 0.35)!;

    return Container(
      padding: EdgeInsets.all(cell * 0.14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cell * 0.6),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int row = 0; row < 2; row++)
            Padding(
              padding: EdgeInsets.only(bottom: row == 0 ? cell * 0.12 : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int column = 0; column < 5; column++)
                    Padding(
                      padding:
                          EdgeInsets.only(right: column == 4 ? 0 : cell * 0.12),
                      child: _Slot(
                        filled: row * 5 + column < filled,
                        emoji: emoji,
                        accent: accent,
                        cell: cell,
                        fontSize: fontSize,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.filled,
    required this.emoji,
    required this.accent,
    required this.cell,
    required this.fontSize,
  });

  final bool filled;
  final String emoji;
  final Color accent;
  final double cell;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cell,
      height: cell,
      child: filled
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(emoji, style: TextStyle(fontSize: fontSize)),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(cell * 0.3),
                border: Border.all(
                  color: accent.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
            ),
    );
  }
}
