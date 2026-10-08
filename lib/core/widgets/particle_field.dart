import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'delight_settings.dart';

/// Code-drawn particle burst: confetti pieces, sparkles and stars fly out of
/// [origin] under gravity, spin, and fade. Pure `CustomPainter` - no particle
/// package, no images.
///
/// Fire-and-forget: starts when built, disposes its own controller.
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.origin,
    this.count = 60,
    this.colors = const <Color>[
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFFFB7185),
      Color(0xFF34D399),
      Color(0xFFA78BFA),
      Color(0xFFFBBF24),
    ],
    this.mode = ParticleBurstMode.confetti,
    this.duration = const Duration(milliseconds: 1400),
    this.spread = 1,
  });

  final Offset origin;
  final int count;
  final List<Color> colors;
  final ParticleBurstMode mode;
  final Duration duration;

  /// 1 = normal spread, 2 = twice as wide (full-screen celebrations).
  final double spread;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

enum ParticleBurstMode { confetti, sparkle, stars }

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!DelightSettings.of(context).sparklesEnabled) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _BurstPainter(
              progress: _controller.value,
              origin: widget.origin,
              count: widget.count,
              colors: widget.colors,
              mode: widget.mode,
              spread: widget.spread,
            ),
          );
        },
      ),
    );
  }
}

/// Continuous ambient sparkle field (used behind level-complete screens).
/// Rebuilds itself for [lifetime] then stops.
class SparkleField extends StatefulWidget {
  const SparkleField({
    super.key,
    this.count = 24,
    this.colors = const <Color>[Color(0xFFFBBF24), Color(0xFFFFFFFF)],
    this.lifetime = const Duration(milliseconds: 2200),
  });

  final int count;
  final List<Color> colors;
  final Duration lifetime;

  @override
  State<SparkleField> createState() => _SparkleFieldState();
}

class _SparkleFieldState extends State<SparkleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.lifetime,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!DelightSettings.of(context).sparklesEnabled) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _BurstPainter(
              progress: _controller.value,
              origin: null, // ambient mode: spread across the whole area
              count: widget.count,
              colors: widget.colors,
              mode: ParticleBurstMode.sparkle,
              spread: 1,
            ),
          );
        },
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required this.origin,
    required this.count,
    required this.colors,
    required this.mode,
    required this.spread,
  });

  final double progress;
  final Offset? origin;
  final int count;
  final List<Color> colors;
  final ParticleBurstMode mode;
  final double spread;

  // Fixed seeds: every paint of the same frame looks identical.
  static final math.Random _rng = math.Random(7);
  late final List<double> _angle =
      List<double>.generate(count, (_) => _rng.nextDouble());
  late final List<double> _speed =
      List<double>.generate(count, (_) => _rng.nextDouble());
  late final List<double> _spin =
      List<double>.generate(count, (_) => _rng.nextDouble());
  late final List<double> _size =
      List<double>.generate(count, (_) => _rng.nextDouble());

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final Offset start = origin ?? Offset(size.width / 2, size.height / 2);
    final double t = progress;
    final double fade = (1 - t).clamp(0.0, 1.0);
    final double gravity = size.height * 1.15;

    for (int i = 0; i < count; i++) {
      final double angle = _angle[i] * math.pi * 2;
      final double velocity = (60 + _speed[i] * 320) * spread;
      final double elapsed = t * 1.4;

      final double dx = math.cos(angle) * velocity * elapsed;
      final double dy = math.sin(angle) * velocity * elapsed +
          gravity * elapsed * elapsed * 0.45;

      // Ambient sparkles drift in place instead of exploding.
      final Offset position = origin == null
          ? Offset(
              (_angle[i] * size.width + _speed[i] * 40 * math.sin(t * 6)) %
                  size.width,
              ((_spin[i] * size.height) + t * 60 * (0.4 + _size[i])) %
                  size.height,
            )
          : start + Offset(dx, dy);

      if (position.dx < -20 ||
          position.dx > size.width + 20 ||
          position.dy > size.height + 20) {
        continue;
      }

      final Color color =
          colors[i % colors.length].withValues(alpha: fade);
      final double base = 6 + _size[i] * 10;
      final double angleNow = _spin[i] * math.pi * 2 * (1 + t * 3);

      switch (mode) {
        case ParticleBurstMode.confetti:
          _drawConfetti(canvas, position, base, angleNow, color);
        case ParticleBurstMode.sparkle:
          _drawStar(canvas, position, base * 0.7, color, filled: true);
        case ParticleBurstMode.stars:
          _drawStar(canvas, position, base, color, filled: true);
      }
    }
  }

  void _drawConfetti(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Color color,
  ) {
    final Paint paint = Paint()..color = color;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final RRect piece = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.6),
      Radius.circular(2),
    );
    canvas.drawRRect(piece, paint);
    canvas.restore();
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    required bool filled,
  }) {
    final Path path = Path();
    const int points = 4;
    for (int p = 0; p < points * 2; p++) {
      final double r = p.isEven ? radius : radius * 0.38;
      final double a = p * math.pi / points - math.pi / 2;
      final Offset point = Offset(
        center.dx + math.cos(a) * r,
        center.dy + math.sin(a) * r,
      );
      if (p == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Convenience: a full-size overlay that shows [child] with a one-shot burst
/// on top. Used on celebration moments.
class BurstOverlay extends StatelessWidget {
  const BurstOverlay({
    super.key,
    required this.progress,
    this.mode = ParticleBurstMode.confetti,
    this.spread = 1.4,
  });

  final double progress;
  final ParticleBurstMode mode;
  final double spread;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BurstPainter(
          progress: progress,
          origin: null,
          count: 90,
          colors: const <Color>[
            Color(0xFF3B82F6),
            Color(0xFFF59E0B),
            Color(0xFFFB7185),
            Color(0xFF34D399),
            Color(0xFFA78BFA),
          ],
          mode: mode,
          spread: spread,
        ),
      ),
    );
  }
}
