import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../mascot/mascot_mood.dart';
import '../theme/app_colors.dart';
import 'sparkle_paint.dart';

/// Colours for the hand-drawn owl. One character, one palette: every owl in
/// the app (corners, celebrations, quiz, tracing) uses this single look so the
/// child always sees the same friendly yellow friend.
@immutable
class MascotPalette {
  const MascotPalette({
    required this.bodyTop,
    required this.bodyBottom,
    required this.belly,
    required this.tuft,
    required this.wing,
    required this.beak,
    required this.feet,
    required this.ink,
    required this.blush,
  });

  /// The one and only owl: a warm yellow bird with an amber crown, coral beak
  /// and soft peach cheeks.
  static const MascotPalette owl = MascotPalette(
    bodyTop: Color(0xFFFFC93C),
    bodyBottom: Color(0xFFF2A91E),
    belly: Color(0xFFFFE9A8),
    tuft: Color(0xFFF2A91E),
    wing: Color(0xFFF2A91E),
    beak: Color(0xFFFF7A66),
    feet: Color(0xFFFF9F43),
    ink: Color(0xFF3C3350),
    blush: Color(0xFFFF9F8A),
  );

  /// Kept as an alias of [owl] so the big celebration owl is the *same* owl,
  /// never a second look.
  static const MascotPalette sunny = owl;

  final Color bodyTop;
  final Color bodyBottom;
  final Color belly;
  final Color tuft;
  final Color wing;
  final Color beak;
  final Color feet;
  final Color ink;
  final Color blush;

  @override
  bool operator ==(Object other) =>
      other is MascotPalette &&
      other.bodyTop == bodyTop &&
      other.bodyBottom == bodyBottom &&
      other.belly == belly &&
      other.tuft == tuft &&
      other.wing == wing &&
      other.beak == beak &&
      other.feet == feet &&
      other.ink == ink &&
      other.blush == blush;

  @override
  int get hashCode => Object.hash(
        bodyTop,
        bodyBottom,
        belly,
        tuft,
        wing,
        beak,
        feet,
        ink,
        blush,
      );
}

