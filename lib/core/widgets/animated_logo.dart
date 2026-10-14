import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'delight_settings.dart';

/// The ABC Zoo brand mark, assembled from individual SVG parts that all share
/// one 380x330 canvas so they line up perfectly when stacked.
///
/// The sequence is a single controller: letters **A, B, C, Z** drop in one
/// after another with a bounce, then the two eyes pop in with a rubber-band
/// squash and look around once, then the logo settles. Tapping it replays a
/// short version. The whole thing finishes in under 2.5 seconds.
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({
    super.key,
    this.size = 260,
    this.duration = const Duration(milliseconds: 2200),
    this.replayDuration = const Duration(milliseconds: 1000),
  });

  /// Rendered width. Height follows the 380x330 canvas ratio.
  final double size;

  /// Full first-play length. Kept under 2.5s.
  final Duration duration;

  /// The shorter loop used when the logo is tapped.
  final Duration replayDuration;

  static const double canvasWidth = 380;
  static const double canvasHeight = 330;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If a parent turns motion back on, make sure a settled logo is not stuck
    // mid-flight.
    if (_reduced && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _reduced {
    final DelightSettings settings = DelightSettings.of(context);
    final bool system =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return settings.reduceMotion || system || !settings.animationsEnabled;
  }

  void _replay() {
    if (_reduced) return;
    _controller.duration = widget.replayDuration;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.size;
    final double height = width * AnimatedLogo.canvasHeight /
        AnimatedLogo.canvasWidth;

    return Semantics(
      label: 'ABC Zoo logo',
      button: true,
      onTap: _replay,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _replay,
        child: RepaintBoundary(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _letter('assets/logo/letter_a.svg', width, height,
                    const Alignment(-0.553, 0.273), 0.00, 0.18),
                _letter('assets/logo/letter_b.svg', width, height,
                    const Alignment(0.089, 0.345), 0.10, 0.28),
                _letter('assets/logo/letter_c.svg', width, height,
                    const Alignment(0.600, 0.279), 0.20, 0.38),
                _letter('assets/logo/letter_z.svg', width, height,
                    const Alignment(0.721, -0.539), 0.30, 0.48),
                _eye('assets/logo/eye_left.svg', width, height,
                    const Alignment(-0.026, -0.515)),
                _eye('assets/logo/eye_right.svg', width, height,
                    const Alignment(0.263, -0.515)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _segment(double value, double begin, double end) =>
      ((value - begin) / (end - begin)).clamp(0.0, 1.0);

  Widget _letter(
    String asset,
    double width,
    double height,
    Alignment alignment,
    double begin,
    double end,
  ) {
    final Widget part =
        SvgPicture.asset(asset, width: width, height: height);
    if (_reduced) return part;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _segment(_controller.value, begin, end);
        final double eased = Curves.easeOutBack.transform(t);
        final double scale = 0.2 + 0.8 * eased;
        final double dy = 46 * (1 - Curves.easeOutCubic.transform(t));
        return Opacity(
          opacity: (t * 2).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform(
              alignment: alignment,
              transform: Matrix4.diagonal3Values(scale, scale, 1),
              child: child,
            ),
          ),
        );
      },
      child: part,
    );
  }

  Widget _eye(String asset, double width, double height, Alignment alignment) {
    final Widget part =
        SvgPicture.asset(asset, width: width, height: height);
    if (_reduced) return part;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double pop = _segment(_controller.value, 0.52, 0.70);
        final double w = math.sin(pop * math.pi * 2) * (1 - pop);
        final double sx = 1 + 0.30 * w;
        final double sy = 1 - 0.25 * w;
        final double look = _segment(_controller.value, 0.70, 0.92);
        final double dx = math.sin(look * 2 * math.pi) * 6;
        return Transform(
          alignment: alignment,
          transform: Matrix4.diagonal3Values(sx, sy, 1)
            ..setTranslationRaw(dx, 0.0, 0.0),
          child: child,
        );
      },
      child: part,
    );
  }
}
