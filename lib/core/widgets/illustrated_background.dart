import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The code-drawn "world" behind every screen: an indigo night sky with
/// twinkling stars, drifting clouds and layered rolling hills. No images.
///
/// Pass [scrollOffset] to parallax the sky against scrolling content, or
/// leave it null for a still backdrop (tests, print-style renders).
class IllustratedBackground extends StatelessWidget {
  const IllustratedBackground({
    super.key,
    this.scrollOffset,
    this.hills = true,
    this.clouds = true,
    this.stars = true,
  });

  final ValueListenable<double>? scrollOffset;
  final bool hills;
  final bool clouds;
  final bool stars;

  @override
  Widget build(BuildContext context) {
    if (scrollOffset == null) {
      return RepaintBoundary(child: _buildCanvas(0));
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: scrollOffset!,
        builder: (BuildContext context, Widget? child) =>
            _buildCanvas(scrollOffset!.value),
      ),
    );
  }

  Widget _buildCanvas(double parallax) {
    return CustomPaint(
      painter: _WorldPainter(
        parallax: parallax,
        showHills: hills,
        showClouds: clouds,
        showStars: stars,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _WorldPainter extends CustomPainter {
  _WorldPainter({
    required this.parallax,
    required this.showHills,
    required this.showClouds,
    required this.showStars,
  });

  final double parallax;
  final bool showHills;
  final bool showClouds;
  final bool showStars;

  // Deterministic "randomness" so the scenery never flickers between paints.
  static final math.Random _rng = math.Random(20261008);
  static final List<Offset> _starSeeds = List<Offset>.generate(
    70,
    (int i) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final List<double> _starTwinkle = List<double>.generate(
    70,
    (int i) => _rng.nextDouble(),
  );
  static final List<_Cloud> _clouds = List<_Cloud>.generate(
    6,
    (int i) => _Cloud(
      seed: Offset(_rng.nextDouble(), _rng.nextDouble() * 0.5),
      size: 90 + _rng.nextDouble() * 130,
      speed: 0.004 + _rng.nextDouble() * 0.006,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Night-sky gradient.
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.bgTop,
            AppColors.bgBottom,
            AppColors.bgGradientEnd,
          ],
        ).createShader(rect),
    );

    if (showStars) _paintStars(canvas, size);
    if (showClouds) _paintClouds(canvas, size);
    if (showHills) _paintHills(canvas, size);
  }

  void _paintStars(Canvas canvas, Size size) {
    final Paint glow = Paint()..color = Colors.white;
    for (int i = 0; i < _starSeeds.length; i++) {
      final Offset seed = _starSeeds[i];
      final double twinkle = 0.45 + 0.55 * _starTwinkle[i];
      final double radius = 1 + 1.6 * _starTwinkle[i];
      canvas.drawCircle(
        Offset(seed.dx * size.width, seed.dy * size.height * 0.7),
        radius * twinkle,
        glow..color = Colors.white.withValues(alpha: 0.85 * twinkle),
      );
    }
  }

  void _paintClouds(Canvas canvas, Size size) {
    final Paint cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10);
    final double shift = parallax * 0.25;
    for (final _Cloud cloud in _clouds) {
      final double travel =
          (DateTime.now().millisecondsSinceEpoch / 1000 * cloud.speed) % 1.4;
      final double x =
          ((cloud.seed.dx + travel) % 1.4 - 0.2) * size.width + shift;
      final double y = cloud.seed.dy * size.height * 0.5 + 20;
      final double r = cloud.size / 2;
      canvas.drawCircle(Offset(x, y), r * 0.7, cloudPaint);
      canvas.drawCircle(Offset(x + r * 0.55, y + 8), r * 0.5, cloudPaint);
      canvas.drawCircle(Offset(x - r * 0.55, y + 10), r * 0.45, cloudPaint);
    }
  }

  void _paintHills(Canvas canvas, Size size) {
    const List<Color> layers = <Color>[
      Color(0xFF2A2668),
      Color(0xFF241F5C),
      Color(0xFF1B1747),
    ];
    for (int i = 0; i < layers.length; i++) {
      final double baseY = size.height - 40 - i * 46 + parallax * (0.06 * i);
      final Path path = Path()
        ..moveTo(0, size.height)
        ..lineTo(0, baseY);
      const double wave = 160;
      for (double x = 0; x <= size.width + wave; x += wave) {
        path.quadraticBezierTo(
          x + wave / 2,
          baseY - 46 - i * 14,
          x + wave,
          baseY,
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = layers[i]);
    }
  }

  @override
  bool shouldRepaint(_WorldPainter oldDelegate) =>
      oldDelegate.parallax != parallax ||
      oldDelegate.showHills != showHills ||
      oldDelegate.showClouds != showClouds ||
      oldDelegate.showStars != showStars;
}

class _Cloud {
  const _Cloud({
    required this.seed,
    required this.size,
    required this.speed,
  });

  final Offset seed;
  final double size;
  final double speed;
}
