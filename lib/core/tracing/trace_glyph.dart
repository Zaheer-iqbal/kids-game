import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../theme/app_colors.dart';

/// One spot the child is expected to pass through while tracing.
///
/// A trace only counts as finished when [kCoverageGoal] of these are covered
/// **and** the finger stayed on the letter ([kAccuracyGoal]), so scribbling
/// over the shape can no longer finish the activity.
class TraceTarget {
  TraceTarget(this.point) : covered = false;

  final Offset point;
  bool covered;

  void reset() => covered = false;
}

/// A rasterized glyph ready for finger tracing: a 0/1 pixel mask, a distance
/// field (how far every pixel is from the glyph), a spread-out list of
/// [targets] and cached pictures for painting the guide and the filled shape.
class TraceGlyph {
  TraceGlyph._({
    required this.mask,
    required this.distanceField,
    required this.targets,
    required this.width,
    required this.height,
    this.guide,
    this.fill,
  });

  /// Fraction of the targets that must be covered before a trace completes.
  static const double kCoverageGoal = 0.85;

  /// Fraction of the finger path that must stay on the glyph. This is what
  /// stops a scribble from "completing" the shape.
  static const double kAccuracyGoal = 0.80;

  /// How close the finger has to pass to a target, in logical pixels. Chosen
  /// so a small hand still covers the stroke comfortably.
  static const double kTolerance = 20.0;

  /// Accuracy is judged a little more generously than coverage, otherwise the
  /// short hops between the parts of a letter ("A" down to its crossbar) would
  /// count as mistakes.
  static const double kAccuracyTolerance = kTolerance * 1.4;

  /// Points closer together than this count as a single finger position, so
  /// holding still cannot inflate accuracy.
  static const double kSampleSpacing = 3.0;

  static const int _minTargets = 150;
  static const int _maxTargets = 300;

  final Uint8List mask;
  final Float32List distanceField;
  final List<TraceTarget> targets;
  final int width;
  final int height;

  /// Faded, dotted outline of the glyph to trace over.
  final ui.Picture? guide;

  /// Solid glyph, tinted; clipped to the covered area to paint the fill.
  final ui.Picture? fill;

  bool get isEmpty => targets.isEmpty;

  /// Where the child should start: the first target in reading order.
  Offset get startPoint => targets.first.point;

  /// Approximate distance in pixels from [point] to the nearest glyph pixel.
  double distanceAt(Offset point) {
    final int x = point.dx.round().clamp(0, width - 1);
    final int y = point.dy.round().clamp(0, height - 1);
    // The chamfer transform below stores tenths, so divide to get pixels.
    return distanceField[y * width + x] / 3.0;
  }

  /// Builds a glyph straight from a pixel mask, with no artwork.
  ///
  /// Used by tests to check the scoring rules on a known shape without
  /// rasterizing a real font.
  @visibleForTesting
  factory TraceGlyph.fromMask({
    required Uint8List mask,
    required int width,
    required int height,
    List<TraceTarget>? targets,
  }) {
    return TraceGlyph._(
      mask: mask,
      distanceField: _distanceField(mask, width, height),
      targets: targets ?? _targetsForGrid(mask, width, height, 4),
      width: width,
      height: height,
    );
  }

  /// Rasterizes [label] (a letter, digit or multi-digit number) into [size].
  ///
  /// Returns null when the glyph came out empty, e.g. a missing font.
  static Future<TraceGlyph?> rasterize({
    required String label,
    required Size size,
    required TextStyle style,
  }) async {
    final int w = size.width.round().clamp(1, 1600);
    final int h = size.height.round().clamp(1, 1600);
    if (w < 8 || h < 8) return null;

    final TextStyle maskStyle = _fitStyle(label, w, h, style);
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: maskStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w.toDouble() * 0.94);
    if (painter.width <= 0 || painter.height <= 0) return null;

