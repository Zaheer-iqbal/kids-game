import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The code-drawn "world" behind every screen: a soft daylight sky with a
/// smiling sun, drifting white clouds and layered rolling pastel hills. No
/// images.
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

  /// Kept for API compatibility: draws soft daytime sparkles / flower dots.
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
    46,
    (int i) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final List<double> _starTwinkle = List<double>.generate(
    46,
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
    // Daylight gradient: soft sky into warm cream.
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

    _paintSun(canvas, size);
    if (showStars) _paintSparkles(canvas, size);
    if (showClouds) _paintClouds(canvas, size);
    if (showHills) _paintHills(canvas, size);
  }

  void _paintSun(Canvas canvas, Size size) {
    final Offset center = Offset(size.width - 54, 64);
    final Paint glow = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.22);
    canvas.drawCircle(center, 44, glow);
    canvas.drawCircle(
      center,
      30,
      Paint()..color = const Color(0xFFFFD86B),
    );
    // Friendly closed-smile sun face, drawn thin and dark so it stays subtle.
    final Paint face = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.goldInk.withValues(alpha: 0.65);
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(0, -2), width: 22, height: 14),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      face,
    );
    canvas.drawCircle(center.translate(-8, -8), 1.8, face..style = PaintingStyle.fill);
    canvas.drawCircle(center.translate(8, -8), 1.8, face);
  }

  /// Soft daytime dots and tiny four-point sparkles floating in the sky.
  void _paintSparkles(Canvas canvas, Size size) {
    for (int i = 0; i < _starSeeds.length; i++) {
      final Offset seed = _starSeeds[i];
      final double twinkle = 0.35 + 0.45 * _starTwinkle[i];
      final double radius = 1.2 + 1.4 * _starTwinkle[i];
      final Offset spot = Offset(
        seed.dx * size.width,
        seed.dy * size.height * 0.6,
      );
      canvas.drawCircle(
        spot,
        radius,
        Paint()..color = Colors.white.withValues(alpha: 0.55 * twinkle),
      );
    }
  }

  void _paintClouds(Canvas canvas, Size size) {
    final Paint cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final double shift = parallax * 0.25;
    for (final _Cloud cloud in _clouds) {
      final double travel =
          (DateTime.now().millisecondsSinceEpoch / 1000 * cloud.speed) % 1.4;
      final double x =
          ((cloud.seed.dx + travel) % 1.4 - 0.2) * size.width + shift;
      final double y = cloud.seed.dy * size.height * 0.42 + 26;
      final double r = cloud.size / 2;
      canvas.drawCircle(Offset(x, y), r * 0.7, cloudPaint);
      canvas.drawCircle(Offset(x + r * 0.55, y + 8), r * 0.5, cloudPaint);
      canvas.drawCircle(Offset(x - r * 0.55, y + 10), r * 0.45, cloudPaint);
    }
  }

  void _paintHills(Canvas canvas, Size size) {
    const List<Color> layers = <Color>[
      Color(0xFFB7E4C7),
      Color(0xFF9BD8B4),
      Color(0xFF7FCFA2),
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