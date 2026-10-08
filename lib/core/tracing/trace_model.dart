import 'dart:ui';

import 'trace_glyph.dart';

/// Scores a finger trace against a [TraceGlyph].
///
/// Two things have to be true before a trace counts as finished:
///
///  * [coverage] - enough of the letter's target points were passed over, and
///  * [accuracy] - the finger stayed on the letter instead of scribbling.
///
/// Keeping the scoring here (instead of in the widget) makes the rules
/// unit-testable without pumping a frame or rasterizing a glyph.
class TraceModel {
  TraceModel(
    this.glyph, {
    this.coverageGoal = TraceGlyph.kCoverageGoal,
    this.accuracyGoal = TraceGlyph.kAccuracyGoal,
    this.tolerance = TraceGlyph.kTolerance,
    this.accuracyTolerance = TraceGlyph.kAccuracyTolerance,
  });

  final TraceGlyph glyph;
  final double coverageGoal;
  final double accuracyGoal;
  final double tolerance;
  final double accuracyTolerance;

  int _covered = 0;
  int _pointsTotal = 0;
  int _pointsOnGlyph = 0;
  Offset? _lastSample;
  bool _completed = false;

  int get totalTargets => glyph.targets.length;
  int get coveredTargets => _covered;

  /// 0..1 share of the glyph the finger has passed over.
  double get coverage =>
      glyph.targets.isEmpty ? 0 : _covered / glyph.targets.length;

  /// 0..1 share of the finger path that stayed on the glyph.
  double get accuracy =>
      _pointsTotal == 0 ? 0 : _pointsOnGlyph / _pointsTotal;

  bool get isComplete => _completed;

  /// True when the child is most of the way there but still missing strokes.
  bool get isNearlyThere =>
      !_completed && coverage >= coverageGoal * 0.6;

  /// True when the finger is wandering far away from the letter.
  bool get isStraying => _pointsTotal >= 24 && accuracy < accuracyGoal * 0.6;

  /// Records one finger position.
  ///
  /// Returns true when this position covered at least one new target, which
  /// is what the canvas uses to decide whether to repaint or buzz.
  bool addPoint(Offset point) {
    if (_completed) return false;

    final Offset? last = _lastSample;
    if (last != null && (point - last).distance < TraceGlyph.kSampleSpacing) {
      return false;
    }
    _lastSample = point;
    _pointsTotal++;
    if (glyph.distanceAt(point) <= accuracyTolerance) _pointsOnGlyph++;

    bool coveredNew = false;
    for (final TraceTarget target in glyph.targets) {
      if (target.covered) continue;
      if ((target.point - point).distance > tolerance) continue;
      target.covered = true;
      _covered++;
      coveredNew = true;
    }

    if (coveredNew && coverage >= coverageGoal && accuracy >= accuracyGoal) {
      _completed = true;
    }
    return coveredNew;
  }

  /// Clears progress and starts a fresh attempt.
  void reset() {
    _covered = 0;
    _pointsTotal = 0;
    _pointsOnGlyph = 0;
    _lastSample = null;
    _completed = false;
    for (final TraceTarget target in glyph.targets) {
      target.reset();
    }
  }

  /// The area of the glyph the child has covered so far, used to paint a
  /// bright fill exactly over the parts that were traced.
  Path coveredPath({double radius = TraceGlyph.kTolerance}) {
    final Path path = Path();
    for (final TraceTarget target in glyph.targets) {
      if (target.covered) path.addOval(Rect.fromCircle(center: target.point, radius: radius));
    }
    return path;
  }
}
