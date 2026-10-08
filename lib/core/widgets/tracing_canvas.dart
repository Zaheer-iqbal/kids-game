import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../di/injection_container.dart' as di;
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../tracing/trace_glyph.dart';
import '../tracing/trace_model.dart';

/// Finger-tracing surface for a single glyph (a letter, a digit or a
/// multi-digit number).
///
/// The glyph is rasterized to a mask once, then every finger position is
/// scored by [TraceModel]: the trace only completes when enough of the glyph
/// has been covered *and* the finger stayed on it. Covered parts light up.
class TracingCanvas extends StatefulWidget {
  const TracingCanvas({
    super.key,
    required this.label,
    required this.color,
    this.onCompleted,
    this.onReset,
  });

  /// The glyph to trace, e.g. `"A"` or `"12"`.
  final String label;

  /// Accent color for the guides and progress badge.
  final Color color;

  /// Fired once - and only once - when both coverage and accuracy goals are
  /// met.
  final VoidCallback? onCompleted;

  /// Fired when the child asks to start over.
  final VoidCallback? onReset;

  @override
  State<TracingCanvas> createState() => TracingCanvasState();
}

/// Public state so widget tests can reach the live scoring model through
/// `tester.state<TracingCanvasState>(...)`.
class TracingCanvasState extends State<TracingCanvas> {
  TraceGlyph? _glyph;
  TraceModel? _model;
  final Path _ink = Path();
  int _inkVersion = 0;
  int _lastMilestone = 0;
  Size _canvasSize = Size.zero;

  /// The live trace, or null while the glyph is still rasterizing.
  ///
  /// Exposed so tests can drag along the real target points instead of
  /// guessing where the glyph is on screen.
  @visibleForTesting
  TraceModel? get model => _model;

  @override
  void didUpdateWidget(TracingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label || oldWidget.color != widget.color) {
      _disposeGlyph();
      _glyph = null;
      _model = null;
      _ink.reset();
      _inkVersion++;
    }
  }

  @override
  void dispose() {
    _disposeGlyph();
    super.dispose();
  }

  void _disposeGlyph() {
    _glyph?.guide?.dispose();
    _glyph?.fill?.dispose();
  }

  Future<void> _rasterize() async {
    if (_canvasSize.isEmpty) return;
    final TraceGlyph? glyph = await TraceGlyph.rasterize(
      label: widget.label,
      size: _canvasSize,
      style: DefaultTextStyle.of(context).style,
    );
    if (!mounted) return;
    setState(() {
      _disposeGlyph();
      _glyph = glyph;
      _model = glyph == null ? null : TraceModel(glyph);
      _ink.reset();
      _inkVersion++;
      _lastMilestone = 0;
    });
  }

  /// Haptics are a nicety: never let a missing platform plugin break a trace.
  void _buzz({required bool heavy}) {
    unawaited(
      (heavy ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick())
          .catchError((Object _) {}),
    );
  }

  /// Raw pointer events (not a gesture recognizer) so strokes are never stolen
  /// by the parent sheet's vertical scroll view.
  void _startStroke(Offset point) {
    _ink.moveTo(point.dx, point.dy);
    _inkVersion++;
    setState(() {});
  }

  void _extendStroke(Offset point) {
    _ink.lineTo(point.dx, point.dy);
    _inkVersion++;
    final TraceModel? model = _model;
    if (model == null || model.isComplete) {
      setState(() {});
      return;
    }

    final bool coveredNew = model.addPoint(point);
    if (coveredNew) {
      final int milestone = (model.coverage * 100).round();
      if (milestone - _lastMilestone >= 10) {
        _lastMilestone = milestone;
        _buzz(heavy: false);
      }
    }
    if (model.isComplete) {
      _complete();
    }
    setState(() {});
  }

  void _complete() {
    _buzz(heavy: true);
    unawaited(di.sl<AudioService>().playTraceChime());
    widget.onCompleted?.call();
  }

  void _reset() {
    setState(() {
      _model?.reset();
      _ink.reset();
      _inkVersion++;
      _lastMilestone = 0;
    });
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != _canvasSize) {
          _canvasSize = size;
          WidgetsBinding.instance.addPostFrameCallback((_) => _rasterize());
        }

        final TraceModel? model = _model;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (PointerDownEvent event) =>
              _startStroke(event.localPosition),
          onPointerMove: (PointerMoveEvent event) =>
              _extendStroke(event.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (model == null)
                  const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  )
                else
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _TracePainter(
                        glyph: model.glyph,
                        coveredPath: model.coveredPath(),
                        coveredCount: model.coveredTargets,
                        ink: _ink,
                        inkVersion: _inkVersion,
                        startPoint: model.glyph.startPoint,
                        completed: model.isComplete,
                        accent: widget.color,
                      ),
                    ),
                  ),
                if (model != null) ...<Widget>[
                  _ProgressBadge(
                    coverage: model.coverage,
                    completed: model.isComplete,
                    color: widget.color,
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: TextButton.icon(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.inkMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('Try again'),
                    ),
                  ),
                  if (model.isComplete)
                    const IgnorePointer(child: Center(child: _CompletionBadge()))
                  else if (model.isNearlyThere)
                    const Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: _Hint(
                        text: 'Almost there, keep tracing!',
                        color: AppColors.success,
                      ),
                    )
                  else if (model.isStraying)
                    const Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: _Hint(
                        text: 'Stay on the letter!',
                        color: AppColors.quiz,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.glyph,
    required this.coveredPath,
    required this.coveredCount,
    required this.ink,
    required this.inkVersion,
    required this.startPoint,
    required this.completed,
    required this.accent,
  });

  final TraceGlyph glyph;
  final Path coveredPath;

  /// Number of covered targets; changes whenever the bright fill grows.
  final int coveredCount;

  final Path ink;
  final int inkVersion;
  final Offset startPoint;
  final bool completed;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Picture? guide = glyph.guide;
    if (guide != null) canvas.drawPicture(guide);

    // Bright fill over the parts that were actually traced.
    if (coveredCount > 0) {
      canvas.save();
      canvas.clipPath(coveredPath);
      final ui.Picture? fill = glyph.fill;
      if (fill != null) canvas.drawPicture(fill);
      canvas.restore();
    }

    final Paint inkPaint = Paint()
      ..color = completed
          ? accent
          : AppColors.ink.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(ink, inkPaint);

    // "Start here" dot until the child has traced at all.
    if (!completed) {
      canvas.drawCircle(
        startPoint,
        11,
        Paint()..color = AppColors.success.withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        startPoint,
        11,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_TracePainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.coveredCount != coveredCount ||
      oldDelegate.inkVersion != inkVersion ||
      oldDelegate.completed != completed ||
      oldDelegate.accent != accent;
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({
    required this.coverage,
    required this.completed,
    required this.color,
  });

  final double coverage;
  final bool completed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int percent = (coverage * 100).round().clamp(0, 100);
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: completed
            ? const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 22,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: coverage,
                      strokeWidth: 3,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (BuildContext context, double value, Widget? child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}
