import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// The custom top-bar avatar: deep violet circle with Owlie's cute face.
class OwlieAvatar extends StatelessWidget {
  const OwlieAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF4C3FB5),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x334C3FB5),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _OwlieFacePainter(),
      ),
    );
  }
}

class _OwlieFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Golden eye patches
    final Paint eyePatchPaint = Paint()
      ..color = const Color(0xFFFFC93C)
      ..style = PaintingStyle.fill;

    final double eyeR = w * 0.22;
    canvas.drawCircle(Offset(w * 0.35, h * 0.48), eyeR, eyePatchPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.48), eyeR, eyePatchPaint);

    // Dark pupils
    final Paint pupilPaint = Paint()
      ..color = const Color(0xFF23314E)
      ..style = PaintingStyle.fill;
    final double pupilR = w * 0.11;
    canvas.drawCircle(Offset(w * 0.36, h * 0.48), pupilR, pupilPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.48), pupilR, pupilPaint);

    // White eye highlights
    final Paint highlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.39, h * 0.45), pupilR * 0.45, highlightPaint);
    canvas.drawCircle(Offset(w * 0.67, h * 0.45), pupilR * 0.45, highlightPaint);

    // Little triangular beak
    final Paint beakPaint = Paint()
      ..color = const Color(0xFFFF7A66)
      ..style = PaintingStyle.fill;
    final Path beakPath = Path()
      ..moveTo(w * 0.45, h * 0.55)
      ..lineTo(w * 0.55, h * 0.55)
      ..lineTo(w * 0.50, h * 0.67)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Graphic for the ABC Card: 3 white cubes arranged in a pyramid (A, B, C).
class AbcCardGraphic extends StatelessWidget {
  const AbcCardGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildBlock('A', const Color(0xFFFF5E5E)),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildBlock('B', const Color(0xFF7356BF)),
            const SizedBox(width: 6),
            _buildBlock('C', const Color(0xFF38B06C)),
          ],
        ),
      ],
    );
  }

  Widget _buildBlock(String letter, Color color) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

/// Graphic for the 123 Card: 3 party balloons tied together with strings.
class BalloonsCardGraphic extends StatelessWidget {
  const BalloonsCardGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Balloon strings converging to the bottom center
          Positioned.fill(
            child: CustomPaint(
              painter: _BalloonStringsPainter(),
            ),
          ),
          // Left balloon: Amber with '1'
          Positioned(
            left: 6,
            top: 14,
            child: _buildBalloon(
              diameter: 38,
              color: const Color(0xFFFFB74D),
              textColor: const Color(0xFF23314E),
              text: '1',
            ),
          ),
          // Center top balloon: Coral Red with '2'
          Positioned(
            left: 33,
            top: 2,
            child: _buildBalloon(
              diameter: 42,
              color: const Color(0xFFFF5252),
              textColor: Colors.white,
              text: '2',
            ),
          ),
          // Right balloon: White with '3'
          Positioned(
            right: 6,
            top: 16,
            child: _buildBalloon(
              diameter: 38,
              color: Colors.white,
              textColor: const Color(0xFF23314E),
              text: '3',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalloon({
    required double diameter,
    required Color color,
    required Color textColor,
    required String text,
  }) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1,
        ),
      ),
    );
  }
}

