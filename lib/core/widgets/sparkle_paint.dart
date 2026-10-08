import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Builds the classic four-point "twinkle" path centred on the origin.
///
/// Shared by the sparkle burst on cards and the excited mascot, so both use
/// exactly the same hand-drawn sparkle instead of an image asset.
Path sparklePath(double radius) {
  // Control points collapsed onto the centre produce the concave twinkle.
  return Path()
    ..moveTo(0, -radius)
    ..quadraticBezierTo(0, 0, radius, 0)
    ..quadraticBezierTo(0, 0, 0, radius)
    ..quadraticBezierTo(0, 0, -radius, 0)
    ..quadraticBezierTo(0, 0, 0, -radius)
    ..close();
}

/// Draws a sparkle at [center] with the given [radius] and paint.
void paintSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.drawPath(sparklePath(radius), paint);
  canvas.restore();
}

/// A small confetti-like dot, used for the round particles in a burst.
void paintDot(Canvas canvas, Offset center, double radius, Paint paint) {
  canvas.drawCircle(center, radius, paint);
}

/// Random angle in radians, evenly spread but not perfectly ordered so bursts
/// look hand-thrown rather than mechanical.
double sparkleAngle(math.Random random) => random.nextDouble() * math.pi * 2;
