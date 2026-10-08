import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'sparkle_paint.dart';

/// A short burst of hand-drawn sparkles, used on letter and number cards.
///
/// The whole burst lives in one [CustomPainter] that listens to the animation
/// directly, so a running burst repaints a single layer and never rebuilds a
/// widget. The layer is wrapped in a [RepaintBoundary], which keeps a burst on
/// one card from repainting its neighbours in a grid.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({
    super.key,
    required this.seed,
    this.colors = const <Color>[
      AppColors.gold,
      Color(0xFFFF9A3B),
      AppColors.quiz,
      Color(0xFF8FD694),
      Color(0xFF8F95F0),
    ],
    this.particles = 12,
  });

  /// Changing the seed replays the burst with a fresh random layout.
  final int seed;

  final List<Color> colors;
  final int particles;

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  @override
  void initState() {
    super.initState();
    // The card already decided the animations are on when it spawned a burst.
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(SparkleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _SparkleBurstPainter(
            animation: _controller,
            seed: widget.seed,
            colors: widget.colors,
            particleCount: widget.particles,
          ),
        ),
      ),
    );
  }
}

class _SparkleBurstPainter extends CustomPainter {
  _SparkleBurstPainter({
    required this.animation,
    required this.seed,
    required this.colors,
    required this.particleCount,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final int seed;
  final List<Color> colors;
  final int particleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = animation.value;
    if (t >= 1) return;

    final Offset center = size.center(Offset.zero);
    final double reach = math.min(size.width, size.height) * 0.55;
    final math.Random random = math.Random(seed);

    final Paint paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < particleCount; i++) {
      final double angle = sparkleAngle(random);
      final double speed = 0.55 + random.nextDouble() * 0.75;
      final double sizeFactor = 0.35 + random.nextDouble() * 0.65;
      final Color color = colors[random.nextInt(colors.length)];
      final bool isDot = random.nextDouble() < 0.35;
      // Slight delay per particle turns the burst into a sprinkle.
      final double delay = random.nextDouble() * 0.25;
      final double local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final double distance = speed * reach * Curves.easeOutCubic.transform(local);
      final Offset position = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy +
            math.sin(angle) * distance +
            // A little gravity so the sparkles rain down as they fade.
            0.45 * reach * local * local,
      );

      // Quick fade in, long fade out.
      final double fadeIn = (local / 0.18).clamp(0.0, 1.0);
      final double fadeOut = 1 - Curves.easeInCubic.transform(local);
      final double opacity = (fadeIn * fadeOut).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final double radius =
          math.max(2.0, reach * 0.12 * sizeFactor * (1 - 0.45 * local));
      paint.color = color.withValues(alpha: opacity);

      if (isDot) {
        paintDot(canvas, position, radius * 0.55, paint);
      } else {
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(angle);
        paintSparkle(canvas, Offset.zero, radius, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleBurstPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.colors != colors ||
        oldDelegate.particleCount != particleCount;
  }
}
