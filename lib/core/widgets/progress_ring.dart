import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// Circular progress indicator with a value/label in the middle - used for
/// "0 of 26 letters explored" style stats and per-letter mastery rings.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 72,
    this.stroke = 8,
    this.color = AppColors.primary,
    this.trackColor = const Color(0xFFE2E8F0),
  });

  /// 0.0 - 1.0 (clamped).
  final double progress;
  final Widget child;
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final double value = progress.clamp(0.0, 1.0);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: AppTokens.springDuration,
              curve: AppTokens.easeOutCubic,
              builder: (BuildContext context, double animated, Widget? _) {
                return CustomPaint(
                  painter: _RingPainter(
                    progress: animated,
                    stroke: stroke,
                    color: color,
                    trackColor: trackColor,
                  ),
                );
              },
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.stroke,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double stroke;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - stroke) / 2;
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final Paint fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // top of the circle
      6.2832 * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.stroke != stroke ||
      oldDelegate.trackColor != trackColor;
}