/// "Pip", a round kid-friendly owl drawn completely in code.
///
/// Every shape (tufts, body, wings, eyes, beak, smile, blush) is painted with
/// canvas primitives, so the app ships with no image assets at all. The owl
/// itself is only a [CustomPaint]; all of the friendliness comes from the
/// poses below, which are pure functions of the animation value.
class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.animation,
    required this.mood,
    required this.reacting,
    required this.giggling,
    this.talking = false,
    this.palette = MascotPalette.owl,
  }) : super(repaint: animation);

  /// Time source. Repeats slowly while idle and runs once for a reaction.
  final Animation<double> animation;

  final MascotMood mood;

  /// True while a one-shot reaction is playing, so [animation] is read as
  /// reaction progress instead of as a breathing loop.
  final bool reacting;

  /// True while the tap-triggered giggle is playing.
  final bool giggling;

  /// True while the owl is "speaking": the beak flaps and the wings flutter,
  /// driven by the same repeating clock as the breathing loop.
  final bool talking;

  final MascotPalette palette;

  static const double _designSize = 100;

  // Layout constants in the 100x100 design box.
  static const Offset _bodyCenter = Offset(50, 58);
  static const double _bodyWidth = 76;
  static const double _bodyHeight = 80;
  static const double _eyeRadius = 15;
  static const double _eyeDX = 14;
  static const double _eyeY = 46;
  static const double _pupilRadius = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = animation.value;
    final double reaction = reacting ? t : 1;

    final _Pose pose = _poseFor(t, reaction);

    final double unit = size.shortestSide / _designSize;
    final double baseX = size.width / 2;
    final double baseY = size.height;

    canvas.save();
    // Plant the owl on its bottom centre: breathing squashes it in place and
    // reactions hop it upward without ever letting go of the floor.
    canvas.translate(baseX, baseY);
    canvas.rotate(pose.rotation);
    canvas.scale(unit * pose.breath, unit * pose.breath);
    canvas.translate(0, -_designSize + pose.lift);

    _paintBody(canvas, pose);
    _paintFace(canvas, pose);
    if (mood == MascotMood.excited) _paintSparkles(canvas, reaction);

    canvas.restore();
  }

  _Pose _poseFor(double t, double reaction) {
    // Reaction progress curves all start at 0 and return to rest at 1, so a
    // finished reaction settles into a calm, smiling face.
    final double arc = math.sin(math.pi * reaction);
    final double fade = 1 - reaction;

    double breath = 1 + 0.035 * math.sin(2 * math.pi * t);
    double lift = 0;
    double rotation = 0.014 * math.sin(2 * math.pi * t);
    double eyeScale = 1;
    double mouthOpen = 0;
    double blush = 0;
    double wingFlap = 0;
    int brows = 0;

    switch (mood) {
      case MascotMood.idle:
        break;
      case MascotMood.happy:
        lift = -11 * arc * (1 - 0.3 * reaction);
        mouthOpen = 0.32 + 0.22 * arc;
        blush = 0.75;
        break;
      case MascotMood.excited:
        rotation += 0.13 * math.sin(3 * math.pi * reaction) * fade;
        lift = -7 * math.sin(2 * math.pi * reaction) * fade;
        eyeScale = 1.14;
        mouthOpen = 0.75 + 0.15 * arc;
        blush = 0.95;
        brows = 1;
        break;
      case MascotMood.encouraging:
        rotation += -0.16 * (1 - Curves.easeInOut.transform(reaction));
        mouthOpen = 0.2;
        blush = 0.6;
        brows = 2;
        break;
    }

    if (giggling) {
      // Fast side-to-side wiggle plus a tiny hop, then straightens up.
      rotation += 0.11 * math.sin(4 * math.pi * t) * (1 - t);
      lift += -5 * math.sin(2 * math.pi * t) * (1 - t);
      eyeScale = math.max(eyeScale, 0.94);
    }

    if (talking) {
      // Speaking: the beak flaps and the wings flutter, both several times per
      // breathing cycle so it reads clearly as "the owl is talking".
      final double talk = math.sin(2 * math.pi * t * 6);
      mouthOpen = 0.28 + 0.55 * (0.5 + 0.5 * talk);
      wingFlap = 0.24 * talk;
    }

    return _Pose(
      breath: breath,
      lift: lift,
      rotation: rotation,
      eyeScale: eyeScale,
      eyeOpen: 1 - 0.88 * _blinkAmount(t),
      mouthOpen: mouthOpen,
      blush: blush,
      wingFlap: wingFlap,
      brows: brows,
    );
  }

  /// Three quick blinks per animation cycle, squashing the eyes shut.
  static double _blinkAmount(double t) {
    const int blinksPerCycle = 3;
    final double phase = (t * blinksPerCycle) % 1;
    if (phase >= 0.07) return 0;
    return math.sin(math.pi * phase / 0.07);
  }

  void _paintBody(Canvas canvas, _Pose pose) {
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[palette.bodyTop, palette.bodyBottom],
      ).createShader(
        Rect.fromCenter(
          center: _bodyCenter,
          width: _bodyWidth,
          height: _bodyHeight,
        ),
      );

    // Ear tufts, drawn first so they peek out from behind the head.
    final Paint tuftPaint = Paint()..color = palette.tuft;
    canvas.drawPath(_leftTuft(), tuftPaint);
    canvas.drawPath(_rightTuft(), tuftPaint);

    // Feet, also behind the body.
    final Paint footPaint = Paint()..color = palette.feet;
    for (final double x in const <double>[38, 62]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, 96), width: 15, height: 9),
          const Radius.circular(4),
        ),
        footPaint,
      );
    }

    // Body.
    canvas.drawOval(
      Rect.fromCenter(
        center: _bodyCenter,
        width: _bodyWidth,
        height: _bodyHeight,
      ),
      bodyPaint,
    );

    // Wings resting on the sides.
    final Paint wingPaint = Paint()
      ..color = Color.lerp(palette.wing, palette.ink, 0.12)!;
    canvas.save();
    canvas.translate(14, 64);
    canvas.rotate(0.18 + pose.wingFlap);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 17, height: 30),
      wingPaint,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(86, 64);
    canvas.rotate(-0.18 - pose.wingFlap);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 17, height: 30),
      wingPaint,
    );
    canvas.restore();

    // Belly.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 68), width: 48, height: 54),
      Paint()..color = palette.belly,
    );
  }

  void _paintFace(Canvas canvas, _Pose pose) {
    // Blush first so the cheeks sit under the eyes.
    if (pose.blush > 0) {
      final Paint blushPaint = Paint()
        ..color = palette.blush.withValues(alpha: 0.55 * pose.blush);
      for (final double x in const <double>[23, 77]) {
        canvas.drawCircle(Offset(x, 62), 7, blushPaint);
      }
    }

    if (pose.brows != 0) {
      _paintBrows(canvas, pose.brows);
    }

    for (final double x in const <double>[50 - _eyeDX, 50 + _eyeDX]) {
      _paintEye(canvas, Offset(x, _eyeY), pose);
    }

    // Beak: a soft rounded triangle.
    final Path beak = Path()
      ..moveTo(50, 55)
      ..quadraticBezierTo(59, 63, 50, 68)
      ..quadraticBezierTo(41, 63, 50, 55)
      ..close();
    canvas.drawPath(beak, Paint()..color = palette.beak);

    _paintMouth(canvas, pose);
  }

  void _paintEye(Canvas canvas, Offset center, _Pose pose) {
    final double ry = _eyeRadius * pose.eyeOpen * pose.eyeScale;
    final double rx = _eyeRadius * pose.eyeScale;
    final Rect eyeRect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);

    canvas.drawOval(eyeRect, Paint()..color = Colors.white);
    canvas.drawOval(
      eyeRect.inflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = palette.ink.withValues(alpha: 0.18),
    );

    // The pupil is clipped to the eye so a blink cuts it instead of leaving a
    // floating dot.
    canvas.save();
    canvas.clipPath(Path()..addOval(eyeRect));
    final Paint pupil = Paint()..color = palette.ink;
    canvas.drawCircle(center.translate(0, 1), _pupilRadius * pose.eyeScale, pupil);
    canvas.drawCircle(
      center.translate(-2.6 * pose.eyeScale, -2.8 * pose.eyeScale),
      2.2 * pose.eyeScale,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.restore();
  }

  void _paintBrows(Canvas canvas, int style) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = palette.ink.withValues(alpha: 0.85);

    for (final double x in const <double>[50 - _eyeDX, 50 + _eyeDX]) {
      final double dir = x < 50 ? -1 : 1;
      final double lift = style == 1 ? 4 : 0;
      // Excited: brows arch up. Encouraging: soft outer-down tilt.
      final double innerRise = style == 1 ? 0 : 1.5;
      final double outerDrop = style == 1 ? 1.5 : 3;
      final Path brow = Path()
        ..moveTo(x - 11 * dir, _eyeY - 21 - lift + outerDrop)
        ..quadraticBezierTo(
          x,
          _eyeY - 27 - lift - innerRise,
          x + 11 * dir,
          _eyeY - 21 - lift + outerDrop,
        );
      canvas.drawPath(brow, paint);
    }
  }

  void _paintMouth(Canvas canvas, _Pose pose) {
    const Offset center = Offset(50, 70);
    const double halfWidth = 8;
    final double depth = 6 + 4 * pose.mouthOpen;

    if (pose.mouthOpen > 0.05) {
      // Open mouth: a filled half-disc with a tiny tongue.
      final Rect opening = Rect.fromCenter(
        center: center.translate(0, 1),
        width: halfWidth * 1.9,
        height: depth * 1.5,
      );
      canvas.drawArc(opening, 0, math.pi, true, Paint()..color = const Color(0xFF8A4459));
      canvas.drawCircle(
        center.translate(0, depth * 0.42),
        depth * 0.32,
        Paint()..color = palette.blush,
      );
    }

    canvas.drawPath(
      Path()
        ..moveTo(center.dx - halfWidth, center.dy)
        ..quadraticBezierTo(
          center.dx,
          center.dy + depth,
          center.dx + halfWidth,
          center.dy,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = palette.ink,
    );
  }

  void _paintSparkles(Canvas canvas, double reaction) {
    final double pulse = 0.55 + 0.45 * math.sin(2 * math.pi * reaction);
    final Paint paint = Paint()..color = AppColors.gold.withValues(alpha: pulse);
    for (final Offset spot in const <Offset>[
      Offset(6, 24),
      Offset(94, 24),
      Offset(50, 2),
    ]) {
      paintSparkle(canvas, spot, 6, paint);
    }
  }

  Path _leftTuft() => Path()
    ..moveTo(13, 36)
    ..quadraticBezierTo(16, 12, 26, 4)
    ..quadraticBezierTo(36, 12, 44, 19)
    ..close();

  Path _rightTuft() => Path()
    ..moveTo(87, 36)
    ..quadraticBezierTo(84, 12, 74, 4)
    ..quadraticBezierTo(64, 12, 56, 19)
    ..close();

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.reacting != reacting ||
        oldDelegate.giggling != giggling ||
        oldDelegate.talking != talking ||
        oldDelegate.palette != palette;
  }
}

class _Pose {
  const _Pose({
    required this.breath,
    required this.lift,
    required this.rotation,
    required this.eyeScale,
    required this.eyeOpen,
    required this.mouthOpen,
    required this.blush,
    required this.brows,
    this.wingFlap = 0,
  });

  final double breath;
  final double lift;
  final double rotation;
  final double eyeScale;
  final double eyeOpen;
  final double mouthOpen;
  final double blush;

  /// Extra rotation applied to the wings while the owl is talking.
  final double wingFlap;

  /// 0 = none, 1 = excited (raised), 2 = encouraging (soft tilt).
  final int brows;
}
