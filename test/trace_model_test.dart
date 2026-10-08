import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/tracing/trace_glyph.dart';
import 'package:kids/core/tracing/trace_model.dart';

/// A 100 x 100 glyph: a thick vertical bar in the middle, like the stem of an
/// "I" or the digit "1". Everything else is empty space.
TraceGlyph _barGlyph() {
  const int size = 100;
  final Uint8List mask = Uint8List(size * size);
  for (int y = 12; y < 88; y++) {
    for (int x = 42; x < 58; x++) {
      mask[y * size + x] = 1;
    }
  }
  return TraceGlyph.fromMask(mask: mask, width: size, height: size);
}

/// Walks a finger along a straight line, one small step at a time.
void _stroke(TraceModel model, Offset from, Offset to, {double step = 2}) {
  final double distance = (to - from).distance;
  final int steps = (distance / step).ceil().clamp(1, 10000);
  for (int i = 0; i <= steps; i++) {
    model.addPoint(Offset.lerp(from, to, i / steps)!);
  }
}

void main() {
  group('TraceModel', () {
    test('an empty trace reports zero progress and never completes', () {
      final TraceModel model = TraceModel(_barGlyph());

      expect(model.coverage, 0);
      expect(model.accuracy, 0);
      expect(model.coveredTargets, 0);
      expect(model.isComplete, isFalse);
      expect(model.isNearlyThere, isFalse);
    });

    test('a full careful trace down the middle completes', () {
      final TraceModel model = TraceModel(_barGlyph());

      // Follow the bar from top to bottom in small steps.
      _stroke(model, const Offset(50, 14), const Offset(50, 86));

      expect(model.coverage, greaterThanOrEqualTo(TraceGlyph.kCoverageGoal));
      expect(model.accuracy, greaterThanOrEqualTo(TraceGlyph.kAccuracyGoal));
      expect(model.isComplete, isTrue);
    });

    test('a scribble across the empty space does not complete', () {
      final TraceModel model = TraceModel(_barGlyph());

      // Same distance travelled as the correct trace, but nowhere near the bar.
      for (int row = 10; row < 90; row += 4) {
        _stroke(model, Offset(6, row.toDouble()), Offset(24, row.toDouble()));
      }

      expect(model.accuracy, lessThan(TraceGlyph.kAccuracyGoal));
      expect(model.isComplete, isFalse);
    });

    test('a half trace is close but not finished, and says so', () {
      final TraceModel model = TraceModel(_barGlyph());

      _stroke(model, const Offset(50, 14), const Offset(50, 50));

      expect(model.coverage, greaterThan(0));
      expect(model.coverage, lessThan(TraceGlyph.kCoverageGoal));
      expect(model.isComplete, isFalse);
      expect(model.isNearlyThere, isTrue, reason: 'the hint must show');
    });

    test('scoring stops once the trace is complete', () {
      final TraceModel model = TraceModel(_barGlyph());
      _stroke(model, const Offset(50, 14), const Offset(50, 86));
      final int covered = model.coveredTargets;

      expect(model.addPoint(const Offset(50, 50)), isFalse);
      expect(model.coveredTargets, covered);
      expect(model.coverage, 1.0);
    });

    test('reset clears progress, flags and the completed state', () {
      final TraceModel model = TraceModel(_barGlyph());
      _stroke(model, const Offset(50, 14), const Offset(50, 86));
      expect(model.isComplete, isTrue);

      model.reset();

      expect(model.coveredTargets, 0);
      expect(model.coverage, 0);
      expect(model.accuracy, 0);
      expect(model.isComplete, isFalse);
      expect(
        model.glyph.targets.every((TraceTarget t) => !t.covered),
        isTrue,
      );
    });

    test('a wandering finger is reported as straying', () {
      final TraceModel model = TraceModel(_barGlyph());

      _stroke(model, const Offset(2, 2), const Offset(2, 98));

      expect(model.isStraying, isTrue);
    });

    test('holding still cannot fake progress', () {
      final TraceModel model = TraceModel(_barGlyph());

      // The same position over and over: only one sample is counted, and it
      // can only cover the targets right around it.
      for (int i = 0; i < 40; i++) {
        model.addPoint(const Offset(50, 50));
      }

      expect(model.coveredTargets, lessThan(model.totalTargets));
      expect(model.coverage, lessThan(TraceGlyph.kCoverageGoal));
      expect(model.isComplete, isFalse);
    });

    test('covered targets build a fill area, uncovered ones leave holes', () {
      final TraceModel model = TraceModel(_barGlyph());
      expect(model.coveredPath().getBounds(), Rect.zero);

      _stroke(model, const Offset(50, 14), const Offset(50, 50));
      final Rect partial = model.coveredPath().getBounds();
      expect(partial.height, greaterThan(0));
      expect(partial.center.dy, lessThan(50));

      model.reset();
      expect(model.coveredPath().getBounds(), Rect.zero);
    });
  });

  group('TraceGlyph', () {
    test('distance is zero inside the glyph and grows away from it', () {
      final TraceGlyph glyph = _barGlyph();

      expect(glyph.distanceAt(const Offset(50, 50)), 0);
      expect(glyph.distanceAt(const Offset(20, 50)), greaterThan(15));
      expect(glyph.distanceAt(const Offset(2, 2)), greaterThan(40));
    });

    test('distance is symmetric and stays finite at the edges', () {
      final TraceGlyph glyph = _barGlyph();

      expect(
        glyph.distanceAt(const Offset(30, 50)),
        closeTo(glyph.distanceAt(const Offset(70, 50)), 1.5),
      );
      expect(glyph.distanceAt(Offset.zero).isFinite, isTrue);
      expect(glyph.distanceAt(const Offset(99, 99)).isFinite, isTrue);
    });

    test('targets sit inside the glyph and are spread out', () {
      final TraceGlyph glyph = _barGlyph();

      expect(glyph.targets, isNotEmpty);
      for (final TraceTarget target in glyph.targets) {
        expect(glyph.distanceAt(target.point), lessThan(2));
      }
      // Sorted top to bottom, so a finger can follow them in order.
      for (int i = 1; i < glyph.targets.length; i++) {
        expect(
          glyph.targets[i].point.dy,
          greaterThanOrEqualTo(glyph.targets[i - 1].point.dy),
        );
      }
    });
  });
}