class _BalloonStringsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final Offset knot = Offset(size.width * 0.50, size.height * 0.88);

    // From bottom of left balloon
    canvas.drawLine(Offset(size.width * 0.23, size.height * 0.48), knot, linePaint);
    // From bottom of middle balloon
    canvas.drawLine(Offset(size.width * 0.50, size.height * 0.44), knot, linePaint);
    // From bottom of right balloon
    canvas.drawLine(Offset(size.width * 0.77, size.height * 0.48), knot, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Graphic for the Quiz Card: Trophy with question mark and cute star.
class TrophyCardGraphic extends StatelessWidget {
  const TrophyCardGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size(78, 74),
            painter: _TrophyPainter(),
          ),
          // Question mark inside the trophy bowl
          const Positioned(
            top: 14,
            child: Text(
              '?',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
                height: 1,
              ),
            ),
          ),
          // Twinkling coral star near the top right rim
          const Positioned(
            right: 0,
            top: 2,
            child: Text(
              '★',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFF6961),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 1. Trophy Bowl
    final Path bowlPath = Path()
      ..moveTo(w * 0.24, h * 0.12)
      ..lineTo(w * 0.76, h * 0.12)
      ..cubicTo(
        w * 0.76, h * 0.58,
        w * 0.60, h * 0.64,
        w * 0.50, h * 0.64,
      )
      ..cubicTo(
        w * 0.40, h * 0.64,
        w * 0.24, h * 0.58,
        w * 0.24, h * 0.12,
      )
      ..close();
    canvas.drawPath(bowlPath, fillPaint);

    // 2. Left handle
    final Paint handlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path leftHandle = Path()
      ..moveTo(w * 0.24, h * 0.20)
      ..cubicTo(w * 0.04, h * 0.20, w * 0.04, h * 0.44, w * 0.28, h * 0.44);
    canvas.drawPath(leftHandle, handlePaint);

    // 3. Right handle
    final Path rightHandle = Path()
      ..moveTo(w * 0.76, h * 0.20)
      ..cubicTo(w * 0.96, h * 0.20, w * 0.96, h * 0.44, w * 0.72, h * 0.44);
    canvas.drawPath(rightHandle, handlePaint);

    // 4. Stem
    final Rect stemRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.72),
      width: w * 0.12,
      height: h * 0.16,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(stemRect, const Radius.circular(2)), fillPaint);

    // 5. Pedestal base
    final Rect baseRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.84),
      width: w * 0.46,
      height: h * 0.12,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(5)), fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Graphic for the Puzzles Card: 2x2 grid of mini tiles (paw, orange dot, blue dot, dashed).
class PuzzlesCardGraphic extends StatelessWidget {
  const PuzzlesCardGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Top-Left: Paw print
              _buildTile(
                child: const Text('🐾', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 5),
              // Top-Right: Orange dot
              _buildTile(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE88A38),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Bottom-Left: Blue dot
              _buildTile(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3897F0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // Bottom-Right: Dashed border tile
              _buildDashedTile(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile({required Widget child}) {
    return Container(
      width: 29,
      height: 29,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFECC8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _buildDashedTile() {
    return SizedBox(
      width: 29,
      height: 29,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(8),
    );

    // Approximate dashed outline around the rounded rectangle
    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = _dashPath(path, dashWidth: 4, dashSpace: 3);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double dashWidth, required double dashSpace}) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = math.min(dashWidth, metric.length - distance);
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The big colorful card matching the screenshot (ABC, 123, Quiz, Puzzles).
class BigGameCard extends StatefulWidget {
  const BigGameCard({
    super.key,
    required this.backgroundColor,
    required this.title,
    required this.graphic,
    required this.onTap,
    this.semanticTitle,
    this.semanticSubtitle,
  });

  final Color backgroundColor;
  final String title;
  final Widget graphic;
  final VoidCallback onTap;
  final String? semanticTitle;
  final String? semanticSubtitle;

  @override
  State<BigGameCard> createState() => _BigGameCardState();
}

class _BigGameCardState extends State<BigGameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (widget.semanticTitle != null || widget.semanticSubtitle != null)
                SizedBox(
                  height: 0,
                  child: OverflowBox(
                    maxWidth: 0,
                    maxHeight: 0,
                    child: Opacity(
                      opacity: 0.001,
                      child: Column(
                        children: <Widget>[
                          if (widget.semanticTitle != null) Text(widget.semanticTitle!),
                          if (widget.semanticSubtitle != null) Text(widget.semanticSubtitle!),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: widget.graphic,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  height: 38,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF23314E),
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rolling green hill painted at the bottom behind Owlie and the floating navbar.
class GreenHillBackground extends StatelessWidget {
  const GreenHillBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Theme background (dynamic from profile / settings)
        Positioned.fill(
          child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        ),
        // Bottom rolling green hill
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 140,
          child: CustomPaint(
            painter: _GreenHillPainter(),
          ),
        ),
        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GreenHillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint hillPaint = Paint()
      ..color = const Color(0xFFD6F2D9)
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(0, size.height * 0.40)
      ..cubicTo(
        size.width * 0.35, size.height * 0.05,
        size.width * 0.70, size.height * 0.50,
        size.width, size.height * 0.20,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, hillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A speech bubble widget with a tail pointing down.
class SpeechBubbleWidget extends StatelessWidget {
  const SpeechBubbleWidget({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF23314E),
              height: 1.1,
            ),
          ),
        ),
        // Bubble tail pointing down
        CustomPaint(
          size: const Size(12, 6),
          painter: _SpeechTailPainter(),
        ),
      ],
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.4, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