    final Offset origin =
        Offset((w - painter.width) / 2, (h - painter.height) / 2);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), origin);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(w, h);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    picture.dispose();
    image.dispose();
    if (byteData == null) return null;

    final Uint8List mask = _alphaToMask(byteData, w, h);
    final List<TraceTarget> targets = _sampleTargets(mask, w, h);
    if (targets.isEmpty) return null;

    return TraceGlyph._(
      mask: mask,
      distanceField: _distanceField(mask, w, h),
      targets: targets,
      width: w,
      height: h,
      guide: _guidePicture(label, maskStyle, origin, mask, w, h),
      fill: _fillPicture(label, maskStyle, origin),
    );
  }

  /// Picks a font size that fills the box for one glyph or shrinks to fit
  /// multi-digit labels such as "12" without clipping.
  static TextStyle _fitStyle(
    String label,
    int w,
    int h,
    TextStyle style,
  ) {
    double fontSize = math.min(w, h) * 0.82;
    while (true) {
      final TextStyle candidate = style.copyWith(
        fontSize: fontSize,
        height: 1.0,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFFFFFFF),
      );
      final TextPainter probe = TextPainter(
        text: TextSpan(text: label, style: candidate),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final bool fits = probe.width <= w * 0.9 && probe.height <= h * 0.86;
      probe.dispose();
      if (fits || fontSize <= 10) return candidate;
      fontSize -= 2;
    }
  }

  static Uint8List _alphaToMask(ByteData bytes, int w, int h) {
    // Web hands back raw float32 channels, native back raw bytes.
    final bool floats = bytes.lengthInBytes == w * h * 16;
    final Uint8List mask = Uint8List(w * h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final int pixel = y * w + x;
        final double alpha = floats
            ? bytes.buffer.asFloat32List()[pixel * 4 + 3]
            : bytes.getUint8(pixel * 4 + 3) / 255.0;
        if (alpha > 0.5) mask[pixel] = 1;
      }
    }
    return mask;
  }

  /// Spreads targets over the whole glyph by picking one pixel per grid cell
  /// (the one closest to that cell's centre), refining the grid until there
  /// are enough of them.
  static List<TraceTarget> _sampleTargets(
    Uint8List mask,
    int w,
    int h,
  ) {
    for (int grid = 12; grid <= 28; grid += 4) {
      final List<TraceTarget> targets = _targetsForGrid(mask, w, h, grid);
      if (targets.length > _maxTargets) {
        return targets.take(_maxTargets).toList(growable: false);
      }
      if (targets.length >= _minTargets) return targets;
    }
    return _targetsForGrid(mask, w, h, 28);
  }

  static List<TraceTarget> _targetsForGrid(
    Uint8List mask,
    int w,
    int h,
    int grid,
  ) {
    final double cellW = w / grid;
    final double cellH = h / grid;
    final List<TraceTarget> targets = <TraceTarget>[];

    for (int row = 0; row < grid; row++) {
      for (int column = 0; column < grid; column++) {
        final int x0 = (column * cellW).floor();
        final int x1 = ((column + 1) * cellW).ceil().clamp(x0 + 1, w);
        final int y0 = (row * cellH).floor();
        final int y1 = ((row + 1) * cellH).ceil().clamp(y0 + 1, h);
        final Offset centre = Offset(
          (x0 + x1 - 1) / 2,
          (y0 + y1 - 1) / 2,
        );

        int bestX = -1;
        int bestY = -1;
        double bestDistance = double.infinity;
        for (int y = y0; y < y1; y++) {
          for (int x = x0; x < x1; x++) {
            if (mask[y * w + x] != 1) continue;
            final double distance =
                (Offset(x + 0.5, y + 0.5) - centre).distanceSquared;
            if (distance < bestDistance) {
              bestDistance = distance;
              bestX = x;
              bestY = y;
            }
          }
        }
        if (bestX >= 0) targets.add(TraceTarget(Offset(bestX + 0.5, bestY + 0.5)));
      }
    }

    targets.sort((TraceTarget a, TraceTarget b) {
      final int byRow = a.point.dy.compareTo(b.point.dy);
      return byRow != 0 ? byRow : a.point.dx.compareTo(b.point.dx);
    });
    return targets;
  }

  /// Two-pass 3-4 chamfer distance transform: every pixel learns how far it is
  /// from the glyph, which makes "am I on the letter?" an O(1) lookup.
  static Float32List _distanceField(Uint8List mask, int w, int h) {
    const double far = 1e7;
    final Float32List dist = Float32List(w * h);
    for (int i = 0; i < dist.length; i++) {
      dist[i] = mask[i] == 1 ? 0 : far;
    }

    void relax(int i, int neighbour, double weight) {
      if (neighbour < 0) return;
      final double candidate = dist[neighbour] + weight;
      if (candidate < dist[i]) dist[i] = candidate;
    }

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final int i = y * w + x;
        relax(i, x > 0 ? i - 1 : -1, 3);
        relax(i, y > 0 ? i - w : -1, 3);
        relax(i, x > 0 && y > 0 ? i - w - 1 : -1, 4);
        relax(i, x < w - 1 && y > 0 ? i - w + 1 : -1, 4);
      }
    }
    for (int y = h - 1; y >= 0; y--) {
      for (int x = w - 1; x >= 0; x--) {
        final int i = y * w + x;
        relax(i, x < w - 1 ? i + 1 : -1, 3);
        relax(i, y < h - 1 ? i + w : -1, 3);
        relax(i, x < w - 1 && y < h - 1 ? i + w + 1 : -1, 4);
        relax(i, x > 0 && y < h - 1 ? i + w - 1 : -1, 4);
      }
    }
    return dist;
  }

  static ui.Picture _guidePicture(
    String label,
    TextStyle style,
    Offset origin,
    Uint8List mask,
    int w,
    int h,
  ) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final TextPainter faded = TextPainter(
      text: TextSpan(
        text: label,
        style: style.copyWith(color: AppColors.ink.withValues(alpha: 0.16)),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    faded.paint(canvas, origin);

    final Paint dot = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;
    for (int y = 0; y < h; y += 3) {
      for (int x = 0; x < w; x += 3) {
        if (mask[y * w + x] == 1) {
          canvas.drawCircle(Offset(x + 1.5, y + 1.5), 1.5, dot);
        }
      }
    }
    return recorder.endRecording();
  }

  static ui.Picture _fillPicture(String label, TextStyle style, Offset origin) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: label,
        style: style.copyWith(color: AppColors.success),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, origin);
    return recorder.endRecording();
  }
}
